//! FFI bridge for polar-engine.
//!
//! All functions are #[frb(sync)]. Zero logic here — every function
//! delegates to PolarSession via the global SESSION mutex.

use std::sync::Mutex;
use polar_engine::session::PolarSession;

static SESSION: Mutex<Option<PolarSession>> = Mutex::new(None);

fn with_session<R>(f: impl FnOnce(&mut PolarSession) -> R) -> R {
    let mut guard = SESSION.lock().expect("session mutex poisoned");
    let session = guard.get_or_insert_with(PolarSession::new);
    f(session)
}

// ── FRB-friendly types ──────────────────────────────────────────

#[flutter_rust_bridge::frb]
#[derive(Debug, Clone)]
pub struct PolarScannedDevice {
    pub name: String,
    pub identifier: String,
    pub rssi: i32,
}

#[flutter_rust_bridge::frb]
#[derive(Debug, Clone)]
pub struct PolarConnectionState {
    pub status: String,
    pub device_name: String,
    pub device_id: String,
    pub battery_percent: i32,
    pub model: String,
    pub firmware: String,
    pub serial: String,
    pub disk_total_kb: i64,
    pub disk_free_kb: i64,
    pub devices: Vec<PolarScannedDevice>,
    pub error: String,
}

#[flutter_rust_bridge::frb]
#[derive(Debug, Clone)]
pub struct PolarStreamState {
    pub is_streaming: bool,
    pub config: String,
    pub hr_bpm: i32,
    pub sample_count: u64,
    pub elapsed_s: f64,
    pub chart_acc_timestamps: Vec<f64>,
    pub chart_acc_x: Vec<f32>,
    pub chart_acc_y: Vec<f32>,
    pub chart_acc_z: Vec<f32>,
    pub chart_gyro_timestamps: Vec<f64>,
    pub chart_gyro_x: Vec<f32>,
    pub chart_gyro_y: Vec<f32>,
    pub chart_gyro_z: Vec<f32>,
}

#[flutter_rust_bridge::frb]
#[derive(Debug, Clone)]
pub struct PolarRecordingState {
    pub is_recording: bool,
    pub active_types: Vec<String>,
    pub status_text: String,
    pub error: String,
}

#[flutter_rust_bridge::frb]
#[derive(Debug, Clone)]
pub struct PolarFileEntry {
    pub path: String,
    pub data_type: String,
    pub date: String,
    pub size_bytes: u64,
}

#[flutter_rust_bridge::frb]
#[derive(Debug, Clone)]
pub struct PolarDownloadedCsv {
    pub filename: String,
    pub data_type: String,
    pub sample_count: u64,
    pub csv_content: String,
}

#[flutter_rust_bridge::frb]
#[derive(Debug, Clone)]
pub struct PolarFilesState {
    pub is_syncing: bool,
    pub entries: Vec<PolarFileEntry>,
    pub progress_text: String,
    pub downloaded_csvs: Vec<PolarDownloadedCsv>,
    pub error: String,
}

// ── Type conversions ────────────────────────────────────────────

impl From<polar_engine::state::ScannedDevice> for PolarScannedDevice {
    fn from(d: polar_engine::state::ScannedDevice) -> Self {
        Self {
            name: d.name,
            identifier: d.identifier,
            rssi: d.rssi,
        }
    }
}

impl From<polar_engine::state::ConnectionSnapshot> for PolarConnectionState {
    fn from(s: polar_engine::state::ConnectionSnapshot) -> Self {
        Self {
            status: s.status.as_str().to_string(),
            device_name: s.device_name,
            device_id: s.device_id,
            battery_percent: s.battery_percent,
            model: s.model,
            firmware: s.firmware,
            serial: s.serial,
            disk_total_kb: s.disk_total_kb,
            disk_free_kb: s.disk_free_kb,
            devices: s.devices.into_iter().map(PolarScannedDevice::from).collect(),
            error: s.error,
        }
    }
}

impl From<polar_engine::state::StreamSnapshot> for PolarStreamState {
    fn from(s: polar_engine::state::StreamSnapshot) -> Self {
        Self {
            is_streaming: s.is_streaming,
            config: s.config,
            hr_bpm: s.hr_bpm,
            sample_count: s.sample_count,
            elapsed_s: s.elapsed_s,
            chart_acc_timestamps: s.chart_acc.timestamps_s,
            chart_acc_x: s.chart_acc.x,
            chart_acc_y: s.chart_acc.y,
            chart_acc_z: s.chart_acc.z,
            chart_gyro_timestamps: s.chart_gyro.timestamps_s,
            chart_gyro_x: s.chart_gyro.x,
            chart_gyro_y: s.chart_gyro.y,
            chart_gyro_z: s.chart_gyro.z,
        }
    }
}

