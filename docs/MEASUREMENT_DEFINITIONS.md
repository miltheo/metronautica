# Measurement definitions

[Workflow](../README.md#processing-workflow) · [Function reference](reference.html) · [PDF](metronautica-reference.pdf)

The R help sources are the maintained technical definitions. This index directs
to the relevant definitions without maintaining a second set of equations.

| Topic | Reference |
|---|---|
| Time, triaxial acceleration, g, metadata and container forms | [Common data format](reference.html#common-data-format) |
| Static offset bias, noise floor, drift and Allan deviation | [Measurement definitions](reference.html#measurement-definitions), [static outcomes](reference.html#static_metrology_from_tbl) |
| Response slope, signed bias, VM integral non-linearity and composite error | [Measurement definitions](reference.html#measurement-definitions), [dynamic outcomes](reference.html#dynamic_metrology_report) |
| Post-parse primary-five diagnostics | [Diagnostic rules, numerators and denominators](reference.html#qc_accel_tbl) |
| Feature operations, units and epoch conventions | [Feature summary specification](reference.html#compute_accel_summaries) and linked individual metrics |
| Activity Index noise variance | [Stationary variance estimation](reference.html#compute_ai_noise_var_from_static) |
| Published-filter and custom-cutoff counts | [Count computation](reference.html#accel_metric_agcounts), [validation](ACTIGRAPH_COUNTS.md) |
| VM calibration, application and provenance | [Calibration fitting](reference.html#dm_fit_vm_calibration) and linked application functions |
| Framework, source functions and interpretation | [Implementation guide](reference.html#implementation-guide) |

The same help sources generate the HTML and PDF references and are installed
with the package. Use `help("measurement-definitions", package = "metronautica")`
for the outcome definitions in R.
