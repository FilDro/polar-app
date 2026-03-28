//! Background BLE runtime running on a dedicated tokio thread.
//!
//! All btleplug operations happen here. The main thread communicates
//! via sync channels (commands in, events out).

use std::sync::mpsc;
use std::time::Duration;

use polar_rs::ble::connection::PolarPeripheral;
use polar_rs::ble::scanner;
use polar_rs::ble::uuids;
use polar_rs::offline::download::download_recording;
use polar_rs::offline::listing;
use polar_rs::offline::workflow;
use polar_rs::pftp::client::PftpClient;
use polar_rs::pmd::codec::parse_pmd_frame;
use polar_rs::pmd::commands;
use polar_rs::pmd::data_types::PmdSamples;
use polar_rs::services::{battery, device_info, heart_rate};
use polar_rs::types::{MeasurementType, RecordingType};

use crate::state::{
    DownloadedCsv, FileEntry, ScannedDevice,
};

/// Commands sent from the main thread to the BLE runtime.
#[derive(Debug)]
pub enum BleCommand {
    StartScan { duration_s: u64 },
    StopScan,
    Connect { identifier: String },
    Disconnect,
    ReadDeviceInfo,
    // Streaming
    StartStream { config: StreamConfig },
    StopStream,
    // Recording
    StartRecording { types: Vec<String> },
    StopRecording { types: Vec<String> },
    CheckRecordingStatus,
    // Files
    ListFiles,
    SyncFiles,
    // Trigger
    SetTrigger { mode: String },
    GetTrigger,
}

#[derive(Debug, Clone)]
pub enum StreamConfig {
    Hr,
    Acc,
    Gyro,
    Imu,
    Full, // HR + ACC + GYRO + MAG (non-SDK, 52Hz)
}

impl StreamConfig {
    pub fn from_str(s: &str) -> Self {
        match s.to_lowercase().as_str() {
            "hr" => Self::Hr,
            "acc" => Self::Acc,
            "gyro" => Self::Gyro,
            "imu" => Self::Imu,
            "full" => Self::Full,
            _ => Self::Hr,
        }
    }

    pub fn as_str(&self) -> &'static str {
        match self {
            Self::Hr => "hr",
            Self::Acc => "acc",
            Self::Gyro => "gyro",
            Self::Imu => "imu",
            Self::Full => "full",
        }
    }
}

/// Events sent from BLE runtime back to the main thread.
#[derive(Debug)]
pub enum BleEvent {
    // Connection
    ScanResult(Vec<ScannedDevice>),
    ScanComplete,
    Connecting(String),
    Connected(String),
    Disconnected,
    Error(String),

    // Device info
    DeviceInfo {
        model: String,
        firmware: String,
        serial: String,
        battery: i32,
        disk_total_kb: i64,
        disk_free_kb: i64,
    },

    // Streaming
    StreamStarted(String),
    StreamStopped,
    HrSample { bpm: u16 },
    AccSamples {
        samples: Vec<[i32; 3]>,
        timestamp_ns: u64,
    },
    GyroSamples {
        samples: Vec<[f32; 3]>,
        timestamp_ns: u64,
    },

    // Recording
    RecordingStarted(Vec<String>),
    RecordingStopped,
    RecordingStatus(Vec<String>),

    // Files
    FileList(Vec<FileEntry>),
    FileSyncProgress(String),
    FileDownloaded(DownloadedCsv),
    FileSyncComplete,

    // Trigger
    TriggerStatus(String),
    TriggerSet(String),
}

/// The BLE runtime handle. Lives on the main thread.
pub struct BleRuntime {
    cmd_tx: mpsc::Sender<BleCommand>,
    event_rx: mpsc::Receiver<BleEvent>,
    _thread: std::thread::JoinHandle<()>,
}

