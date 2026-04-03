use crate::zones::ZoneDistribution;

/// Session training load.
#[derive(Debug, Clone)]
pub struct SessionLoad {
    pub trimp_edwards: f64,
    pub duration_s: f64,
    pub zones: ZoneDistribution,
}

/// Longitudinal load metrics.
#[derive(Debug, Clone)]
pub struct LoadMetrics {
    /// Sum of TRIMP over last 7 days.
    pub acute_load: f64,
    /// Mean daily TRIMP over last 28 days * 7.
    pub chronic_load: f64,
    /// Acute:Chronic Workload Ratio (None if chronic_load is 0).
    pub acwr: Option<f64>,
    /// mean(daily TRIMP over 7 days) / sd(daily TRIMP over 7 days).
    pub monotony: f64,
    /// sum(daily TRIMP over 7 days) * monotony.
    pub strain: f64,
}

/// ACWR risk classification.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum AcwrRisk {
    /// acwr < 0.8
    Low,
    /// 0.8 <= acwr <= 1.3
    Optimal,
    /// 1.3 < acwr <= 1.5
    Elevated,
    /// acwr > 1.5
    High,
}

/// Compute Edwards TRIMP from zone distribution.
///
/// Edwards TRIMP = (z1_minutes * 1) + (z2_minutes * 2) + (z3_minutes * 3)
///               + (z4_minutes * 4) + (z5_minutes * 5)
///
/// Note: below_z1 time (index 0) is NOT counted (weight = 0).
/// Zone minutes = zone_seconds / 60.0.
pub fn edwards_trimp(zones: &ZoneDistribution) -> f64 {
    let weights = [0.0, 1.0, 2.0, 3.0, 4.0, 5.0];
    zones
        .zone_seconds
        .iter()
        .zip(weights.iter())
        .map(|(&secs, &w)| (secs / 60.0) * w)
        .sum()
}

/// Compute longitudinal load metrics from daily TRIMP values.
///
/// Input: slice of `(date_ordinal, trimp)` pairs, sorted ascending by date.
/// Uses the last 7 entries for acute and last 28 for chronic.
///
/// If fewer than 7 days, acute_load = sum of available, chronic from available.
/// If 0 days, all metrics are 0.0 and acwr is None.
///
/// Monotony = mean(last 7 daily TRIMPs) / sd(last 7 daily TRIMPs).
///   If sd == 0, monotony = 0.0.
/// Strain = sum(last 7 daily TRIMPs) * monotony.
pub fn compute_load_metrics(daily_trimps: &[(i32, f64)]) -> LoadMetrics {
    if daily_trimps.is_empty() {
        return LoadMetrics {
            acute_load: 0.0,
            chronic_load: 0.0,
            acwr: None,
            monotony: 0.0,
            strain: 0.0,
        };
    }

    let n = daily_trimps.len();

    // Last 7 days (or fewer if not enough data).
    let acute_start = if n > 7 { n - 7 } else { 0 };
    let acute_slice = &daily_trimps[acute_start..];
    let acute_load: f64 = acute_slice.iter().map(|(_, t)| t).sum();

    // Last 28 days (or fewer if not enough data).
    let chronic_start = if n > 28 { n - 28 } else { 0 };
    let chronic_slice = &daily_trimps[chronic_start..];
    let chronic_days = chronic_slice.len() as f64;
    let chronic_sum: f64 = chronic_slice.iter().map(|(_, t)| t).sum();
    let chronic_load = (chronic_sum / chronic_days) * 7.0;

    // ACWR
    let acwr = if chronic_load == 0.0 {
        None
    } else {
        Some(acute_load / chronic_load)
    };

    // Monotony and strain from last 7 days.
    let acute_values: Vec<f64> = acute_slice.iter().map(|(_, t)| *t).collect();
    let acute_count = acute_values.len() as f64;
    let mean = acute_load / acute_count;
    let variance = acute_values.iter().map(|v| (v - mean).powi(2)).sum::<f64>() / acute_count;
    let sd = variance.sqrt();

    let monotony = if sd == 0.0 { 0.0 } else { mean / sd };
    let strain = acute_load * monotony;

    LoadMetrics {
        acute_load,
        chronic_load,
        acwr,
        monotony,
        strain,
    }
}

