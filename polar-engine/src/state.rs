//! UI state snapshots returned by polling.

use std::collections::VecDeque;

/// Session summary after HR processing.
#[derive(Debug, Clone)]
pub struct SessionSummary {
    pub start_time: String,
    pub duration_s: f64,
    pub trimp_edwards: f64,
    pub hr_avg: f64,
    pub hr_max: u16,
    pub hr_min: u16,
    pub zone_seconds: Vec<f64>,   // 6 elements: [below_z1, z1, z2, z3, z4, z5]
    pub zone_percent: Vec<f64>,   // 6 elements
}

/// Raw HR data extracted from a downloaded recording, for later processing.
#[derive(Debug, Clone)]
pub struct HrRecordingData {
    pub start_time: String,
    /// (timestamp_s, hr_bpm) pairs — timestamp relative to recording start.
    pub samples: Vec<(f64, u16)>,
}

/// Connection state snapshot.
#[derive(Debug, Clone)]
pub struct ConnectionSnapshot {
    pub status: ConnectionStatus,
    pub device_name: String,
    pub device_id: String,
    pub battery_percent: i32,
    pub model: String,
    pub firmware: String,
    pub serial: String,
    pub disk_total_kb: i64,
    pub disk_free_kb: i64,
    pub devices: Vec<ScannedDevice>,
    pub error: String,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum ConnectionStatus {
    Disconnected,
    Scanning,
    Connecting,
    Connected,
}

impl ConnectionStatus {
    pub fn as_str(&self) -> &'static str {
        match self {
            Self::Disconnected => "disconnected",
            Self::Scanning => "scanning",
            Self::Connecting => "connecting",
            Self::Connected => "connected",
        }
    }
}

#[derive(Debug, Clone)]
pub struct ScannedDevice {
    pub name: String,
    pub identifier: String,
    pub rssi: i32,
}

/// Streaming state snapshot.
#[derive(Debug, Clone)]
pub struct StreamSnapshot {
    pub is_streaming: bool,
    pub config: String,
    pub hr_bpm: i32,
    pub sample_count: u64,
    pub elapsed_s: f64,
    /// Recent ACC samples for charting (x,y,z triples flattened).
    pub chart_acc: ChartData,
    /// Recent GYRO samples for charting.
    pub chart_gyro: ChartData,
}

#[derive(Debug, Clone, Default)]
pub struct ChartData {
    pub timestamps_s: Vec<f64>,
    pub x: Vec<f32>,
    pub y: Vec<f32>,
    pub z: Vec<f32>,
}

/// Recording state snapshot.
#[derive(Debug, Clone)]
pub struct RecordingSnapshot {
    pub is_recording: bool,
    pub active_types: Vec<String>,
    pub status_text: String,
    pub error: String,
}

/// Files state snapshot.
#[derive(Debug, Clone)]
pub struct FilesSnapshot {
    pub is_syncing: bool,
    pub entries: Vec<FileEntry>,
    pub progress_text: String,
    pub downloaded_csvs: Vec<DownloadedCsv>,
    pub error: String,
    /// Raw HR data extracted during file sync, ready for processing.
    pub hr_data: Option<HrRecordingData>,
    /// Session summary after HR processing.
    pub session_summary: Option<SessionSummary>,
}

#[derive(Debug, Clone)]
pub struct FileEntry {
    pub path: String,
    pub data_type: String,
    pub date: String,
    pub size_bytes: u64,
}

#[derive(Debug, Clone)]
pub struct DownloadedCsv {
    pub filename: String,
    pub data_type: String,
    pub sample_count: u64,
    pub csv_content: String,
}

impl Default for ConnectionSnapshot {
    fn default() -> Self {
        Self {
            status: ConnectionStatus::Disconnected,
            device_name: String::new(),
            device_id: String::new(),
            battery_percent: -1,
            model: String::new(),
            firmware: String::new(),
            serial: String::new(),
            disk_total_kb: -1,
            disk_free_kb: -1,
            devices: Vec::new(),
            error: String::new(),
        }
    }
}

impl Default for StreamSnapshot {
    fn default() -> Self {
        Self {
            is_streaming: false,
            config: String::new(),
            hr_bpm: -1,
            sample_count: 0,
            elapsed_s: 0.0,
            chart_acc: ChartData::default(),
            chart_gyro: ChartData::default(),
        }
    }
}

