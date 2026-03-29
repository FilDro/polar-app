/// Readiness traffic-light classification.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Readiness {
    Green,
    Amber,
    Red,
}

/// Short-term HRV variability classification.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Stability {
    Stable,
    Variable,
}

/// How mature the baseline is.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum BaselinePhase {
    /// Not enough data yet, show raw values only.
    Building(u32),
    /// 7-13 days: preliminary traffic light with caveat.
    Preliminary,
    /// 14+ days: full confident scoring.
    Confident,
}

/// Summary of the athlete's HRV baseline.
#[derive(Debug, Clone)]
pub struct Baseline {
    pub mean: f64,
    pub sd: f64,
    pub cv_7day: f64,
    pub day_count: u32,
}

/// Full readiness assessment result.
#[derive(Debug, Clone)]
pub struct ReadinessResult {
    pub readiness: Readiness,
    pub stability: Stability,
    pub phase: BaselinePhase,
    pub baseline: Baseline,
}

/// Compute rolling baseline from historical lnRMSSD values.
///
/// Input: up to 60 most recent daily lnRMSSD values (excluding today).
/// Returns mean, SD (population), and cv_7day computed from the last 7 values.
pub fn compute_baseline(history: &[f64]) -> Baseline {
    let day_count = history.len() as u32;

    if history.is_empty() {
        return Baseline {
            mean: 0.0,
            sd: 0.0,
            cv_7day: 0.0,
            day_count: 0,
        };
    }

    let n = history.len() as f64;
    let mean = history.iter().sum::<f64>() / n;

    let variance = history.iter().map(|v| (v - mean).powi(2)).sum::<f64>() / n;
    let sd = variance.sqrt();

    // cv_7day from the most recent 7 values (or fewer if not enough history)
    let last_7: &[f64] = if history.len() >= 7 {
        &history[history.len() - 7..]
    } else {
        history
    };
    let cv_7day = compute_cv_7day(last_7);

    Baseline {
        mean,
        sd,
        cv_7day,
        day_count,
    }
}

/// Compute coefficient of variation for the last 7 days.
///
/// CV = SD / mean (population SD).
/// Returns 0.0 if the input is empty or the mean is zero.
pub fn compute_cv_7day(last_7: &[f64]) -> f64 {
    if last_7.is_empty() {
        return 0.0;
    }

    let n = last_7.len() as f64;
    let mean = last_7.iter().sum::<f64>() / n;

    if mean.abs() < f64::EPSILON {
        return 0.0;
    }

    let variance = last_7.iter().map(|v| (v - mean).powi(2)).sum::<f64>() / n;
    let sd = variance.sqrt();

    sd / mean
}

/// Determine baseline phase from day count.
///
/// - Days 1-6: `Building(day_count)`
/// - Days 7-13: `Preliminary`
/// - Day 14+: `Confident`
/// - Day 0: `Building(0)` (no data)
pub fn baseline_phase(day_count: u32) -> BaselinePhase {
    match day_count {
        0..=6 => BaselinePhase::Building(day_count),
        7..=13 => BaselinePhase::Preliminary,
        _ => BaselinePhase::Confident,
    }
}

/// Compute the 7-day rolling mean: up to 6 most recent history values plus today.
///
/// history is ordered oldest-first (same format as compute_baseline input).
/// If history has fewer than 6 entries, all available entries are included.
/// The result is used as the input to score_readiness so that the traffic light
/// reflects the recent trend rather than reacting to a single-day spike.
pub fn compute_7day_mean(today: f64, history: &[f64]) -> f64 {
    // Take the 6 most recent entries from history (newest-last order after rev+take).
    let tail: Vec<f64> = history.iter().rev().take(6).cloned().collect();
    // tail is newest-first; reverse to restore chronological order, then append today.
    let mut window: Vec<f64> = tail.into_iter().rev().collect();
    window.push(today);
    window.iter().sum::<f64>() / window.len() as f64
}

