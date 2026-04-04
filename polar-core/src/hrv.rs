/// Input PPI sample — mirrors polar-rs PpiSample fields.
#[derive(Debug, Clone)]
pub struct PpiInput {
    pub hr: u8,
    pub ppi_ms: u16,
    pub error_estimate: u16,
    pub flags: u8,
}

/// Result of HRV computation.
#[derive(Debug, Clone)]
pub struct HrvResult {
    pub rmssd_ms: f64,
    pub ln_rmssd: f64,
    pub rr_mean_ms: f64,
    pub rr_count: usize,
    pub resting_hr_bpm: f64,
    /// Number of samples discarded due to the blocker flag (flags & 0x01).
    pub rejected_count: usize,
}

/// Errors during HRV computation.
#[derive(Debug, Clone)]
pub enum HrvError {
    NotEnoughSamples { got: usize, need: usize },
    NoValidIntervals,
}

impl std::fmt::Display for HrvError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            HrvError::NotEnoughSamples { got, need } => {
                write!(f, "not enough samples: got {got}, need {need}")
            }
            HrvError::NoValidIntervals => write!(f, "no valid RR intervals after warmup"),
        }
    }
}

impl std::error::Error for HrvError {}

const MIN_SAMPLES: usize = 20;

/// Compute HRV metrics from PPI samples.
///
/// Discards warmup samples from the first `warmup_s` seconds (tracked by summing ppi_ms).
/// Requires >= 30 valid samples after warmup.
///
/// Computation:
///   1. Sum ppi_ms to track elapsed time, discard samples where elapsed < warmup_s * 1000
///   2. From remaining samples, extract ppi_ms values as RR intervals
///   3. RMSSD = sqrt(mean(successive_differences²))
///   4. lnRMSSD = ln(RMSSD)
///   5. resting_hr = 60000.0 / mean(RR_intervals)
pub fn compute_hrv(samples: &[PpiInput], warmup_s: f64) -> Result<HrvResult, HrvError> {
    let warmup_ms = warmup_s * 1000.0;

    // Phase 1: skip warmup by accumulating elapsed time; reject blocker-flagged samples.
    // Bit 0 of flags (flags & 0x01) is the blocker flag: set when motion was detected
    // during acquisition. See Polar BLE SDK PPIData.md and PpiDataTest.kt.
    // Elapsed time accumulates even for rejected samples — we track real time, not
    // valid-beat time — so the warmup window is computed correctly.
    let mut elapsed_ms: f64 = 0.0;
    let mut rr_intervals: Vec<f64> = Vec::new();
    let mut rejected_count: usize = 0;

    for sample in samples {
        elapsed_ms += sample.ppi_ms as f64;
        if elapsed_ms < warmup_ms {
            continue;
        }
        if sample.flags & 0x01 != 0 {
            rejected_count += 1;
            continue;
        }
        rr_intervals.push(sample.ppi_ms as f64);
    }

    if rr_intervals.is_empty() {
        return Err(HrvError::NoValidIntervals);
    }

    if rr_intervals.len() < MIN_SAMPLES {
        return Err(HrvError::NotEnoughSamples {
            got: rr_intervals.len(),
            need: MIN_SAMPLES,
        });
    }

    // Phase 2: successive differences
    let successive_diffs: Vec<f64> = rr_intervals.windows(2).map(|w| w[1] - w[0]).collect();

    if successive_diffs.is_empty() {
        return Err(HrvError::NoValidIntervals);
    }

    // Phase 3: RMSSD
    let sum_sq: f64 = successive_diffs.iter().map(|d| d * d).sum();
    let rmssd_ms = (sum_sq / successive_diffs.len() as f64).sqrt();

    // Phase 4: lnRMSSD
    let ln_rmssd = rmssd_ms.ln();

    // Phase 5: resting HR
    let rr_mean_ms: f64 = rr_intervals.iter().sum::<f64>() / rr_intervals.len() as f64;
    let resting_hr_bpm = 60_000.0 / rr_mean_ms;

    Ok(HrvResult {
        rmssd_ms,
        ln_rmssd,
        rr_mean_ms,
        rr_count: rr_intervals.len(),
        resting_hr_bpm,
        rejected_count,
    })
}

#[cfg(test)]
mod tests {
    use super::*;
    use approx::assert_relative_eq;

    /// Helper: create a PpiInput with clean flags (no blocker).
    fn ppi(ms: u16) -> PpiInput {
        PpiInput {
            hr: 60,
            ppi_ms: ms,
            error_estimate: 5,
            flags: 0,
        }
    }