/// Classify ACWR into risk zone.
pub fn classify_acwr(acwr: f64) -> AcwrRisk {
    if acwr < 0.8 {
        AcwrRisk::Low
    } else if acwr <= 1.3 {
        AcwrRisk::Optimal
    } else if acwr <= 1.5 {
        AcwrRisk::Elevated
    } else {
        AcwrRisk::High
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::zones::ZoneDistribution;
    use approx::assert_relative_eq;

    /// Build a ZoneDistribution with given zone_seconds; other fields are defaults.
    fn dist_from_seconds(zone_seconds: [f64; 6]) -> ZoneDistribution {
        let total: f64 = zone_seconds.iter().sum();
        let mut zone_percent = [0.0; 6];
        if total > 0.0 {
            for (i, pct) in zone_percent.iter_mut().enumerate() {
                *pct = (zone_seconds[i] / total) * 100.0;
            }
        }
        ZoneDistribution {
            zone_seconds,
            zone_percent,
            hr_avg: 0.0,
            hr_max_observed: 0,
            hr_min: 0,
            duration_s: total,
        }
    }

    // ── Edwards TRIMP tests ──────────────────────────────────────────

    #[test]
    fn test_edwards_trimp_known_distribution() {
        // Z1=30min, Z2=15min, Z3=5min, Z4=3min, Z5=1min
        // below_z1 = 0min
        // TRIMP = 30*1 + 15*2 + 5*3 + 3*4 + 1*5 = 30+30+15+12+5 = 92
        let dist = dist_from_seconds([
            0.0,         // below Z1
            30.0 * 60.0, // Z1 = 1800s
            15.0 * 60.0, // Z2 = 900s
            5.0 * 60.0,  // Z3 = 300s
            3.0 * 60.0,  // Z4 = 180s
            1.0 * 60.0,  // Z5 = 60s
        ]);
        let trimp = edwards_trimp(&dist);
        assert_relative_eq!(trimp, 92.0);
    }

    #[test]
    fn test_edwards_trimp_all_below_z1() {
        let dist = dist_from_seconds([600.0, 0.0, 0.0, 0.0, 0.0, 0.0]);
        let trimp = edwards_trimp(&dist);
        assert_relative_eq!(trimp, 0.0);
    }

    #[test]
    fn test_edwards_trimp_all_z5() {
        // 10 minutes in Z5
        let dist = dist_from_seconds([0.0, 0.0, 0.0, 0.0, 0.0, 600.0]);
        let trimp = edwards_trimp(&dist);
        // 10 * 5 = 50
        assert_relative_eq!(trimp, 50.0);
    }

    #[test]
    fn test_edwards_trimp_zero_duration() {
        let dist = dist_from_seconds([0.0; 6]);
        let trimp = edwards_trimp(&dist);
        assert_relative_eq!(trimp, 0.0);
    }

    // ── Load metrics tests ───────────────────────────────────────────

    #[test]
    fn test_load_metrics_empty() {
        let m = compute_load_metrics(&[]);
        assert_relative_eq!(m.acute_load, 0.0);
        assert_relative_eq!(m.chronic_load, 0.0);
        assert!(m.acwr.is_none());
        assert_relative_eq!(m.monotony, 0.0);
        assert_relative_eq!(m.strain, 0.0);
    }

    #[test]
    fn test_load_metrics_7_days() {
        // 7 days, each day TRIMP = 100
        let data: Vec<(i32, f64)> = (1..=7).map(|d| (d, 100.0)).collect();
        let m = compute_load_metrics(&data);

        // acute = 700
        assert_relative_eq!(m.acute_load, 700.0);
        // chronic: 7 days available, mean = 100, * 7 = 700
        assert_relative_eq!(m.chronic_load, 700.0);
        // ACWR = 700/700 = 1.0
        assert_relative_eq!(m.acwr.unwrap(), 1.0);
        // monotony: all same => sd = 0 => monotony = 0
        assert_relative_eq!(m.monotony, 0.0);
        assert_relative_eq!(m.strain, 0.0);
    }

    #[test]
    fn test_load_metrics_28_days() {
        // 28 days, linearly increasing TRIMP: day 1 = 10, day 28 = 280
        let data: Vec<(i32, f64)> = (1..=28).map(|d| (d, d as f64 * 10.0)).collect();
        let m = compute_load_metrics(&data);

        // Last 7 days: days 22..28 => TRIMP = 220,230,240,250,260,270,280
        let acute_vals = [220.0, 230.0, 240.0, 250.0, 260.0, 270.0, 280.0];
        let expected_acute: f64 = acute_vals.iter().sum();
        assert_relative_eq!(m.acute_load, expected_acute);

        // Chronic: all 28 days, sum = 10*(1+2+...+28) = 10*406 = 4060
        // mean = 4060/28, * 7 = 4060/4 = 1015
        let expected_chronic = (4060.0 / 28.0) * 7.0;
        assert_relative_eq!(m.chronic_load, expected_chronic);

        assert!(m.acwr.is_some());
        assert_relative_eq!(m.acwr.unwrap(), expected_acute / expected_chronic);

        // Monotony from last 7 values
        let mean_7 = expected_acute / 7.0;
        let var_7: f64 = acute_vals.iter().map(|v| (v - mean_7).powi(2)).sum::<f64>() / 7.0;
        let sd_7 = var_7.sqrt();
        let expected_monotony = mean_7 / sd_7;
        assert_relative_eq!(m.monotony, expected_monotony, epsilon = 1e-10);

        let expected_strain = expected_acute * expected_monotony;
        assert_relative_eq!(m.strain, expected_strain, epsilon = 1e-10);
    }

    #[test]
    fn test_load_metrics_fewer_than_7_days() {
        // 3 days of data
        let data = vec![(1, 50.0), (2, 60.0), (3, 70.0)];
        let m = compute_load_metrics(&data);

        // acute = sum of all 3
        assert_relative_eq!(m.acute_load, 180.0);
        // chronic = mean of 3 * 7 = 60 * 7 = 420
        assert_relative_eq!(m.chronic_load, 420.0);
        // ACWR = 180/420
        assert_relative_eq!(m.acwr.unwrap(), 180.0 / 420.0);
    }

    #[test]
    fn test_load_metrics_monotony_sd_zero() {
        // All identical daily TRIMPs => sd = 0 => monotony = 0
        let data: Vec<(i32, f64)> = (1..=7).map(|d| (d, 50.0)).collect();
        let m = compute_load_metrics(&data);
        assert_relative_eq!(m.monotony, 0.0);
        assert_relative_eq!(m.strain, 0.0);
    }

    #[test]
    fn test_load_metrics_varying_daily() {
        // Deliberately varied to get nonzero monotony
        let data = vec![
            (1, 40.0),
            (2, 60.0),
            (3, 80.0),
            (4, 50.0),
            (5, 70.0),
            (6, 90.0),
            (7, 30.0),
        ];
        let m = compute_load_metrics(&data);

        let values = [40.0, 60.0, 80.0, 50.0, 70.0, 90.0, 30.0];
        let sum: f64 = values.iter().sum(); // 420
        let mean = sum / 7.0; // 60
        let var: f64 = values.iter().map(|v| (v - mean).powi(2)).sum::<f64>() / 7.0;
        let sd = var.sqrt();

        assert_relative_eq!(m.acute_load, sum);
        assert_relative_eq!(m.monotony, mean / sd, epsilon = 1e-10);
        assert_relative_eq!(m.strain, sum * (mean / sd), epsilon = 1e-10);
    }

    #[test]
    fn test_acwr_none_when_chronic_zero() {
        // Single day with TRIMP = 0
        let data = vec![(1, 0.0)];
        let m = compute_load_metrics(&data);
        assert!(m.acwr.is_none());
    }

    // ── ACWR classification tests ────────────────────────────────────

    #[test]
    fn test_classify_acwr_low() {
        assert_eq!(classify_acwr(0.0), AcwrRisk::Low);
        assert_eq!(classify_acwr(0.5), AcwrRisk::Low);
        assert_eq!(classify_acwr(0.79), AcwrRisk::Low);
    }

    #[test]
    fn test_classify_acwr_optimal() {
        assert_eq!(classify_acwr(0.8), AcwrRisk::Optimal);
        assert_eq!(classify_acwr(1.0), AcwrRisk::Optimal);
        assert_eq!(classify_acwr(1.3), AcwrRisk::Optimal);
    }

    #[test]
    fn test_classify_acwr_elevated() {
        assert_eq!(classify_acwr(1.31), AcwrRisk::Elevated);
        assert_eq!(classify_acwr(1.4), AcwrRisk::Elevated);
        assert_eq!(classify_acwr(1.5), AcwrRisk::Elevated);
    }

    #[test]
    fn test_classify_acwr_high() {
        assert_eq!(classify_acwr(1.51), AcwrRisk::High);
        assert_eq!(classify_acwr(2.0), AcwrRisk::High);
        assert_eq!(classify_acwr(10.0), AcwrRisk::High);
    }

    #[test]
    fn test_classify_acwr_boundaries() {
        // Exact boundary values
        assert_eq!(classify_acwr(0.8), AcwrRisk::Optimal); // lower bound of Optimal
        assert_eq!(classify_acwr(1.3), AcwrRisk::Optimal); // upper bound of Optimal
        assert_eq!(classify_acwr(1.5), AcwrRisk::Elevated); // upper bound of Elevated
    }
}