impl BleRuntime {
    pub fn new() -> Self {
        let (cmd_tx, cmd_rx) = mpsc::channel::<BleCommand>();
        let (event_tx, event_rx) = mpsc::channel::<BleEvent>();

        let thread = std::thread::Builder::new()
            .name("ble-runtime".into())
            .spawn(move || {
                let rt = tokio::runtime::Runtime::new()
                    .expect("failed to create tokio runtime");
                rt.block_on(ble_runtime_loop(cmd_rx, event_tx));
            })
            .expect("failed to spawn BLE thread");

        Self {
            cmd_tx,
            event_rx,
            _thread: thread,
        }
    }

    pub fn send_command(&self, cmd: BleCommand) {
        let _ = self.cmd_tx.send(cmd);
    }

    /// Drain all pending events (non-blocking).
    pub fn drain_events(&self) -> Vec<BleEvent> {
        let mut events = Vec::new();
        while let Ok(ev) = self.event_rx.try_recv() {
            events.push(ev);
        }
        events
    }
}

/// Main async loop running on the BLE background thread.
async fn ble_runtime_loop(
    cmd_rx: mpsc::Receiver<BleCommand>,
    event_tx: mpsc::Sender<BleEvent>,
) {
    let mut peripheral: Option<PolarPeripheral> = None;

    loop {
        // Check for commands (non-blocking from async context)
        let cmd = match cmd_rx.try_recv() {
            Ok(cmd) => Some(cmd),
            Err(mpsc::TryRecvError::Empty) => {
                // No command, sleep briefly to avoid busy-loop
                tokio::time::sleep(Duration::from_millis(10)).await;
                None
            }
            Err(mpsc::TryRecvError::Disconnected) => break,
        };

        let Some(cmd) = cmd else { continue };

        match cmd {
            BleCommand::StartScan { duration_s } => {
                handle_scan(&event_tx, duration_s).await;
            }
            BleCommand::StopScan => {
                // btleplug doesn't have explicit stop_scan; scan is bounded by duration
            }
            BleCommand::Connect { identifier } => {
                let _ = event_tx.send(BleEvent::Connecting(identifier.clone()));
                match handle_connect(&identifier).await {
                    Ok(p) => {
                        let name = identifier.clone();
                        peripheral = Some(p);
                        let _ = event_tx.send(BleEvent::Connected(name));
                    }
                    Err(e) => {
                        let _ = event_tx.send(BleEvent::Error(format!("Connect failed: {}", e)));
                    }
                }
            }
            BleCommand::Disconnect => {
                if let Some(ref p) = peripheral {
                    let _ = p.disconnect().await;
                }
                peripheral = None;
                let _ = event_tx.send(BleEvent::Disconnected);
            }
            BleCommand::ReadDeviceInfo => {
                if let Some(ref p) = peripheral {
                    handle_device_info(p, &event_tx).await;
                }
            }
            BleCommand::StartStream { config } => {
                if let Some(ref p) = peripheral {
                    handle_stream(p, &config, &event_tx, &cmd_rx).await;
                    let _ = event_tx.send(BleEvent::StreamStopped);
                }
            }
            BleCommand::StopStream => {
                // Stream loop checks for StopStream via cmd_rx
            }
            BleCommand::StartRecording { types } => {
                if let Some(ref p) = peripheral {
                    handle_start_recording(p, &types, &event_tx).await;
                }
            }
            BleCommand::StopRecording { types } => {
                if let Some(ref p) = peripheral {
                    handle_stop_recording(p, &types, &event_tx).await;
                }
            }
            BleCommand::CheckRecordingStatus => {
                if let Some(ref p) = peripheral {
                    handle_recording_status(p, &event_tx).await;
                }
            }
            BleCommand::ListFiles => {
                if let Some(ref p) = peripheral {
                    handle_list_files(p, &event_tx).await;
                }
            }
            BleCommand::SyncFiles => {
                if let Some(ref p) = peripheral {
                    handle_sync_files(p, &event_tx).await;
                }
            }
            BleCommand::SetTrigger { mode } => {
                if let Some(ref p) = peripheral {
                    handle_set_trigger(p, &mode, &event_tx).await;
                }
            }
            BleCommand::GetTrigger => {
                if let Some(ref p) = peripheral {
                    handle_get_trigger(p, &event_tx).await;
                }
            }
        }
    }
}