    /// Helper: create a PpiInput with the blocker flag set (flags & 0x01).
    fn ppi_blocked(ms: u16) -> PpiInput {
        PpiInput {
            hr: 60,
            ppi_ms: ms,
            error_estimate: 50,
            flags: 0x01,
        }
    }

    #[test]
    fn test_known_rmssd_zero() {
        // 35 samples, all 1000ms => all successive diffs = 0 => RMSSD = 0
        let samples: Vec<PpiInput> = vec![ppi(1000); 35];
        let result = compute_hrv(&samples, 0.0).unwrap();
        assert_relative_eq!(result.rmssd_ms, 0.0, epsilon = 1e-9);
        assert_relative_eq!(result.rr_mean_ms, 1000.0, epsilon = 1e-9);
        assert_eq!(result.rr_count, 35);
    }

    #[test]
    fn test_known_rmssd_nonzero() {
        // Alternating 1000ms and 1020ms for 40 samples (no warmup).
        // Successive diffs alternate between +20 and -20, so diff² = 400 always.
        // RMSSD = sqrt(mean(400)) = sqrt(400) = 20.0
        let mut samples = Vec::new();
        for i in 0..40 {
            if i % 2 == 0 {
                samples.push(ppi(1000));
            } else {
                samples.push(ppi(1020));
            }
        }
        let result = compute_hrv(&samples, 0.0).unwrap();
        assert_relative_eq!(result.rmssd_ms, 20.0, epsilon = 1e-9);
        assert_relative_eq!(result.ln_rmssd, 20.0_f64.ln(), epsilon = 1e-9);
    }

    #[test]
    fn test_warmup_discard() {
        // 5 warmup samples at 1000ms each = 5000ms = 5s
        // Then 35 "real" samples at 800ms each.
        // warmup_s = 5.0 => discard while elapsed < 5000.
        //
        // Sample 1: elapsed=1000 <5000 => skip
        // Sample 2: elapsed=2000 <5000 => skip
        // Sample 3: elapsed=3000 <5000 => skip
        // Sample 4: elapsed=4000 <5000 => skip
        // Sample 5: elapsed=5000, NOT <5000 => keep (1000ms value)
        // Samples 6-40: all kept (800ms values)
        //
        // So we get 1 sample at 1000ms + 35 samples at 800ms = 36 total.
        let mut samples = Vec::new();
        for _ in 0..5 {
            samples.push(ppi(1000));
        }
        for _ in 0..35 {
            samples.push(ppi(800));
        }

        let result = compute_hrv(&samples, 5.0).unwrap();
        assert_eq!(result.rr_count, 36);
        // First kept interval is 1000, rest are 800.
        // Only the first successive diff is 800-1000 = -200, rest are 0.
        // sum_sq = (-200)^2 = 40000
        // RMSSD = sqrt(40000 / 35) = sqrt(1142.857...) ≈ 33.806
        let expected_rmssd = (40000.0_f64 / 35.0).sqrt();
        assert_relative_eq!(result.rmssd_ms, expected_rmssd, epsilon = 1e-6);
    }

    #[test]
    fn test_warmup_discard_all_same_after() {
        // 25 samples at 1000ms = 25s warmup, then 35 at 800ms
        // warmup_s = 26.0 => need elapsed >= 26000
        // After 25 samples at 1000: elapsed=25000 < 26000 => all skipped
        // Sample 26 (800ms): elapsed=25800 < 26000 => skip
        // Sample 27 (800ms): elapsed=26600 >= 26000 => keep
        // So we get 34 kept samples, all 800ms.
        let mut samples = Vec::new();
        for _ in 0..25 {
            samples.push(ppi(1000));
        }
        for _ in 0..35 {
            samples.push(ppi(800));
        }

        let result = compute_hrv(&samples, 26.0).unwrap();
        assert_eq!(result.rr_count, 34);
        assert_relative_eq!(result.rmssd_ms, 0.0, epsilon = 1e-9);
        assert_relative_eq!(result.rr_mean_ms, 800.0, epsilon = 1e-9);
    }

    #[test]
    fn test_not_enough_samples() {
        let samples: Vec<PpiInput> = vec![ppi(1000); 15];
        let result = compute_hrv(&samples, 0.0);
        match result {
            Err(HrvError::NotEnoughSamples { got: 15, need: 20 }) => {}
            other => panic!("expected NotEnoughSamples, got {:?}", other),
        }
    }

