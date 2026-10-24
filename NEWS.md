# metronautica 0.1.0

Initial release.

- Metronautica Tibble: four sample columns with optional metadata, diagnostics
  and assessment records.

- Static/noise and dynamic assessments attach compact report records by default
  (`attach_report = FALSE` opts out). Returned `data` retains the assessed source;
  dynamic reports also return enriched `test_clips`. Signal/selection changes mark
  inherited assessments as historical.

- Native wearable accelerometer parsing, common data format and primary-five signal diagnostics.
- Time-window and stepped-RPM clipping; static and dynamic metrological characterisation.
- Filtering, calibration provenance, time-domain features and interactive plots.
- Standalone published-filter and custom-cutoff activity counts.
- Checksum-verified access to separately distributed native-recording examples.
