//! PolarSession — the top-level coordinator.
//!
//! Owns the BLE runtime and maintains state snapshots
//! for the FFI bridge to poll.

use std::time::Instant;

use polar_core::hrv::PpiInput;

use crate::ble_runtime::{BleCommand, BleEvent, BleRuntime, StreamConfig};
use crate::state::*;

const MORNING_WARMUP_S: f64 = 25.0;

struct PreprocessedMorningSamples {
    diagnostics: MorningCheckDiagnostics,
    inputs: Vec<PpiInput>,
}

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
    // Morning check
    morning_check: MorningCheckSnapshot,
    morning_ppi_buffer: Vec<TimedMorningPpiSample>,
    // Device management ops
    device_ops: DeviceOpsSnapshot,
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
            morning_check: MorningCheckSnapshot::default(),
            morning_ppi_buffer: Vec::new(),
            device_ops: DeviceOpsSnapshot::default(),
        }
    }

    // ── Connection commands ──────────────────────────────────────

    pub fn start_scan(&mut self) {
        self.connection.status = ConnectionStatus::Scanning;
        self.connection.devices.clear();
        self.ble
            .send_command(BleCommand::StartScan { duration_s: 5 });
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
        self.files.hr_data = None;
        self.files.session_summary = None;
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

    pub fn setup_trigger(&self, mode: &str, types: Vec<String>) {
        self.ble.send_command(BleCommand::SetupTrigger {
            mode: mode.to_string(),
            types,
        });
    }

    pub fn sync_time(&self) {
        self.ble.send_command(BleCommand::SyncTime);
    }

    pub fn device_restart(&mut self) {
        self.device_ops = DeviceOpsSnapshot {
            is_busy: true,
            progress_text: "Restarting...".into(),
            ..Default::default()
        };
        self.ble.send_command(BleCommand::DeviceRestart);
    }

    pub fn device_factory_reset(&mut self) {
        self.device_ops = DeviceOpsSnapshot {
            is_busy: true,
            progress_text: "Factory resetting...".into(),
            ..Default::default()
        };
        self.ble.send_command(BleCommand::DeviceFactoryReset);
    }

    pub fn delete_all_recordings(&mut self) {
        self.device_ops = DeviceOpsSnapshot {
            is_busy: true,
            progress_text: "Deleting recordings...".into(),
            ..Default::default()
        };
        self.ble.send_command(BleCommand::DeleteAllRecordings);
    }

    pub fn delete_telemetry(&mut self) {
        self.device_ops = DeviceOpsSnapshot {
            is_busy: true,
            progress_text: "Deleting telemetry...".into(),
            ..Default::default()
        };
        self.ble.send_command(BleCommand::DeleteTelemetry);
    }

    // ── Morning check commands ─────────────────────────────────

    pub fn start_morning_check(&mut self) {
        self.morning_check = MorningCheckSnapshot {
            phase: MorningCheckPhase::Warmup,
            ..Default::default()
        };
        self.morning_ppi_buffer.clear();
        self.ble.send_command(BleCommand::StartMorningCheck);
    }

    pub fn stop_morning_check(&mut self) {
        self.ble.send_command(BleCommand::StopMorningCheck);
        self.morning_check.phase = MorningCheckPhase::Idle;
    }

    /// Compute morning result from accumulated PPI samples + baseline history.
    /// baseline_history: vec of historical lnRMSSD values (up to 60 days, excluding today).
    pub fn compute_morning_result(&mut self, baseline_history: &[f64]) -> MorningResult {
        use polar_core::hrv::compute_hrv;
        use polar_core::scoring::{
            baseline_phase, compute_7day_mean, compute_baseline, score_readiness, BaselinePhase,
        };

        let preprocessed = preprocess_morning_samples(&self.morning_ppi_buffer);
        self.morning_check.diagnostics = Some(preprocessed.diagnostics.clone());

        if preprocessed.diagnostics.raw_samples == 0 {
            self.morning_check.phase = MorningCheckPhase::Error;
            self.morning_check.error =
                "No PPI data received from the sensor. Check strap contact and try again."
                    .to_string();
            self.morning_check.result = None;
            return MorningResult::default();
        }

        // Warmup filtering is handled inside compute_hrv using cumulative PPI
        // time (not wall-clock time) to avoid discarding valid samples from
        // large initial batches common with the Verity Sense optical sensor.
        let hrv = match compute_hrv(&preprocessed.inputs, MORNING_WARMUP_S) {
            Ok(r) => r,
            Err(e) => {
                self.morning_check.phase = MorningCheckPhase::Error;
                self.morning_check.error = e.to_string();
                self.morning_check.result = None;
                return MorningResult::default();
            }
        };

        // Compute baseline and scoring.
        // Use the 7-day rolling mean as the decision input so the traffic light reflects
        // the recent trend rather than reacting to a single-day spike (Esco et al. 2025).
        let baseline = compute_baseline(baseline_history);
        let phase = baseline_phase(baseline.day_count);
        let ln_rmssd_7day = compute_7day_mean(hrv.ln_rmssd, baseline_history);
        let scoring = score_readiness(ln_rmssd_7day, &baseline);

        let readiness_str = match scoring.readiness {
            polar_core::scoring::Readiness::Green => "green",
            polar_core::scoring::Readiness::Amber => "amber",
            polar_core::scoring::Readiness::Red => "red",
        };

        // If still building baseline (< 7 days), indicate that
        let readiness_str = if matches!(phase, BaselinePhase::Building(_)) {
            "building"
        } else {
            readiness_str
        };

        let stability_str = match scoring.stability {
            polar_core::scoring::Stability::Stable => "stable",
            polar_core::scoring::Stability::Variable => "variable",
        };

        let result = MorningResult {
            ln_rmssd: hrv.ln_rmssd,
            ln_rmssd_7day,
            rmssd_ms: hrv.rmssd_ms,
            resting_hr_bpm: hrv.resting_hr_bpm,
            rr_count: hrv.rr_count,
            rejected_count: 0,
            readiness: readiness_str.to_string(),
            stability: stability_str.to_string(),
            baseline_mean: scoring.baseline.mean,
            baseline_sd: scoring.baseline.sd,
            cv_7day: scoring.baseline.cv_7day,
            day_count: scoring.baseline.day_count,
        };

        self.morning_check.error.clear();
        self.morning_check.result = Some(result.clone());
        self.morning_check.phase = MorningCheckPhase::Done;
        result
    }

    // ── Session processing ──────────────────────────────────────

    /// Process downloaded HR data into a session summary.
    /// Call after file sync completes and hr_data is available.
    pub fn process_session(&mut self, hr_max: u16, hr_rest: u16) -> Option<SessionSummary> {
        use polar_core::trimp::edwards_trimp;
        use polar_core::zones::{classify_hr_series, AthleteConfig};

        let hr_data = self.files.hr_data.as_ref()?;

        if hr_data.samples.is_empty() {
            return None;
        }

        let config = AthleteConfig {
            hr_max,
            hr_rest,
            zones: AthleteConfig::default().zones,
        };

        let distribution = classify_hr_series(&hr_data.samples, &config);
        let trimp = edwards_trimp(&distribution);

        let summary = SessionSummary {
            start_time: hr_data.start_time.clone(),
            duration_s: distribution.duration_s,
            trimp_edwards: trimp,
            hr_avg: distribution.hr_avg,
            hr_max: distribution.hr_max_observed,
            hr_min: distribution.hr_min,
            zone_seconds: distribution.zone_seconds.to_vec(),
            zone_percent: distribution.zone_percent.to_vec(),
        };

        self.files.session_summary = Some(summary.clone());
        Some(summary)
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
                self.device_ops = DeviceOpsSnapshot::default();
            }
            BleEvent::Error(msg) => {
                self.connection.error = msg.clone();
                // Also set on sub-states if relevant
                if self.streaming.is_streaming {
                    self.streaming.is_streaming = false;
                }
                if self.files.is_syncing {
                    self.files.error = msg.clone();
                }
                if self.device_ops.is_busy {
                    self.device_ops.is_busy = false;
                    self.device_ops.error = msg;
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
                self.files.progress_text =
                    format!("Complete — {} files", self.files.downloaded_csvs.len());
            }
            BleEvent::HrDataReady(data) => {
                self.files.hr_data = Some(data);
            }
            BleEvent::TriggerStatus(mode) => {
                self.recording.status_text = format!("Trigger: {}", mode);
            }
            BleEvent::TriggerSet(mode) => {
                self.recording.status_text = format!("Trigger set to: {}", mode);
            }
            BleEvent::MorningCheckProgress {
                phase,
                elapsed_s,
                hr_bpm,
                ppi_count,
            } => {
                self.morning_check.phase = if phase == "warmup" {
                    MorningCheckPhase::Warmup
                } else {
                    MorningCheckPhase::Recording
                };
                self.morning_check.elapsed_s = elapsed_s;
                self.morning_check.hr_bpm = hr_bpm;
                self.morning_check.ppi_count = ppi_count;
            }
            BleEvent::MorningCheckComplete { samples } => {
                self.morning_ppi_buffer = samples;
                self.morning_check.phase = MorningCheckPhase::Computing;
                self.morning_check.ppi_count = self.morning_ppi_buffer.len();
                self.morning_check.error.clear();
            }
            BleEvent::MorningCheckError(msg) => {
                self.morning_check.phase = MorningCheckPhase::Error;
                self.morning_check.error = msg;
                self.morning_check.diagnostics = Some(MorningCheckDiagnostics {
                    raw_samples: self.morning_check.ppi_count,
                    ..Default::default()
                });
            }
            BleEvent::DeviceOpsProgress(msg) => {
                self.device_ops.progress_text = msg;
            }
            BleEvent::DeviceOpsComplete(msg) => {
                self.device_ops.is_busy = false;
                self.device_ops.progress_text = msg;
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

    pub fn morning_check_snapshot(&self) -> MorningCheckSnapshot {
        self.morning_check.clone()
    }

    pub fn device_ops_snapshot(&self) -> DeviceOpsSnapshot {
        self.device_ops.clone()
    }
}

/// Convert timed PPI samples into HRV inputs.
///
/// Filters out zero-PPI samples (optical sensor can't determine interval)
/// and zeroes the flags byte (Verity Sense flags are diagnostic-only, not
/// the blocker flag used by chest straps).
///
/// Warmup is NOT filtered here — it is handled by `compute_hrv` using
/// cumulative PPI time. Wall-clock warmup was previously used but caused
/// valid samples to be discarded when the sensor sends large initial
/// batches that get back-dated past the warmup boundary.
fn preprocess_morning_samples(
    samples: &[TimedMorningPpiSample],
) -> PreprocessedMorningSamples {
    let mut inputs = Vec::with_capacity(samples.len());
    let mut flagged_samples = 0usize;
    let mut zero_ppi = 0usize;

    for sample in samples {
        if sample.flags != 0 {
            flagged_samples += 1;
        }

        if sample.ppi_ms == 0 {
            zero_ppi += 1;
            continue;
        }

        inputs.push(PpiInput {
            hr: if sample.display_hr_bpm > 0 {
                sample.display_hr_bpm
            } else {
                derive_hr_bpm(sample.ppi_ms)
            },
            ppi_ms: sample.ppi_ms,
            error_estimate: sample.error_estimate,
            flags: 0,
        });
    }

    PreprocessedMorningSamples {
        diagnostics: MorningCheckDiagnostics {
            raw_samples: samples.len(),
            warmup_discarded: zero_ppi,
            flagged_samples,
            valid_post_warmup: inputs.len(),
        },
        inputs,
    }
}

fn derive_hr_bpm(ppi_ms: u16) -> u8 {
    if ppi_ms == 0 {
        return 0;
    }

    ((60_000.0 / ppi_ms as f64).round()).clamp(0.0, u8::MAX as f64) as u8
}

#[cfg(test)]
mod tests {
    use super::{derive_hr_bpm, preprocess_morning_samples};
    use crate::state::TimedMorningPpiSample;

    #[test]
    fn derive_hr_bpm_returns_zero_for_zero_ppi() {
        assert_eq!(derive_hr_bpm(0), 0);
    }

    #[test]
    fn derive_hr_bpm_maps_rr_to_expected_bpm() {
        assert_eq!(derive_hr_bpm(1000), 60);
        assert_eq!(derive_hr_bpm(750), 80);
    }

    #[test]
    fn preprocess_keeps_all_nonzero_ppi_and_zeros_flags() {
        let samples = vec![
            timed_sample(24.9, 1000),
            timed_sample(25.1, 980),
            timed_sample(26.0, 960),
        ];

        let preprocessed = preprocess_morning_samples(&samples);

        assert_eq!(preprocessed.diagnostics.raw_samples, 3);
        assert_eq!(preprocessed.diagnostics.valid_post_warmup, 3);
        assert_eq!(preprocessed.inputs.len(), 3);
        // Flags are zeroed for Verity Sense compatibility
        assert!(preprocessed.inputs.iter().all(|sample| sample.flags == 0));
    }

    #[test]
    fn preprocess_drops_zero_ppi_samples() {
        let samples = vec![
            timed_sample(30.0, 1000),
            timed_sample(31.0, 0),
            timed_sample(32.0, 950),
        ];

        let preprocessed = preprocess_morning_samples(&samples);

        assert_eq!(preprocessed.diagnostics.raw_samples, 3);
        assert_eq!(preprocessed.diagnostics.warmup_discarded, 1); // zero_ppi count
        assert_eq!(preprocessed.diagnostics.valid_post_warmup, 2);
        assert_eq!(preprocessed.inputs.len(), 2);
    }

    #[test]
    fn preprocess_keeps_all_cli_like_verity_sense_trace() {
        let samples = cli_like_trace_samples();

        let preprocessed = preprocess_morning_samples(&samples);

        assert_eq!(preprocessed.diagnostics.raw_samples, samples.len());
        // All samples have non-zero ppi_ms, so all should survive preprocessing
        assert_eq!(preprocessed.diagnostics.valid_post_warmup, samples.len());
        assert_eq!(preprocessed.inputs.len(), samples.len());
        assert!(preprocessed.inputs.iter().all(|sample| sample.hr > 0));
        assert!(preprocessed.inputs.iter().all(|sample| sample.flags == 0));
    }

    fn timed_sample(elapsed_s: f64, ppi_ms: u16) -> TimedMorningPpiSample {
        TimedMorningPpiSample {
            elapsed_s,
            raw_hr_bpm: 0,
            display_hr_bpm: derive_hr_bpm(ppi_ms),
            ppi_ms,
            error_estimate: 10,
            flags: 0x07,
        }
    }

    fn cli_like_trace_samples() -> Vec<TimedMorningPpiSample> {
        let mut samples = Vec::new();
        samples.extend(trace_batch(
            16.1,
            &[376, 1149, 808, 948, 896, 965, 967, 945, 979],
        ));
        samples.extend(trace_batch(21.1, &[952, 927, 950, 997, 958]));
        samples.extend(trace_batch(26.1, &[964, 1000, 968, 994, 994]));
        samples.extend(trace_batch(31.1, &[956, 979, 969, 973, 923]));
        samples.extend(trace_batch(36.2, &[948, 948, 929, 958, 931, 867]));
        samples.extend(trace_batch(41.1, &[861, 815, 799, 823, 861, 887]));
        samples.extend(trace_batch(46.0, &[906, 902, 929, 941, 914]));
        samples.extend(trace_batch(50.8, &[945, 933, 931, 963, 965]));
        samples.extend(trace_batch(55.9, &[919, 935, 931, 937, 914, 959]));
        samples.extend(trace_batch(61.0, &[989, 972, 950, 952, 913]));
        samples
    }

    fn trace_batch(batch_elapsed_s: f64, ppi_values: &[u16]) -> Vec<TimedMorningPpiSample> {
        let mut trailing_s = 0.0;
        let mut samples = Vec::with_capacity(ppi_values.len());

        for ppi_ms in ppi_values.iter().rev() {
            samples.push(TimedMorningPpiSample {
                elapsed_s: (batch_elapsed_s - trailing_s).max(0.0),
                raw_hr_bpm: 0,
                display_hr_bpm: derive_hr_bpm(*ppi_ms),
                ppi_ms: *ppi_ms,
                error_estimate: 10,
                flags: 0x07,
            });
            trailing_s += *ppi_ms as f64 / 1000.0;
        }

        samples.reverse();
        samples
    }
}
