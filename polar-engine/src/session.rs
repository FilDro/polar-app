//! PolarSession — the top-level coordinator.
//!
//! Owns the BLE runtime and maintains state snapshots
//! for the FFI bridge to poll.

use std::time::Instant;

use crate::ble_runtime::{BleCommand, BleEvent, BleRuntime, StreamConfig};
use crate::state::*;

pub struct PolarSession {
    ble: BleRuntime,
    connection: ConnectionSnapshot,
    streaming: StreamSnapshot,
    recording: RecordingSnapshot,
    files: FilesSnapshot,
    // Ring buffers for chart data (~10s at 52Hz = 520 samples, or at 416Hz = 4160)
    acc_ring: SampleRingBuffer,
    gyro_ring: SampleRingBuffer,
    stream_start: Option<Instant>,
    stream_sample_count: u64,
}

impl PolarSession {
    pub fn new() -> Self {
        Self {
            ble: BleRuntime::new(),
            connection: ConnectionSnapshot::default(),
            streaming: StreamSnapshot::default(),
            recording: RecordingSnapshot::default(),
            files: FilesSnapshot::default(),
            acc_ring: SampleRingBuffer::new(5000),
            gyro_ring: SampleRingBuffer::new(5000),
            stream_start: None,
            stream_sample_count: 0,
        }
    }

    // ── Connection commands ──────────────────────────────────────

    pub fn start_scan(&mut self) {
        self.connection.status = ConnectionStatus::Scanning;
        self.connection.devices.clear();
        self.ble.send_command(BleCommand::StartScan { duration_s: 5 });
    }

    pub fn connect(&mut self, identifier: &str) {
        self.connection.status = ConnectionStatus::Connecting;
        self.connection.device_id = identifier.to_string();
        self.ble.send_command(BleCommand::Connect {
            identifier: identifier.to_string(),
        });
    }

    pub fn disconnect(&mut self) {
        self.ble.send_command(BleCommand::Disconnect);
        self.connection = ConnectionSnapshot::default();
        self.streaming = StreamSnapshot::default();
    }

    pub fn read_device_info(&self) {
        self.ble.send_command(BleCommand::ReadDeviceInfo);
    }

    // ── Streaming commands ──────────────────────────────────────

    pub fn start_stream(&mut self, config: &str) {
        let stream_config = StreamConfig::from_str(config);
        self.streaming.config = config.to_string();
        self.streaming.is_streaming = true;
        self.streaming.sample_count = 0;
        self.streaming.hr_bpm = -1;
        self.acc_ring.clear();
        self.gyro_ring.clear();
        self.stream_start = Some(Instant::now());
        self.stream_sample_count = 0;
        self.ble.send_command(BleCommand::StartStream {
            config: stream_config,
        });
    }

    pub fn stop_stream(&mut self) {
        self.ble.send_command(BleCommand::StopStream);
        self.streaming.is_streaming = false;
    }

    // ── Recording commands ──────────────────────────────────────

    pub fn start_recording(&mut self, types: &[String]) {
        self.recording.active_types = types.to_vec();
        self.recording.is_recording = false; // Will be set when confirmed
        self.recording.error.clear();
        self.ble.send_command(BleCommand::StartRecording {
            types: types.to_vec(),
        });
    }

    pub fn stop_recording(&mut self, types: &[String]) {
        self.recording.error.clear();
        self.ble.send_command(BleCommand::StopRecording {
            types: types.to_vec(),
        });
    }

    pub fn check_recording_status(&self) {
        self.ble.send_command(BleCommand::CheckRecordingStatus);
    }

    // ── File commands ───────────────────────────────────────────

    pub fn list_files(&mut self) {
        self.files.is_syncing = true;
        self.files.entries.clear();
        self.files.error.clear();
        self.ble.send_command(BleCommand::ListFiles);
    }

    pub fn sync_files(&mut self) {
        self.files.is_syncing = true;
        self.files.downloaded_csvs.clear();
        self.files.error.clear();
        self.ble.send_command(BleCommand::SyncFiles);
    }

    // ── Trigger commands ────────────────────────────────────────

    pub fn set_trigger(&self, mode: &str) {
        self.ble.send_command(BleCommand::SetTrigger {
            mode: mode.to_string(),
        });
    }

    pub fn get_trigger(&self) {
        self.ble.send_command(BleCommand::GetTrigger);
    }

    // ── Polling ─────────────────────────────────────────────────

    /// Drain all BLE events and update state. Called by FFI bridge.
    pub fn process_events(&mut self) {
        let events = self.ble.drain_events();
        for event in events {
            self.handle_event(event);
        }

        // Update elapsed time
        if self.streaming.is_streaming {
            if let Some(start) = self.stream_start {
                self.streaming.elapsed_s = start.elapsed().as_secs_f64();
            }
        }
    }