impl Default for RecordingSnapshot {
    fn default() -> Self {
        Self {
            is_recording: false,
            active_types: Vec::new(),
            status_text: String::new(),
            error: String::new(),
        }
    }
}

impl Default for FilesSnapshot {
    fn default() -> Self {
        Self {
            is_syncing: false,
            entries: Vec::new(),
            progress_text: String::new(),
            downloaded_csvs: Vec::new(),
            error: String::new(),
            hr_data: None,
            session_summary: None,
        }
    }
}

// ── Morning check types ────────────────────────────────────────

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum MorningCheckPhase {
    Idle,
    Warmup,
    Recording,
    Computing,
    Done,
    Error,
}

impl MorningCheckPhase {
    pub fn as_str(&self) -> &'static str {
        match self {
            Self::Idle => "idle",
            Self::Warmup => "warmup",
            Self::Recording => "recording",
            Self::Computing => "computing",
            Self::Done => "done",
            Self::Error => "error",
        }
    }
}

#[derive(Debug, Clone)]
pub struct MorningCheckSnapshot {
    pub phase: MorningCheckPhase,
    pub elapsed_s: f64,
    pub hr_bpm: u8,
    pub ppi_count: usize,
    pub result: Option<MorningResult>,
    pub error: String,
}

impl Default for MorningCheckSnapshot {
    fn default() -> Self {
        Self {
            phase: MorningCheckPhase::Idle,
            elapsed_s: 0.0,
            hr_bpm: 0,
            ppi_count: 0,
            result: None,
            error: String::new(),
        }
    }
}

#[derive(Debug, Clone)]
pub struct MorningResult {
    pub ln_rmssd: f64,
    /// 7-day rolling mean (last 6 history values + today). Used for the traffic light.
    pub ln_rmssd_7day: f64,
    pub rmssd_ms: f64,
    pub resting_hr_bpm: f64,
    pub rr_count: usize,
    /// Number of PPI samples discarded due to the blocker flag.
    pub rejected_count: usize,
    pub readiness: String,
    pub stability: String,
    pub baseline_mean: f64,
    pub baseline_sd: f64,
    pub cv_7day: f64,
    pub day_count: u32,
}

impl Default for MorningResult {
    fn default() -> Self {
        Self {
            ln_rmssd: 0.0,
            ln_rmssd_7day: 0.0,
            rmssd_ms: 0.0,
            resting_hr_bpm: 0.0,
            rr_count: 0,
            rejected_count: 0,
            readiness: String::new(),
            stability: String::new(),
            baseline_mean: 0.0,
            baseline_sd: 0.0,
            cv_7day: 0.0,
            day_count: 0,
        }
    }
}

/// Ring buffer for chart data, keeps last N seconds.
pub struct SampleRingBuffer {
    pub timestamps: VecDeque<f64>,
    pub x: VecDeque<f32>,
    pub y: VecDeque<f32>,
    pub z: VecDeque<f32>,
    max_samples: usize,
}

impl SampleRingBuffer {
    pub fn new(max_samples: usize) -> Self {
        Self {
            timestamps: VecDeque::with_capacity(max_samples),
            x: VecDeque::with_capacity(max_samples),
            y: VecDeque::with_capacity(max_samples),
            z: VecDeque::with_capacity(max_samples),
            max_samples,
        }
    }

    pub fn push(&mut self, t: f64, x: f32, y: f32, z: f32) {
        if self.timestamps.len() >= self.max_samples {
            self.timestamps.pop_front();
            self.x.pop_front();
            self.y.pop_front();
            self.z.pop_front();
        }
        self.timestamps.push_back(t);
        self.x.push_back(x);
        self.y.push_back(y);
        self.z.push_back(z);
    }

    pub fn to_chart_data(&self) -> ChartData {
        ChartData {
            timestamps_s: self.timestamps.iter().copied().collect(),
            x: self.x.iter().copied().collect(),
            y: self.y.iter().copied().collect(),
            z: self.z.iter().copied().collect(),
        }
    }

    pub fn clear(&mut self) {
        self.timestamps.clear();
        self.x.clear();
        self.y.clear();
        self.z.clear();
    }
}