impl From<polar_engine::state::RecordingSnapshot> for PolarRecordingState {
    fn from(s: polar_engine::state::RecordingSnapshot) -> Self {
        Self {
            is_recording: s.is_recording,
            active_types: s.active_types,
            status_text: s.status_text,
            error: s.error,
        }
    }
}

impl From<polar_engine::state::FileEntry> for PolarFileEntry {
    fn from(e: polar_engine::state::FileEntry) -> Self {
        Self {
            path: e.path,
            data_type: e.data_type,
            date: e.date,
            size_bytes: e.size_bytes,
        }
    }
}

impl From<polar_engine::state::DownloadedCsv> for PolarDownloadedCsv {
    fn from(d: polar_engine::state::DownloadedCsv) -> Self {
        Self {
            filename: d.filename,
            data_type: d.data_type,
            sample_count: d.sample_count,
            csv_content: d.csv_content,
        }
    }
}

impl From<polar_engine::state::FilesSnapshot> for PolarFilesState {
    fn from(s: polar_engine::state::FilesSnapshot) -> Self {
        Self {
            is_syncing: s.is_syncing,
            entries: s.entries.into_iter().map(PolarFileEntry::from).collect(),
            progress_text: s.progress_text,
            downloaded_csvs: s.downloaded_csvs.into_iter().map(PolarDownloadedCsv::from).collect(),
            error: s.error,
        }
    }
}

// ── Connection API ──────────────────────────────────────────────

#[flutter_rust_bridge::frb(sync)]
pub fn polar_start_scan() {
    with_session(|s| s.start_scan());
}

#[flutter_rust_bridge::frb(sync)]
pub fn polar_connect(identifier: String) {
    with_session(|s| s.connect(&identifier));
}

#[flutter_rust_bridge::frb(sync)]
pub fn polar_disconnect() {
    with_session(|s| s.disconnect());
}

#[flutter_rust_bridge::frb(sync)]
pub fn polar_poll_connection() -> PolarConnectionState {
    with_session(|s| {
        s.process_events();
        s.connection_snapshot().into()
    })
}

// ── Streaming API ───────────────────────────────────────────────

#[flutter_rust_bridge::frb(sync)]
pub fn polar_start_stream(config: String) {
    with_session(|s| s.start_stream(&config));
}

#[flutter_rust_bridge::frb(sync)]
pub fn polar_stop_stream() {
    with_session(|s| s.stop_stream());
}

#[flutter_rust_bridge::frb(sync)]
pub fn polar_poll_stream() -> PolarStreamState {
    with_session(|s| {
        s.process_events();
        s.stream_snapshot().into()
    })
}

// ── Recording API ───────────────────────────────────────────────

#[flutter_rust_bridge::frb(sync)]
pub fn polar_start_recording(types: Vec<String>) {
    with_session(|s| s.start_recording(&types));
}

#[flutter_rust_bridge::frb(sync)]
pub fn polar_stop_recording(types: Vec<String>) {
    with_session(|s| s.stop_recording(&types));
}

#[flutter_rust_bridge::frb(sync)]
pub fn polar_check_recording_status() {
    with_session(|s| s.check_recording_status());
}

#[flutter_rust_bridge::frb(sync)]
pub fn polar_poll_recording() -> PolarRecordingState {
    with_session(|s| {
        s.process_events();
        s.recording_snapshot().into()
    })
}

// ── Files API ───────────────────────────────────────────────────

#[flutter_rust_bridge::frb(sync)]
pub fn polar_list_files() {
    with_session(|s| s.list_files());
}

#[flutter_rust_bridge::frb(sync)]
pub fn polar_sync_files() {
    with_session(|s| s.sync_files());
}

#[flutter_rust_bridge::frb(sync)]
pub fn polar_poll_files() -> PolarFilesState {
    with_session(|s| {
        s.process_events();
        s.files_snapshot().into()
    })
}

// ── Trigger API ─────────────────────────────────────────────────

#[flutter_rust_bridge::frb(sync)]
pub fn polar_set_trigger(mode: String) {
    with_session(|s| s.set_trigger(&mode));
}

#[flutter_rust_bridge::frb(sync)]
pub fn polar_get_trigger() {
    with_session(|s| s.get_trigger());
}