    fn handle_event(&mut self, event: BleEvent) {
        match event {
            BleEvent::ScanResult(devices) => {
                self.connection.devices = devices;
            }
            BleEvent::ScanComplete => {
                if self.connection.status == ConnectionStatus::Scanning {
                    self.connection.status = ConnectionStatus::Disconnected;
                }
            }
            BleEvent::Connecting(name) => {
                self.connection.status = ConnectionStatus::Connecting;
                self.connection.device_name = name;
            }
            BleEvent::Connected(name) => {
                self.connection.status = ConnectionStatus::Connected;
                self.connection.device_name = name;
                self.connection.error.clear();
                // Auto-read device info on connect
                self.ble.send_command(BleCommand::ReadDeviceInfo);
            }
            BleEvent::Disconnected => {
                self.connection = ConnectionSnapshot::default();
                self.streaming = StreamSnapshot::default();
                self.recording = RecordingSnapshot::default();
            }
            BleEvent::Error(msg) => {
                self.connection.error = msg.clone();
                // Also set on sub-states if relevant
                if self.streaming.is_streaming {
                    self.streaming.is_streaming = false;
                }
                if self.files.is_syncing {
                    self.files.error = msg;
                }
            }
            BleEvent::DeviceInfo {
                model,
                firmware,
                serial,
                battery,
                disk_total_kb,
                disk_free_kb,
            } => {
                self.connection.model = model;
                self.connection.firmware = firmware;
                self.connection.serial = serial;
                self.connection.battery_percent = battery;
                self.connection.disk_total_kb = disk_total_kb;
                self.connection.disk_free_kb = disk_free_kb;
            }
            BleEvent::StreamStarted(config) => {
                self.streaming.is_streaming = true;
                self.streaming.config = config;
            }
            BleEvent::StreamStopped => {
                self.streaming.is_streaming = false;
            }
            BleEvent::HrSample { bpm } => {
                self.streaming.hr_bpm = bpm as i32;
            }
            BleEvent::AccSamples {
                samples,
                timestamp_ns,
            } => {
                let base_s = timestamp_ns as f64 / 1_000_000_000.0;
                for (i, s) in samples.iter().enumerate() {
                    let t = base_s + (i as f64 * 0.0024); // ~416Hz
                    self.acc_ring.push(t, s[0] as f32, s[1] as f32, s[2] as f32);
                    self.stream_sample_count += 1;
                }
                self.streaming.sample_count = self.stream_sample_count;
                self.streaming.chart_acc = self.acc_ring.to_chart_data();
            }
            BleEvent::GyroSamples {
                samples,
                timestamp_ns,
            } => {
                let base_s = timestamp_ns as f64 / 1_000_000_000.0;
                for (i, s) in samples.iter().enumerate() {
                    let t = base_s + (i as f64 * 0.0024);
                    self.gyro_ring.push(t, s[0], s[1], s[2]);
                    self.stream_sample_count += 1;
                }
                self.streaming.sample_count = self.stream_sample_count;
                self.streaming.chart_gyro = self.gyro_ring.to_chart_data();
            }
            BleEvent::RecordingStarted(types) => {
                self.recording.is_recording = true;
                self.recording.active_types = types;
                self.recording.status_text = "Recording active".to_string();
            }
            BleEvent::RecordingStopped => {
                self.recording.is_recording = false;
                self.recording.active_types.clear();
                self.recording.status_text = "Recording stopped".to_string();
            }
            BleEvent::RecordingStatus(active) => {
                self.recording.is_recording = !active.is_empty();
                self.recording.active_types = active;
                self.recording.status_text = if self.recording.is_recording {
                    format!("Active: {}", self.recording.active_types.join(", "))
                } else {
                    "No active recordings".to_string()
                };
            }
            BleEvent::FileList(entries) => {
                self.files.entries = entries;
                self.files.is_syncing = false;
            }
            BleEvent::FileSyncProgress(msg) => {
                self.files.progress_text = msg;
            }
            BleEvent::FileDownloaded(csv) => {
                self.files.downloaded_csvs.push(csv);
            }
            BleEvent::FileSyncComplete => {
                self.files.is_syncing = false;
                self.files.progress_text = format!(
                    "Complete — {} files",
                    self.files.downloaded_csvs.len()
                );
            }
            BleEvent::TriggerStatus(mode) => {
                self.recording.status_text = format!("Trigger: {}", mode);
            }
            BleEvent::TriggerSet(mode) => {
                self.recording.status_text = format!("Trigger set to: {}", mode);
            }
        }
    }

    // ── Snapshot accessors ──────────────────────────────────────

    pub fn connection_snapshot(&self) -> ConnectionSnapshot {
        self.connection.clone()
    }

    pub fn stream_snapshot(&self) -> StreamSnapshot {
        self.streaming.clone()
    }

    pub fn recording_snapshot(&self) -> RecordingSnapshot {
        self.recording.clone()
    }

    pub fn files_snapshot(&self) -> FilesSnapshot {
        self.files.clone()
    }
}