async fn handle_scan(event_tx: &mpsc::Sender<BleEvent>, duration_s: u64) {
    match scanner::scan(Duration::from_secs(duration_s)).await {
        Ok(devices) => {
            let scanned: Vec<ScannedDevice> = devices
                .into_iter()
                .map(|d| {
                    let identifier = d
                        .name
                        .split_whitespace()
                        .last()
                        .unwrap_or(&d.name)
                        .to_string();
                    ScannedDevice {
                        name: d.name,
                        identifier,
                        rssi: d.rssi.unwrap_or(0) as i32,
                    }
                })
                .collect();
            let _ = event_tx.send(BleEvent::ScanResult(scanned));
        }
        Err(e) => {
            let _ = event_tx.send(BleEvent::Error(format!("Scan failed: {}", e)));
        }
    }
    let _ = event_tx.send(BleEvent::ScanComplete);
}

async fn handle_connect(identifier: &str) -> Result<PolarPeripheral, Box<dyn std::error::Error + Send + Sync>> {
    let device = scanner::find_device(identifier, Duration::from_secs(10)).await?;
    let peripheral = PolarPeripheral::connect(device.peripheral).await?;
    // Enable PFTP notifications for file operations
    let _ = peripheral.enable_notifications(uuids::PFTP_MTU).await;
    let _ = peripheral.enable_notifications(uuids::PFTP_D2H).await;
    Ok(peripheral)
}

async fn handle_device_info(p: &PolarPeripheral, event_tx: &mpsc::Sender<BleEvent>) {
    use polar_rs::ble::transport::BleTransport;

    let model = p.read(uuids::DIS_MODEL_NUMBER).await
        .ok()
        .and_then(|d| device_info::parse_dis_string(&d))
        .unwrap_or_default();
    let firmware = p.read(uuids::DIS_FIRMWARE_REV).await
        .ok()
        .and_then(|d| device_info::parse_dis_string(&d))
        .unwrap_or_default();
    let serial = p.read(uuids::DIS_SERIAL_NUMBER).await
        .ok()
        .and_then(|d| device_info::parse_dis_string(&d))
        .unwrap_or_default();
    let bat = p.read(uuids::BATTERY_LEVEL).await
        .ok()
        .and_then(|d| battery::parse_battery_level(&d))
        .map(|b| b as i32)
        .unwrap_or(-1);

    let pftp = PftpClient::new(p);
    let (disk_total_kb, disk_free_kb) = match pftp.get_disk_space().await {
        Ok((total, free)) => ((total / 1024) as i64, (free / 1024) as i64),
        Err(_) => (-1, -1),
    };

    let _ = event_tx.send(BleEvent::DeviceInfo {
        model,
        firmware,
        serial,
        battery: bat,
        disk_total_kb,
        disk_free_kb,
    });
}

