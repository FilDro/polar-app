/// Per-athlete HR configuration using the HR reserve method.
#[derive(Debug, Clone)]
pub struct AthleteConfig {
    pub hr_max: u16,
    pub hr_rest: u16,
    /// Zone boundaries as fractions of HR reserve: [(lower, upper); 5]
    /// Default: Z1=[0.50,0.60], Z2=[0.60,0.70], Z3=[0.70,0.80], Z4=[0.80,0.90], Z5=[0.90,1.00]
    pub zones: [(f64, f64); 5],
}

impl Default for AthleteConfig {
    fn default() -> Self {
        Self {
            hr_max: 195,
            hr_rest: 55,
            zones: [
                (0.50, 0.60),
                (0.60, 0.70),
                (0.70, 0.80),
                (0.80, 0.90),
                (0.90, 1.00),
            ],
        }
    }
}

/// Result of zone classification.
#[derive(Debug, Clone)]
pub struct ZoneDistribution {
    /// Time in seconds for each zone: [below_z1, z1, z2, z3, z4, z5]
    pub zone_seconds: [f64; 6],
    /// Percentage of total time for each zone.
    pub zone_percent: [f64; 6],
    pub hr_avg: f64,
    pub hr_max_observed: u16,
    pub hr_min: u16,
    pub duration_s: f64,
}

/// Classify a series of HR samples into zones.
///
/// Each sample is `(timestamp_s, hr_bpm)`. Samples should be ~1 Hz.
/// Time in each zone is computed from the delta to the next sample;
/// the last sample is assumed to represent 1.0 second.
///
/// HR reserve method:
///   `hr_reserve_fraction = (hr - hr_rest) / (hr_max - hr_rest)`
///   Then classify into the configured zone boundaries.
///
/// Zone index mapping:
///   0 = below Z1 (`hr_reserve_fraction < zones[0].lower`)
///   1 = Z1, 2 = Z2, 3 = Z3, 4 = Z4, 5 = Z5
///
/// If `hr <= hr_rest`, classify as below_z1 (index 0).
/// If `hr >= hr_max`, classify as Z5 (index 5).
pub fn classify_hr_series(samples: &[(f64, u16)], config: &AthleteConfig) -> ZoneDistribution {
    let mut zone_seconds = [0.0_f64; 6];

    if samples.is_empty() {
        return ZoneDistribution {
            zone_seconds,
            zone_percent: [0.0; 6],
            hr_avg: 0.0,
            hr_max_observed: 0,
            hr_min: 0,
            duration_s: 0.0,
        };
    }

    let hr_reserve = f64::from(config.hr_max) - f64::from(config.hr_rest);
    let mut hr_sum: f64 = 0.0;
    let mut hr_max_obs: u16 = 0;
    let mut hr_min_obs: u16 = u16::MAX;

    for (i, &(_, hr)) in samples.iter().enumerate() {
        // Compute the time delta this sample represents.
        let dt = if i + 1 < samples.len() {
            samples[i + 1].0 - samples[i].0
        } else {
            1.0
        };

        // Track stats.
        hr_sum += f64::from(hr);
        if hr > hr_max_obs {
            hr_max_obs = hr;
        }
        if hr < hr_min_obs {
            hr_min_obs = hr;
        }

        // Determine the zone index for this sample.
        let zone_idx = classify_single_hr(hr, config, hr_reserve);
        zone_seconds[zone_idx] += dt;
    }

    let duration_s: f64 = zone_seconds.iter().sum();
    let hr_avg = hr_sum / samples.len() as f64;

    let mut zone_percent = [0.0_f64; 6];
    if duration_s > 0.0 {
        for (i, pct) in zone_percent.iter_mut().enumerate() {
            *pct = (zone_seconds[i] / duration_s) * 100.0;
        }
    }

    ZoneDistribution {
        zone_seconds,
        zone_percent,
        hr_avg,
        hr_max_observed: hr_max_obs,
        hr_min: hr_min_obs,
        duration_s,
    }
}