/// Score readiness from today's lnRMSSD against baseline.
///
/// Scoring rules:
///   GREEN  — `ln_rmssd >= baseline.mean - 0.5 * baseline.sd`
///   AMBER  — `ln_rmssd >= baseline.mean - 1.5 * baseline.sd`
///   RED    — `ln_rmssd <  baseline.mean - 1.5 * baseline.sd`
///
/// Stability:
///   STABLE   — `cv_7day < 0.10`
///   VARIABLE — `cv_7day >= 0.10`
///
/// If phase is Building, readiness is still computed but the caller
/// should know not to show a traffic light.
pub fn score_readiness(ln_rmssd: f64, baseline: &Baseline) -> ReadinessResult {
    let green_threshold = baseline.mean - 0.5 * baseline.sd;
    let amber_threshold = baseline.mean - 1.5 * baseline.sd;

    let readiness = if ln_rmssd >= green_threshold {
        Readiness::Green
    } else if ln_rmssd >= amber_threshold {
        Readiness::Amber
    } else {
        Readiness::Red
    };

    let stability = if baseline.cv_7day < 0.10 {
        Stability::Stable
    } else {
        Stability::Variable
    };

    let phase = baseline_phase(baseline.day_count);

    ReadinessResult {
        readiness,
        stability,
        phase,
        baseline: baseline.clone(),
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use approx::assert_relative_eq;

    #[test]
    fn test_compute_baseline_known_values() {
        // Values: [3.0, 4.0, 5.0, 6.0, 7.0]
        // Mean = 5.0
        // Variance = ((4+1+0+1+4)/5) = 2.0
        // SD = sqrt(2.0) ~ 1.4142
        let history = vec![3.0, 4.0, 5.0, 6.0, 7.0];
        let baseline = compute_baseline(&history);

        assert_relative_eq!(baseline.mean, 5.0, epsilon = 1e-9);
        assert_relative_eq!(baseline.sd, 2.0_f64.sqrt(), epsilon = 1e-9);
        assert_eq!(baseline.day_count, 5);
    }

    #[test]
    fn test_compute_baseline_uniform() {
        // All same value => SD = 0
        let history = vec![4.0; 14];
        let baseline = compute_baseline(&history);

        assert_relative_eq!(baseline.mean, 4.0, epsilon = 1e-9);
        assert_relative_eq!(baseline.sd, 0.0, epsilon = 1e-9);
        assert_eq!(baseline.day_count, 14);
    }

    #[test]
    fn test_compute_cv_7day_zero() {
        // All identical => SD=0 => CV=0
        let cv = compute_cv_7day(&[10.0; 7]);
        assert_relative_eq!(cv, 0.0, epsilon = 1e-9);
    }

    #[test]
    fn test_compute_cv_7day_nonzero() {
        let vals = [4.0, 4.0, 4.0, 4.0, 4.0, 4.0, 6.0];
        let cv = compute_cv_7day(&vals);
        // Manually: mean = 30/7, deviations squared summed / 7, sqrt, / mean
        let mean = 30.0 / 7.0;
        let var = vals.iter().map(|v| (v - mean).powi(2)).sum::<f64>() / 7.0;
        let expected_cv = var.sqrt() / mean;
        assert_relative_eq!(cv, expected_cv, epsilon = 1e-9);
        assert!(cv > 0.10); // Should classify as Variable
    }

    #[test]
    fn test_compute_cv_7day_empty() {
        assert_relative_eq!(compute_cv_7day(&[]), 0.0, epsilon = 1e-9);
    }

    #[test]
    fn test_baseline_phase_building() {
        assert_eq!(baseline_phase(0), BaselinePhase::Building(0));
        assert_eq!(baseline_phase(1), BaselinePhase::Building(1));
        assert_eq!(baseline_phase(6), BaselinePhase::Building(6));
    }

    #[test]
    fn test_baseline_phase_preliminary() {
        assert_eq!(baseline_phase(7), BaselinePhase::Preliminary);
        assert_eq!(baseline_phase(13), BaselinePhase::Preliminary);
    }

    #[test]
    fn test_baseline_phase_confident() {
        assert_eq!(baseline_phase(14), BaselinePhase::Confident);
        assert_eq!(baseline_phase(60), BaselinePhase::Confident);
    }

    #[test]
    fn test_score_green_well_above() {
        // Baseline mean=4.0, sd=0.5
        // Green threshold = 4.0 - 0.25 = 3.75
        // Today = 4.2 => Green
        let baseline = Baseline {
            mean: 4.0,
            sd: 0.5,
            cv_7day: 0.05,
            day_count: 14,
        };
        let result = score_readiness(4.2, &baseline);
        assert_eq!(result.readiness, Readiness::Green);
        assert_eq!(result.phase, BaselinePhase::Confident);
    }

    #[test]
    fn test_score_green_at_boundary() {
        // Exactly at green threshold => Green (>=)
        let baseline = Baseline {
            mean: 4.0,
            sd: 0.5,
            cv_7day: 0.05,
            day_count: 14,
        };
        let threshold = 4.0 - 0.5 * 0.5; // 3.75
        let result = score_readiness(threshold, &baseline);
        assert_eq!(result.readiness, Readiness::Green);
    }

    #[test]
    fn test_score_amber_between_thresholds() {
        // Baseline mean=4.0, sd=0.5
        // Green threshold = 3.75
        // Amber threshold = 4.0 - 0.75 = 3.25
        // Value = 3.5 => Amber
        let baseline = Baseline {
            mean: 4.0,
            sd: 0.5,
            cv_7day: 0.05,
            day_count: 14,
        };
        let result = score_readiness(3.5, &baseline);
        assert_eq!(result.readiness, Readiness::Amber);
    }

    #[test]
    fn test_score_amber_at_boundary() {
        // Exactly at amber threshold => Amber (>=)
        let baseline = Baseline {
            mean: 4.0,
            sd: 0.5,
            cv_7day: 0.05,
            day_count: 14,
        };
        let threshold = 4.0 - 1.5 * 0.5; // 3.25
        let result = score_readiness(threshold, &baseline);
        assert_eq!(result.readiness, Readiness::Amber);
    }

    #[test]
    fn test_score_red_below_amber() {
        // Baseline mean=4.0, sd=0.5
        // Amber threshold = 3.25
        // Value = 3.0 => Red
        let baseline = Baseline {
            mean: 4.0,
            sd: 0.5,
            cv_7day: 0.05,
            day_count: 14,
        };
        let result = score_readiness(3.0, &baseline);
        assert_eq!(result.readiness, Readiness::Red);
    }

    #[test]
    fn test_stability_stable() {
        let baseline = Baseline {
            mean: 4.0,
            sd: 0.5,
            cv_7day: 0.05,
            day_count: 14,
        };
        let result = score_readiness(4.0, &baseline);
        assert_eq!(result.stability, Stability::Stable);
    }

    #[test]
    fn test_stability_variable() {
        let baseline = Baseline {
            mean: 4.0,
            sd: 0.5,
            cv_7day: 0.15,
            day_count: 14,
        };
        let result = score_readiness(4.0, &baseline);
        assert_eq!(result.stability, Stability::Variable);
    }

    #[test]
    fn test_stability_boundary_is_variable() {
        // cv_7day = 0.10 exactly => Variable (>= 0.10)
        let baseline = Baseline {
            mean: 4.0,
            sd: 0.5,
            cv_7day: 0.10,
            day_count: 14,
        };
        let result = score_readiness(4.0, &baseline);
        assert_eq!(result.stability, Stability::Variable);
    }

    #[test]
    fn test_single_day_history() {
        let history = vec![3.8];
        let baseline = compute_baseline(&history);

        assert_relative_eq!(baseline.mean, 3.8, epsilon = 1e-9);
        assert_relative_eq!(baseline.sd, 0.0, epsilon = 1e-9);
        assert_eq!(baseline.day_count, 1);

        let result = score_readiness(3.8, &baseline);
        assert_eq!(result.phase, BaselinePhase::Building(1));
        // SD=0 => green threshold = mean itself, exact match => Green
        assert_eq!(result.readiness, Readiness::Green);
    }

    #[test]
    fn test_empty_history() {
        let baseline = compute_baseline(&[]);

        assert_relative_eq!(baseline.mean, 0.0, epsilon = 1e-9);
        assert_relative_eq!(baseline.sd, 0.0, epsilon = 1e-9);
        assert_eq!(baseline.day_count, 0);

        let result = score_readiness(3.5, &baseline);
        assert_eq!(result.phase, BaselinePhase::Building(0));
        // mean=0, sd=0 => thresholds=0, 3.5 >= 0 => Green
        assert_eq!(result.readiness, Readiness::Green);
    }

    #[test]
    fn test_phase_propagated_in_result() {
        let baseline = Baseline {
            mean: 4.0,
            sd: 0.5,
            cv_7day: 0.05,
            day_count: 10,
        };
        let result = score_readiness(4.0, &baseline);
        assert_eq!(result.phase, BaselinePhase::Preliminary);
    }

    // ── compute_7day_mean ──────────────────────────────────────────

    #[test]
    fn test_7day_mean_no_history() {
        // No prior history => mean is just today's value.
        let mean = compute_7day_mean(4.0, &[]);
        assert_relative_eq!(mean, 4.0, epsilon = 1e-9);
    }

    #[test]
    fn test_7day_mean_short_history() {
        // 2 prior values + today = 3-element window.
        // mean([3.0, 4.0, 5.0]) = 4.0
        let mean = compute_7day_mean(5.0, &[3.0, 4.0]);
        assert_relative_eq!(mean, 4.0, epsilon = 1e-9);
    }

    #[test]
    fn test_7day_mean_full_history() {
        // Exactly 6 prior values + today = 7-element window.
        let history = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0];
        let mean = compute_7day_mean(7.0, &history);
        // (1+2+3+4+5+6+7)/7 = 28/7 = 4.0
        assert_relative_eq!(mean, 4.0, epsilon = 1e-9);
    }

    #[test]
    fn test_7day_mean_uses_only_last_6() {
        // 10 prior values; only the most recent 6 should be used.
        // history = [1,2,3,4,5,6,7,8,9,10], last 6 = [5,6,7,8,9,10], today = 11
        // mean([5,6,7,8,9,10,11]) = 56/7 = 8.0
        let history: Vec<f64> = (1..=10).map(|x| x as f64).collect();
        let mean = compute_7day_mean(11.0, &history);
        assert_relative_eq!(mean, 8.0, epsilon = 1e-9);
    }

    #[test]
    fn test_7day_mean_smooths_spike() {
        // Stable history at 4.0, today spikes to 2.0.
        // Raw today = 2.0 would fire RED (below mean - 1.5*sd if sd is small).
        // 7-day mean = (4+4+4+4+4+4+2)/7 ≈ 3.71, which is a smaller drop.
        let history = [4.0_f64; 6];
        let mean = compute_7day_mean(2.0, &history);
        let expected = (6.0 * 4.0 + 2.0) / 7.0;
        assert_relative_eq!(mean, expected, epsilon = 1e-9);
        // Confirm it's between today's spike and the stable baseline
        assert!(mean > 2.0);
        assert!(mean < 4.0);
    }
}
