# Activity counts: implementation and validation

[Workflow](../README.md#processing-workflow) · [HTML guide](index.html) · [HTML reference](reference.html) · [PDF reference](metronautica-reference.pdf)

The standalone `accel_metric_agcounts()` API is implemented in `R/m_agcounts.R`.
Its Rd help and generated reference manual are the parameter/method reference.
This is an implementation of the published algorithm, not a newly proposed
historical count definition. Published coefficients are acknowledged from
ActiGraph/agcounts under GPL-3.0, commit
3137c9b9a26539ae2d9645d396586fe15faece59; see
[Neishabouri et al. (2022)](https://doi.org/10.1038/s41598-022-16003-x).

## Use and interpretation

Use `accel_metric_agcounts()` for the published-filter calculation or explicit
custom cutoffs. Input precision, gap handling and boundary policies are part of
the pipeline; modified counts do not inherit behavioural-threshold validation.
[Function parameters and method](reference.html#accel_metric_agcounts) define
these settings. [The processing guide](REAL_DATA_EXAMPLES.md#feature-settings)
links count computation to the acceleration workflow.

## Original experimental validation

The experiment included 89 paired native/ActiLife 7.1.0 Normal-filter AGD
recordings: 45 static files and 44 secondary-shaker files. Static checks used
initial, central stationary and final 30-minute windows, with preceding context
for internal windows. They did not cover every static-recording second.
Secondary checks used all matching raw coverage. GT9X startup prefixes were
explicitly derived from native-header timing. No lag or parameter was fitted.

Across 3,763,659 paired one-second axis values, the calculation matched the
pinned official Python reference exactly, including nonzero counts. Synthetic
checks covered all 12 supported rates; all eight legacy rates also matched R
agcounts 0.7.0. A custom 0.69-10 Hz example matched an independently designed
SciPy calculation. These are computational comparisons, not behavioural tests.

AGD agreement in the controlled-shaker interval was 100% for wGT3X-BT and LEAP,
and 99.996693% for GT9X. The latter involved eight affected seconds around a one-second
missing interval. A targeted carry-forward test reproduced those AGD values, whereas zero
filling did not. Other residuals concerned startup and idle/download transitions.
R agcounts also modifies zero-valued periods internally, so its public wrapper
need not evaluate the supplied values unchanged. Matching the calculation does
not establish universal export reproduction under different input conventions.

The accompanying CSV files report full-record/window agreement, nonzero-count
agreement, maximum differences and coverage. Python and R agcounts were external
benchmarks only; neither is required to install or use Metronautica.

## API verification and benchmark scope

The standalone API reproduced all 3,763,659 pinned published-reference axis
values over the 89-recording benchmark. Benchmark inputs use explicit zero-fill
and GT9X startup-padding conventions; this does not imply that recordings with
gaps satisfy the function's strict default policy.

Native parser-to-count checks cover complete first shaker trials for LEAP,
wGT3X-BT and GT9X. Explicit legacy precision reproduces the upstream conversion.
The audited GT9X recording has two one-second missing intervals; only one lies
within the controlled-shaker window. Gap rejection, explicit carry-forward,
boundary padding and affected-epoch flags are checked separately.

Package tests use synthetic signals and small deterministic reference fixtures;
they do not download recordings or require external benchmark software. Run
`Rscript tools/validate.R` after installing the package to execute all eight
checks, including counts.

## Benchmark tables

Tables are in [validation](validation/). The recording/window summaries include
startup and other transitions; controlled-shaker agreement is reported separately.
Their denominators and intervals must be retained when interpreting percentages.

| File | Content |
|---|---|
| [final_agreement_by_device.csv](validation/final_agreement_by_device.csv) | Reference and AGD agreement by device and recording type |
| [final_agd_agreement_by_period.csv](validation/final_agd_agreement_by_period.csv) | AGD agreement by assessment interval |
| [final_coverage_by_device.csv](validation/final_coverage_by_device.csv) | Paired recording and epoch coverage |
| [integration_agreement.csv](validation/integration_agreement.csv) | Installed-API agreement over the benchmark inputs |
| [integration_coverage.csv](validation/integration_coverage.csv) | Window coverage and missing samples |
| [native_agd_start_times.csv](validation/native_agd_start_times.csv) | Native versus AGD recording-start times |