/// Map a single HR value to a zone index (0..=5).
fn classify_single_hr(hr: u16, config: &AthleteConfig, hr_reserve: f64) -> usize {
    if hr <= config.hr_rest {
        return 0; // below Z1
    }
    if hr >= config.hr_max {
        return 5; // Z5
    }

    let fraction = (f64::from(hr) - f64::from(config.hr_rest)) / hr_reserve;

    for (i, &(lower, upper)) in config.zones.iter().enumerate() {
        if fraction >= lower && fraction < upper {
            return i + 1; // zones are 1-indexed (1=Z1 .. 5=Z5)
        }
    }

    // If fraction falls exactly on the upper bound of Z5 (1.0) but hr < hr_max,
    // or due to floating point we missed the last bucket, assign to Z5.
    if fraction >= config.zones[4].0 {
        return 5;
    }

    // fraction < zones[0].lower — below Z1
    0
}

#[cfg(test)]
mod tests {
    use super::*;
    use approx::assert_relative_eq;

    fn default_config() -> AthleteConfig {
        AthleteConfig::default()
    }

    // Helper: build samples at 1-second intervals starting at t=0.
    fn samples_from_hrs(hrs: &[u16]) -> Vec<(f64, u16)> {
        hrs.iter()
            .enumerate()
            .map(|(i, &hr)| (i as f64, hr))
            .collect()
    }

    #[test]
    fn test_default_config_values() {
        let cfg = AthleteConfig::default();
        assert_eq!(cfg.hr_max, 195);
        assert_eq!(cfg.hr_rest, 55);
        assert_eq!(cfg.zones.len(), 5);
        assert_relative_eq!(cfg.zones[0].0, 0.50);
        assert_relative_eq!(cfg.zones[0].1, 0.60);
        assert_relative_eq!(cfg.zones[4].0, 0.90);
        assert_relative_eq!(cfg.zones[4].1, 1.00);
    }

    #[test]
    fn test_empty_input() {
        let cfg = default_config();
        let result = classify_hr_series(&[], &cfg);
        assert_relative_eq!(result.duration_s, 0.0);
        assert_relative_eq!(result.hr_avg, 0.0);
        assert_eq!(result.hr_max_observed, 0);
        assert_eq!(result.hr_min, 0);
        for s in &result.zone_seconds {
            assert_relative_eq!(*s, 0.0);
        }
    }

    #[test]
    fn test_single_sample() {
        let cfg = default_config();
        // hr_rest=55, hr_max=195, reserve=140
        // HR 125: fraction = (125-55)/140 = 70/140 = 0.50 => Z1 lower bound
        let samples = vec![(0.0, 125_u16)];
        let result = classify_hr_series(&samples, &cfg);

        assert_relative_eq!(result.duration_s, 1.0);
        assert_relative_eq!(result.hr_avg, 125.0);
        assert_eq!(result.hr_max_observed, 125);
        assert_eq!(result.hr_min, 125);
        // Should be 100% in Z1
        assert_relative_eq!(result.zone_seconds[1], 1.0);
        assert_relative_eq!(result.zone_percent[1], 100.0);
    }

    #[test]
    fn test_all_samples_in_one_zone() {
        let cfg = default_config();
        // reserve = 140
        // Z2: fraction in [0.60, 0.70)
        // HR for 0.60 = 55 + 0.60*140 = 55 + 84 = 139
        // HR for 0.70 = 55 + 0.70*140 = 55 + 98 = 153
        // Use HR = 145 => fraction = 90/140 = 0.6428... => Z2
        let hrs: Vec<u16> = vec![145; 10];
        let samples = samples_from_hrs(&hrs);
        let result = classify_hr_series(&samples, &cfg);

        // 9 inter-sample deltas of 1s + 1s for last sample = 10s total
        assert_relative_eq!(result.duration_s, 10.0);
        assert_relative_eq!(result.zone_seconds[2], 10.0); // Z2
        assert_relative_eq!(result.zone_percent[2], 100.0);
        // All other zones should be 0
        for i in [0, 1, 3, 4, 5] {
            assert_relative_eq!(result.zone_seconds[i], 0.0);
        }
    }