    #[test]
    fn test_empty_input() {
        let result = compute_hrv(&[], 0.0);
        assert!(matches!(result, Err(HrvError::NoValidIntervals)));
    }

    #[test]
    fn test_all_warmup_no_remaining() {
        // All samples fall within warmup period
        let samples: Vec<PpiInput> = vec![ppi(100); 5]; // 500ms total, warmup 10s
        let result = compute_hrv(&samples, 10.0);
        assert!(matches!(result, Err(HrvError::NoValidIntervals)));
    }

    #[test]
    fn test_ln_rmssd_known_value() {
        // Alternating 980 and 1020 for 40 samples => diff = ±40, RMSSD = 40
        let mut samples = Vec::new();
        for i in 0..40 {
            if i % 2 == 0 {
                samples.push(ppi(980));
            } else {
                samples.push(ppi(1020));
            }
        }
        let result = compute_hrv(&samples, 0.0).unwrap();
        assert_relative_eq!(result.rmssd_ms, 40.0, epsilon = 1e-9);
        assert_relative_eq!(result.ln_rmssd, 40.0_f64.ln(), epsilon = 1e-9);
    }

    #[test]
    fn test_resting_hr_60bpm() {
        // Mean RR = 1000ms => HR = 60000/1000 = 60 bpm
        let samples: Vec<PpiInput> = vec![ppi(1000); 35];
        let result = compute_hrv(&samples, 0.0).unwrap();
        assert_relative_eq!(result.resting_hr_bpm, 60.0, epsilon = 1e-9);
    }

    #[test]
    fn test_resting_hr_75bpm() {
        // Mean RR = 800ms => HR = 60000/800 = 75 bpm
        let samples: Vec<PpiInput> = vec![ppi(800); 35];
        let result = compute_hrv(&samples, 0.0).unwrap();
        assert_relative_eq!(result.resting_hr_bpm, 75.0, epsilon = 1e-9);
    }

    #[test]
    fn test_blocker_flag_rejected() {
        // 35 clean samples + 10 blocked samples.
        // Blocked samples must not contribute to RMSSD or rr_count.
        let mut samples: Vec<PpiInput> = vec![ppi(1000); 35];
        samples.extend(vec![ppi_blocked(500); 10]);
        let result = compute_hrv(&samples, 0.0).unwrap();
        assert_eq!(result.rr_count, 35);
        assert_eq!(result.rejected_count, 10);
        // All clean samples are 1000ms => all successive diffs = 0 => RMSSD = 0
        assert_relative_eq!(result.rmssd_ms, 0.0, epsilon = 1e-9);
        assert_relative_eq!(result.rr_mean_ms, 1000.0, epsilon = 1e-9);
    }

    #[test]
    fn test_clean_flag_accepted() {
        // flags=0x00 (no blocker) => accepted as normal
        let samples: Vec<PpiInput> = vec![ppi(1000); 35];
        let result = compute_hrv(&samples, 0.0).unwrap();
        assert_eq!(result.rejected_count, 0);
        assert_eq!(result.rr_count, 35);
    }

    #[test]
    fn test_mixed_flags_rmssd_from_clean_only() {
        // 35 clean samples at 1000ms interspersed with 10 blocked at 800ms.
        // Only the 35 clean samples are kept => RMSSD=0, rr_mean=1000ms.
        let mut samples: Vec<PpiInput> = Vec::new();
        for i in 0..35 {
            samples.push(ppi(1000));
            if i < 10 {
                samples.push(ppi_blocked(800));
            }
        }
        let result = compute_hrv(&samples, 0.0).unwrap();
        assert_eq!(result.rr_count, 35);
        assert_eq!(result.rejected_count, 10);
        assert_relative_eq!(result.rmssd_ms, 0.0, epsilon = 1e-9);
        assert_relative_eq!(result.rr_mean_ms, 1000.0, epsilon = 1e-9);
    }

    #[test]
    fn test_all_blocked_returns_no_valid_intervals() {
        // 40 samples all with blocker set => rr_intervals is empty => NoValidIntervals.
        // (The NotEnoughSamples path is only reached when at least 1 clean sample exists
        // but the count is below MIN_SAMPLES.)
        let samples: Vec<PpiInput> = vec![ppi_blocked(1000); 40];
        let result = compute_hrv(&samples, 0.0);
        assert!(matches!(result, Err(HrvError::NoValidIntervals)));
    }
}