async fn handle_stream(
    p: &PolarPeripheral,
    config: &StreamConfig,
    event_tx: &mpsc::Sender<BleEvent>,
    cmd_rx: &mpsc::Receiver<BleCommand>,
) {
    use polar_rs::ble::transport::BleTransport;

    // Enable PMD notifications
    if let Err(e) = p.enable_notifications(uuids::PMD_CP).await {
        let _ = event_tx.send(BleEvent::Error(format!("PMD CP notify failed: {}", e)));
        return;
    }

    let config_name = config.as_str().to_string();

    match config {
        StreamConfig::Hr => {
            stream_hr(p, event_tx, cmd_rx).await;
        }
        StreamConfig::Acc | StreamConfig::Gyro | StreamConfig::Imu => {
            // SDK mode for high-frequency streaming
            if let Err(e) = p.enable_notifications(uuids::PMD_DATA).await {
                let _ = event_tx.send(BleEvent::Error(format!("PMD DATA notify failed: {}", e)));
                return;
            }

            let enable_sdk = commands::build_enable_sdk_mode();
            if let Err(e) = p.write(uuids::PMD_CP, &enable_sdk, polar_rs::ble::transport::WriteType::WithResponse).await {
                let _ = event_tx.send(BleEvent::Error(format!("SDK mode failed: {}", e)));
                return;
            }
            tokio::time::sleep(Duration::from_millis(500)).await;

            let types = match config {
                StreamConfig::Acc => vec![MeasurementType::Acc],
                StreamConfig::Gyro => vec![MeasurementType::Gyro],
                StreamConfig::Imu => vec![MeasurementType::Acc, MeasurementType::Gyro],
                _ => unreachable!(),
            };

            // Start each stream
            for mt in &types {
                let (rate, range) = match mt {
                    MeasurementType::Acc => (416u16, 8u16),
                    MeasurementType::Gyro => (416, 2000),
                    _ => (416, 8),
                };
                let cmd = commands::build_start_stream(*mt, RecordingType::Online, rate, 16, range, 3);
                let _ = p.write(uuids::PMD_CP, &cmd, polar_rs::ble::transport::WriteType::WithResponse).await;
                tokio::time::sleep(Duration::from_millis(200)).await;
            }

            let _ = event_tx.send(BleEvent::StreamStarted(config_name));

            // Read streaming data
            stream_pmd(p, event_tx, cmd_rx).await;

            // Stop streams
            for mt in &types {
                let cmd = commands::build_stop_stream(*mt);
                let _ = p.write(uuids::PMD_CP, &cmd, polar_rs::ble::transport::WriteType::WithResponse).await;
            }

            // Disable SDK mode
            let disable = commands::build_disable_sdk_mode();
            let _ = p.write(uuids::PMD_CP, &disable, polar_rs::ble::transport::WriteType::WithResponse).await;
        }
        StreamConfig::Full => {
            // Non-SDK mode: HR + 52Hz IMU
            if let Err(e) = p.enable_notifications(uuids::PMD_DATA).await {
                let _ = event_tx.send(BleEvent::Error(format!("PMD DATA notify failed: {}", e)));
                return;
            }

            // Start ACC, GYRO, MAG at 52Hz (no SDK mode)
            let imu_types = [
                (MeasurementType::Acc, 52u16, 8u16),
                (MeasurementType::Gyro, 52, 2000),
                (MeasurementType::Magnetometer, 50, 50),
            ];
            for (mt, rate, range) in &imu_types {
                let cmd = commands::build_start_stream(*mt, RecordingType::Online, *rate, 16, *range, 3);
                let _ = p.write(uuids::PMD_CP, &cmd, polar_rs::ble::transport::WriteType::WithResponse).await;
                tokio::time::sleep(Duration::from_millis(200)).await;
            }

            let _ = event_tx.send(BleEvent::StreamStarted(config.as_str().to_string()));

            // Stream HR + PMD concurrently
            stream_hr_and_pmd(p, event_tx, cmd_rx).await;

            // Stop IMU streams
            for (mt, _, _) in &imu_types {
                let cmd = commands::build_stop_stream(*mt);
                let _ = p.write(uuids::PMD_CP, &cmd, polar_rs::ble::transport::WriteType::WithResponse).await;
            }
        }
    }
}

