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
    pub session_summary: Option<PolarSessionSummary>,
}

#[flutter_rust_bridge::frb]
#[derive(Debug, Clone)]
pub struct PolarMorningCheckState {
    pub phase: String,
    pub elapsed_s: f64,
    pub hr_bpm: u8,
    pub ppi_count: u32,
    pub result: Option<PolarMorningResult>,
    pub error: String,
}

#[flutter_rust_bridge::frb]
#[derive(Debug, Clone)]
pub struct PolarMorningResult {
    pub ln_rmssd: f64,
    pub rmssd_ms: f64,
    pub resting_hr_bpm: f64,
    pub rr_count: u32,
    pub readiness: String,
    pub stability: String,
    pub baseline_mean: f64,
    pub baseline_sd: f64,
    pub cv_7day: f64,
    pub day_count: u32,
}

#[flutter_rust_bridge::frb]
#[derive(Debug, Clone)]
pub struct PolarSessionSummary {
    pub start_time: String,
    pub duration_s: f64,
    pub trimp_edwards: f64,
    pub hr_avg: f64,
    pub hr_max: u16,
    pub hr_min: u16,
    pub zone_seconds: Vec<f64>,
    pub zone_percent: Vec<f64>,
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
            session_summary: s.session_summary.map(PolarSessionSummary::from),
        }
    }
}

impl From<polar_engine::state::SessionSummary> for PolarSessionSummary {
    fn from(s: polar_engine::state::SessionSummary) -> Self {
        Self {
            start_time: s.start_time,
            duration_s: s.duration_s,
            trimp_edwards: s.trimp_edwards,
            hr_avg: s.hr_avg,
            hr_max: s.hr_max,
            hr_min: s.hr_min,
            zone_seconds: s.zone_seconds,
            zone_percent: s.zone_percent,
        }
    }
}

impl From<polar_engine::state::MorningResult> for PolarMorningResult {
    fn from(r: polar_engine::state::MorningResult) -> Self {
        Self {
            ln_rmssd: r.ln_rmssd,
            rmssd_ms: r.rmssd_ms,
            resting_hr_bpm: r.resting_hr_bpm,
            rr_count: r.rr_count as u32,
            readiness: r.readiness,
            stability: r.stability,
            baseline_mean: r.baseline_mean,
            baseline_sd: r.baseline_sd,
            cv_7day: r.cv_7day,
            day_count: r.day_count,
        }
    }
}

impl From<polar_engine::state::MorningCheckSnapshot> for PolarMorningCheckState {
    fn from(s: polar_engine::state::MorningCheckSnapshot) -> Self {
        Self {
            phase: s.phase.as_str().to_string(),
            elapsed_s: s.elapsed_s,
            hr_bpm: s.hr_bpm,
            ppi_count: s.ppi_count as u32,
            result: s.result.map(PolarMorningResult::from),
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

// ── Session Processing API ─────────────────────────────────────

/// Process the most recently downloaded HR recording into a session summary.
/// Call after polar_sync_files() completes and events have been polled.
/// Returns None if no HR data was downloaded.
#[flutter_rust_bridge::frb(sync)]
pub fn polar_process_session(hr_max: u16, hr_rest: u16) -> Option<PolarSessionSummary> {
    with_session(|s| {
        s.process_session(hr_max, hr_rest)
            .map(PolarSessionSummary::from)
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

// ── Morning Check API ──────────────────────────────────────────

#[flutter_rust_bridge::frb(sync)]
pub fn polar_start_morning_check() {
    with_session(|s| s.start_morning_check());
}

#[flutter_rust_bridge::frb(sync)]
pub fn polar_stop_morning_check() {
    with_session(|s| s.stop_morning_check());
}

#[flutter_rust_bridge::frb(sync)]
pub fn polar_poll_morning_check() -> PolarMorningCheckState {
    with_session(|s| {
        s.process_events();
        s.morning_check_snapshot().into()
    })
}

/// Compute morning result. Call after phase == "computing".
/// baseline_history: historical lnRMSSD values (up to 60 days, excluding today).
#[flutter_rust_bridge::frb(sync)]
pub fn polar_compute_morning_result(baseline_history: Vec<f64>) -> PolarMorningResult {
    with_session(|s| {
        let result = s.compute_morning_result(&baseline_history);
        PolarMorningResult::from(result)
    })
}