    #[test]
    fn test_samples_across_multiple_zones() {
        let cfg = default_config();
        // reserve = 140, rest = 55
        // below_z1: HR <= 55 => use 50
        // Z1: fraction [0.50, 0.60) => HR [125, 139) => use 130
        // Z2: fraction [0.60, 0.70) => HR [139, 153) => use 145
        // Z3: fraction [0.70, 0.80) => HR [153, 167) => use 160
        // Z4: fraction [0.80, 0.90) => HR [167, 181) => use 175
        // Z5: fraction [0.90, 1.00] => HR [181, 195] => use 190
        let samples = vec![
            (0.0, 50_u16),   // below Z1
            (1.0, 130_u16),  // Z1
            (2.0, 145_u16),  // Z2
            (3.0, 160_u16),  // Z3
            (4.0, 175_u16),  // Z4
            (5.0, 190_u16),  // Z5
        ];
        let result = classify_hr_series(&samples, &cfg);

        assert_relative_eq!(result.duration_s, 6.0);
        // Each sample gets 1 second (inter-sample delta=1, last sample=1)
        assert_relative_eq!(result.zone_seconds[0], 1.0); // below Z1
        assert_relative_eq!(result.zone_seconds[1], 1.0); // Z1
        assert_relative_eq!(result.zone_seconds[2], 1.0); // Z2
        assert_relative_eq!(result.zone_seconds[3], 1.0); // Z3
        assert_relative_eq!(result.zone_seconds[4], 1.0); // Z4
        assert_relative_eq!(result.zone_seconds[5], 1.0); // Z5

        for pct in &result.zone_percent {
            assert_relative_eq!(*pct, 100.0 / 6.0, epsilon = 1e-10);
        }
    }

    #[test]
    fn test_below_z1_classification() {
        let cfg = default_config();
        // HR at or below hr_rest => below Z1
        let samples = samples_from_hrs(&[40, 50, 55]);
        let result = classify_hr_series(&samples, &cfg);

        assert_relative_eq!(result.zone_seconds[0], 3.0);
        assert_relative_eq!(result.zone_percent[0], 100.0);
    }

    #[test]
    fn test_z5_classification_at_max() {
        let cfg = default_config();
        // HR at or above hr_max => Z5
        let samples = samples_from_hrs(&[195, 200, 210]);
        let result = classify_hr_series(&samples, &cfg);

        assert_relative_eq!(result.zone_seconds[5], 3.0);
        assert_relative_eq!(result.zone_percent[5], 100.0);
    }

    #[test]
    fn test_hr_stats() {
        let cfg = default_config();
        let samples = vec![
            (0.0, 100_u16),
            (1.0, 120_u16),
            (2.0, 140_u16),
            (3.0, 160_u16),
            (4.0, 180_u16),
        ];
        let result = classify_hr_series(&samples, &cfg);

        let expected_avg = (100.0 + 120.0 + 140.0 + 160.0 + 180.0) / 5.0;
        assert_relative_eq!(result.hr_avg, expected_avg);
        assert_eq!(result.hr_max_observed, 180);
        assert_eq!(result.hr_min, 100);
    }

    #[test]
    fn test_non_uniform_timestamps() {
        let cfg = default_config();
        // Z1 HR = 130 (fraction ~0.5357)
        // Place two samples with a 5-second gap, then one at +1s
        let samples = vec![
            (0.0, 130_u16),
            (5.0, 130_u16),
            (6.0, 130_u16),
        ];
        let result = classify_hr_series(&samples, &cfg);

        // First sample: dt = 5.0, second: dt = 1.0, last: dt = 1.0
        assert_relative_eq!(result.duration_s, 7.0);
        assert_relative_eq!(result.zone_seconds[1], 7.0); // all Z1
    }

    #[test]
    fn test_zone_boundary_lower_z1() {
        let cfg = default_config();
        // reserve = 140, rest = 55
        // fraction = 0.50 exactly => HR = 55 + 0.50*140 = 55 + 70 = 125
        // Z1 is [0.50, 0.60), so 0.50 should be Z1
        let samples = vec![(0.0, 125_u16)];
        let result = classify_hr_series(&samples, &cfg);
        assert_relative_eq!(result.zone_seconds[1], 1.0);
    }

    #[test]
    fn test_hr_just_above_rest_below_z1() {
        let cfg = default_config();
        // reserve = 140, rest = 55
        // HR = 56 => fraction = 1/140 = 0.00714 < 0.50 => below Z1
        let samples = vec![(0.0, 56_u16)];
        let result = classify_hr_series(&samples, &cfg);
        assert_relative_eq!(result.zone_seconds[0], 1.0);
    }
}