async fn stream_hr(
    p: &PolarPeripheral,
    event_tx: &mpsc::Sender<BleEvent>,
    cmd_rx: &mpsc::Receiver<BleCommand>,
) {
    use polar_rs::ble::transport::BleTransport;

    let _ = event_tx.send(BleEvent::StreamStarted("hr".to_string()));

    if let Err(e) = p.enable_notifications(uuids::HR_MEASUREMENT).await {
        let _ = event_tx.send(BleEvent::Error(format!("HR notify failed: {}", e)));
        return;
    }

    let mut rx = match p.subscribe(uuids::HR_MEASUREMENT).await {
        Ok(rx) => rx,
        Err(e) => {
            let _ = event_tx.send(BleEvent::Error(format!("HR subscribe failed: {}", e)));
            return;
        }
    };

    loop {
        // Check for stop command
        if let Ok(cmd) = cmd_rx.try_recv() {
            if matches!(cmd, BleCommand::StopStream | BleCommand::Disconnect) {
                break;
            }
        }

        match tokio::time::timeout(Duration::from_millis(2000), rx.recv()).await {
            Ok(Ok(notif)) => {
                if let Some(hr) = heart_rate::parse_hr_measurement(&notif.data) {
                    let _ = event_tx.send(BleEvent::HrSample { bpm: hr.hr_bpm });
                }
            }
            Ok(Err(_)) => break, // Channel closed
            Err(_) => continue,  // Timeout, keep waiting
        }
    }
}

async fn stream_pmd(
    p: &PolarPeripheral,
    event_tx: &mpsc::Sender<BleEvent>,
    cmd_rx: &mpsc::Receiver<BleCommand>,
) {
    use polar_rs::ble::transport::BleTransport;

    let mut rx = match p.subscribe(uuids::PMD_DATA).await {
        Ok(rx) => rx,
        Err(e) => {
            let _ = event_tx.send(BleEvent::Error(format!("PMD subscribe failed: {}", e)));
            return;
        }
    };

    loop {
        if let Ok(cmd) = cmd_rx.try_recv() {
            if matches!(cmd, BleCommand::StopStream | BleCommand::Disconnect) {
                break;
            }
        }

        match tokio::time::timeout(Duration::from_millis(2000), rx.recv()).await {
            Ok(Ok(notif)) => {
                if let Ok(frame) = parse_pmd_frame(&notif.data, 1.0) {
                    match frame.samples {
                        PmdSamples::Acc(ref samples) => {
                            let _ = event_tx.send(BleEvent::AccSamples {
                                samples: samples.clone(),
                                timestamp_ns: frame.timestamp_ns,
                            });
                        }
                        PmdSamples::Gyro(ref samples) => {
                            let _ = event_tx.send(BleEvent::GyroSamples {
                                samples: samples.clone(),
                                timestamp_ns: frame.timestamp_ns,
                            });
                        }
                        _ => {}
                    }
                }
            }
            Ok(Err(_)) => break,
            Err(_) => continue,
        }
    }
}

async fn stream_hr_and_pmd(
    p: &PolarPeripheral,
    event_tx: &mpsc::Sender<BleEvent>,
    cmd_rx: &mpsc::Receiver<BleCommand>,
) {
    use polar_rs::ble::transport::BleTransport;

    let _ = p.enable_notifications(uuids::HR_MEASUREMENT).await;

    let mut hr_rx = p.subscribe(uuids::HR_MEASUREMENT).await.ok();
    let mut pmd_rx = p.subscribe(uuids::PMD_DATA).await.ok();

    loop {
        if let Ok(cmd) = cmd_rx.try_recv() {
            if matches!(cmd, BleCommand::StopStream | BleCommand::Disconnect) {
                break;
            }
        }

        // Poll HR
        if let Some(ref mut rx) = hr_rx {
            if let Ok(notif) = rx.try_recv() {
                if let Some(hr) = heart_rate::parse_hr_measurement(&notif.data) {
                    let _ = event_tx.send(BleEvent::HrSample { bpm: hr.hr_bpm });
                }
            }
        }

        // Poll PMD
        if let Some(ref mut rx) = pmd_rx {
            // Drain all available PMD notifications
            loop {
                match rx.try_recv() {
                    Ok(notif) => {
                        if let Ok(frame) = parse_pmd_frame(&notif.data, 1.0) {
                            match frame.samples {
                                PmdSamples::Acc(ref samples) => {
                                    let _ = event_tx.send(BleEvent::AccSamples {
                                        samples: samples.clone(),
                                        timestamp_ns: frame.timestamp_ns,
                                    });
                                }
                                PmdSamples::Gyro(ref samples) => {
                                    let _ = event_tx.send(BleEvent::GyroSamples {
                                        samples: samples.clone(),
                                        timestamp_ns: frame.timestamp_ns,
                                    });
                                }
                                _ => {}
                            }
                        }
                    }
                    Err(_) => break,
                }
            }
        }

        tokio::time::sleep(Duration::from_millis(10)).await;
    }
}

