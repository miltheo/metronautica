# Measurement definitions

Canonical definitions are maintained in R help and shared by the HTML/PDF references.

| Topic | Reference |
|---|---|
| Four-column acceleration contract and optional pipeline fields | [Metronautica Tibble 0.1.0](../data-contract/0.1.0/SPECIFICATION.md), [reference summary](https://miltheo.github.io/metronautica/reference.html#common-data-format) |
| Static offset bias, noise floor, drift and Allan deviation | [Measurement definitions](https://miltheo.github.io/metronautica/reference.html#measurement-definitions), [static outcomes](https://miltheo.github.io/metronautica/reference.html#static_metrology_from_tbl) |
| Response slope, signed bias, VM integral non-linearity and composite error | [Measurement definitions](https://miltheo.github.io/metronautica/reference.html#measurement-definitions), [dynamic outcomes](https://miltheo.github.io/metronautica/reference.html#dynamic_metrology_report) |
| Post-parse primary-five diagnostics | [Diagnostic rules, numerators and denominators](https://miltheo.github.io/metronautica/reference.html#qc_accel_tbl) |
| Feature operations, units and epoch conventions | [Feature summary specification](https://miltheo.github.io/metronautica/reference.html#compute_accel_summaries) and linked individual metrics |
| Activity Index noise variance | [Stationary variance estimation](https://miltheo.github.io/metronautica/reference.html#compute_ai_noise_var_from_static) |
| Published-filter and custom-cutoff counts | [Count computation](https://miltheo.github.io/metronautica/reference.html#accel_metric_agcounts), [validation](ACTIGRAPH_COUNTS.md) |
| VM calibration, application and provenance | [Calibration fitting](https://miltheo.github.io/metronautica/reference.html#dm_fit_vm_calibration) and linked application functions |
| Framework, source functions and interpretation | [Function map](../README.md#function-map), [container contracts](https://miltheo.github.io/metronautica/reference.html#common-data-format--input-and-return-contracts) |

In R: `help("measurement-definitions", package = "metronautica")`.