fn parse_measurement_types(types: &[String]) -> Vec<MeasurementType> {
    types
        .iter()
        .filter_map(|t| match t.to_lowercase().as_str() {
            "acc" => Some(MeasurementType::Acc),
            "gyro" => Some(MeasurementType::Gyro),
            "mag" | "magnetometer" => Some(MeasurementType::Magnetometer),
            "ppg" => Some(MeasurementType::Ppg),
            "ppi" => Some(MeasurementType::Ppi),
            "hr" => Some(MeasurementType::OfflineHr),
            _ => None,
        })
        .collect()
}

async fn handle_start_recording(
    p: &PolarPeripheral,
    types: &[String],
    event_tx: &mpsc::Sender<BleEvent>,
) {
    use polar_rs::ble::transport::BleTransport;

    if let Err(e) = p.enable_notifications(uuids::PMD_CP).await {
        let _ = event_tx.send(BleEvent::Error(format!("PMD CP failed: {}", e)));
        return;
    }

    let meas_types = parse_measurement_types(types);
    match workflow::start_recording(p, &meas_types).await {
        Ok(()) => {
            let _ = event_tx.send(BleEvent::RecordingStarted(types.to_vec()));
        }
        Err(e) => {
            let _ = event_tx.send(BleEvent::Error(format!("Recording start failed: {}", e)));
        }
    }
}

async fn handle_stop_recording(
    p: &PolarPeripheral,
    types: &[String],
    event_tx: &mpsc::Sender<BleEvent>,
) {
    use polar_rs::ble::transport::BleTransport;

    let _ = p.enable_notifications(uuids::PMD_CP).await;

    let meas_types = parse_measurement_types(types);
    match workflow::stop_recording(p, &meas_types).await {
        Ok(()) => {
            let _ = event_tx.send(BleEvent::RecordingStopped);
        }
        Err(e) => {
            let _ = event_tx.send(BleEvent::Error(format!("Recording stop failed: {}", e)));
        }
    }
}

async fn handle_recording_status(
    p: &PolarPeripheral,
    event_tx: &mpsc::Sender<BleEvent>,
) {
    use polar_rs::ble::transport::BleTransport;

    let _ = p.enable_notifications(uuids::PMD_CP).await;

    match workflow::get_recording_status(p).await {
        Ok(data) => {
            // Parse active types from response
            let mut active = Vec::new();
            if data.len() > 4 && data[3] == 0 {
                for &byte in &data[4..] {
                    match byte {
                        0x02 => active.push("acc".to_string()),
                        0x05 => active.push("gyro".to_string()),
                        0x06 => active.push("mag".to_string()),
                        0x01 => active.push("ppg".to_string()),
                        0x03 => active.push("ppi".to_string()),
                        0x0E => active.push("hr".to_string()),
                        _ => {}
                    }
                }
            }
            let _ = event_tx.send(BleEvent::RecordingStatus(active));
        }
        Err(e) => {
            let _ = event_tx.send(BleEvent::Error(format!("Status check failed: {}", e)));
        }
    }
}

async fn handle_list_files(
    p: &PolarPeripheral,
    event_tx: &mpsc::Sender<BleEvent>,
) {
    let pftp = PftpClient::new(p);

    if let Err(e) = pftp.start_sync().await {
        let _ = event_tx.send(BleEvent::Error(format!("Start sync failed: {}", e)));
        return;
    }

    match listing::list_recordings(&pftp).await {
        Ok(entries) => {
            let file_entries: Vec<FileEntry> = entries
                .iter()
                .map(|e| FileEntry {
                    path: e.path.clone(),
                    data_type: e.data_type.clone(),
                    date: e.date.clone(),
                    size_bytes: e.size,
                })
                .collect();
            let _ = event_tx.send(BleEvent::FileList(file_entries));
        }
        Err(e) => {
            let _ = event_tx.send(BleEvent::Error(format!("List failed: {}", e)));
        }
    }

    let _ = pftp.stop_sync().await;
}

async fn handle_sync_files(
    p: &PolarPeripheral,
    event_tx: &mpsc::Sender<BleEvent>,
) {
    let pftp = PftpClient::new(p);

    if let Err(e) = pftp.start_sync().await {
        let _ = event_tx.send(BleEvent::Error(format!("Start sync failed: {}", e)));
        return;
    }

    let entries = match listing::list_recordings(&pftp).await {
        Ok(entries) => entries,
        Err(e) => {
            let _ = event_tx.send(BleEvent::Error(format!("List failed: {}", e)));
            let _ = pftp.stop_sync().await;
            return;
        }
    };

    let total = entries.len();
    for (i, entry) in entries.iter().enumerate() {
        let _ = event_tx.send(BleEvent::FileSyncProgress(
            format!("{}/{} — {}", i + 1, total, entry.path),
        ));

        match download_recording(&pftp, entry).await {
            Ok(recording) => {
                let csv = recording_to_csv(&recording);
                let session_time = entry.path.split('/').rev().nth(1).unwrap_or("unknown");
                let type_name = entry.path.split('/').last().unwrap_or("REC").replace(".REC", "");
                let filename = format!("{}_{}.csv", session_time, type_name);

                let _ = event_tx.send(BleEvent::FileDownloaded(DownloadedCsv {
                    filename,
                    data_type: entry.data_type.clone(),
                    sample_count: recording.sample_count() as u64,
                    csv_content: csv,
                }));
            }
            Err(e) => {
                let _ = event_tx.send(BleEvent::Error(format!(
                    "Failed to parse {}: {}",
                    entry.path, e
                )));
            }
        }
    }

    let _ = pftp.stop_sync().await;
    let _ = event_tx.send(BleEvent::FileSyncComplete);
}

async fn handle_set_trigger(
    p: &PolarPeripheral,
    mode: &str,
    event_tx: &mpsc::Sender<BleEvent>,
) {
    use polar_rs::ble::transport::BleTransport;

    let _ = p.enable_notifications(uuids::PMD_CP).await;

    let trigger_mode = match workflow::TriggerMode::from_str(mode) {
        Some(m) => m,
        None => {
            let _ = event_tx.send(BleEvent::Error(format!("Unknown trigger mode: {}", mode)));
            return;
        }
    };

    match workflow::set_trigger(p, trigger_mode).await {
        Ok(()) => {
            let _ = event_tx.send(BleEvent::TriggerSet(mode.to_string()));
        }
        Err(e) => {
            let _ = event_tx.send(BleEvent::Error(format!("Set trigger failed: {}", e)));
        }
    }
}

async fn handle_get_trigger(
    p: &PolarPeripheral,
    event_tx: &mpsc::Sender<BleEvent>,
) {
    use polar_rs::ble::transport::BleTransport;

    let _ = p.enable_notifications(uuids::PMD_CP).await;

    match workflow::get_trigger_status(p).await {
        Ok(data) => {
            let mode = if data.len() > 5 {
                match data[5] {
                    0 => "disabled",
                    1 => "system-start",
                    2 => "exercise-start",
                    _ => "unknown",
                }
            } else {
                "unknown"
            };
            let _ = event_tx.send(BleEvent::TriggerStatus(mode.to_string()));
        }
        Err(e) => {
            let _ = event_tx.send(BleEvent::Error(format!("Get trigger failed: {}", e)));
        }
    }
}

/// Convert an offline recording to CSV string.
fn recording_to_csv(recording: &polar_rs::offline::file_format::OfflineRecording) -> String {
    use polar_rs::pmd::timestamps::distribute_timestamps;

    let mut csv = String::new();
    let mut prev_ts: Option<u64> = None;
    let sample_rate = recording.settings.sample_rates.first().copied().unwrap_or(52);

    for frame in &recording.frames {
        let count = frame.samples.len();
        let timestamps = distribute_timestamps(frame.timestamp_ns, prev_ts, count, sample_rate);
        prev_ts = Some(frame.timestamp_ns);

        match &frame.samples {
            PmdSamples::Acc(samples) => {
                if csv.is_empty() { csv.push_str("timestamp_ns,x_mg,y_mg,z_mg\n"); }
                for (i, s) in samples.iter().enumerate() {
                    let ts = timestamps.get(i).copied().unwrap_or(frame.timestamp_ns);
                    csv.push_str(&format!("{},{},{},{}\n", ts, s[0], s[1], s[2]));
                }
            }
            PmdSamples::Gyro(samples) => {
                if csv.is_empty() { csv.push_str("timestamp_ns,x_dps,y_dps,z_dps\n"); }
                for (i, s) in samples.iter().enumerate() {
                    let ts = timestamps.get(i).copied().unwrap_or(frame.timestamp_ns);
                    csv.push_str(&format!("{},{:.2},{:.2},{:.2}\n", ts, s[0], s[1], s[2]));
                }
            }
            PmdSamples::Mag(samples) => {
                if csv.is_empty() { csv.push_str("timestamp_ns,x,y,z\n"); }
                for (i, s) in samples.iter().enumerate() {
                    let ts = timestamps.get(i).copied().unwrap_or(frame.timestamp_ns);
                    csv.push_str(&format!("{},{:.4},{:.4},{:.4}\n", ts, s[0], s[1], s[2]));
                }
            }
            PmdSamples::Hr(samples) => {
                if csv.is_empty() { csv.push_str("timestamp_ns,hr_bpm,ppg_quality,corrected_hr\n"); }
                for (i, s) in samples.iter().enumerate() {
                    let ts = timestamps.get(i).copied().unwrap_or(frame.timestamp_ns);
                    csv.push_str(&format!("{},{},{},{}\n", ts, s.hr, s.ppg_quality, s.corrected_hr));
                }
            }
            PmdSamples::Ppi(samples) => {
                if csv.is_empty() { csv.push_str("timestamp_ns,hr_bpm,ppi_ms,error_estimate,flags\n"); }
                for (i, s) in samples.iter().enumerate() {
                    let ts = timestamps.get(i).copied().unwrap_or(frame.timestamp_ns);
                    csv.push_str(&format!("{},{},{},{},{}\n", ts, s.hr, s.ppi_ms, s.error_estimate, s.flags));
                }
            }
            PmdSamples::Ppg(samples) => {
                if csv.is_empty() {
                    let nchan = samples.first().map_or(4, |s| s.len());
                    let header: Vec<String> = (0..nchan).map(|i| format!("ch{}", i)).collect();
                    csv.push_str(&format!("timestamp_ns,{}\n", header.join(",")));
                }
                for (i, s) in samples.iter().enumerate() {
                    let ts = timestamps.get(i).copied().unwrap_or(frame.timestamp_ns);
                    let vals: Vec<String> = s.iter().map(|v| v.to_string()).collect();
                    csv.push_str(&format!("{},{}\n", ts, vals.join(",")));
                }
            }
            _ => {
                if csv.is_empty() { csv.push_str("timestamp_ns,raw\n"); }
                csv.push_str(&format!("{},unsupported\n", frame.timestamp_ns));
            }
        }
    }

    if csv.is_empty() { csv.push_str("# empty recording\n"); }
    csv
}
