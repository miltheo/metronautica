# Activity counts: implementation and validation

`accel_metric_agcounts()` implements the published algorithm with optional custom
band-pass cutoffs. Published coefficients: ActiGraph/agcounts, GPL-3.0, commit
3137c9b9a26539ae2d9645d396586fe15faece59;
[Neishabouri et al. (2022)](https://doi.org/10.1038/s41598-022-16003-x).

## Use and interpretation

The [function reference](https://miltheo.github.io/metronautica/reference.html#accel_metric_agcounts) defines inputs,
precision, gap and boundary policies. Counts are standalone; `AG` is not a
`compute_accel_summaries()` selector. Neither Python nor R agcounts is required.
Custom filters produce modified counts without inherited behavioural-threshold validation.

## Calculation stages

1. Convert axes to 30 Hz using the rate-specific historical method, including
   its separate power-of-two path and finite-record behaviour.
2. Round to three decimals; apply the published causal filter with steady-state
   initialisation.
3. Rescale by `(3/4096)/(2.6/256) * 237.5`, rectify, threshold, saturate and quantise.
4. Average and floor groups of three samples to 10 Hz, then accumulate epochs.

Normal quantisation suppresses values below 4, saturates at 128 and floors.
Low-frequency extension suppresses values below 1, uses `floor(value)-1` for
`1 <= value < 4`, and otherwise floors after saturation at 128. It changes
thresholds, not filter coefficients; AGD validation used the Normal filter.

Custom filtering replaces only the band-pass stage: Butterworth prototype order
1-8 (default 4), twice that transfer order, with peak gain matched to the published
filter. Unstable designs error; subsequent scaling/count operations are retained.

GT3X parsing defaults to native precision; `precision = "legacy_3dp"` selects the
earlier rounded conversion. Lost digits cannot be reconstructed. Parsing does
not repair source timestamps or gaps.

## Original experimental validation

The benchmark used 89 paired native/ActiLife 7.1.0 Normal-filter AGD recordings:
45 static and 44 secondary-shaker files. Static comparisons covered initial,
central stationary and final 30-minute windows, retaining preceding context for
internal windows. They did not cover every recording second. Shaker comparisons
used all matching raw coverage. GT9X startup prefixes came from native-header
timing; no lag or parameter was fitted.

| Comparison | Result |
|---|---|
| Pinned official Python reference | Exact match for 3,763,659 one-second axis values, including nonzero counts |
| Synthetic rate checks | All 12 supported rates; eight legacy rates also matched R agcounts 0.7.0 |
| Custom 0.69-10 Hz filter | Matched independently designed SciPy calculation |
| Controlled-shaker AGD | 100% for wGT3X-BT and LEAP; 99.996693% for GT9X |

The GT9X difference affected eight seconds around one missing second.
Carry-forward reproduced those AGD values; zero filling did not. Other residuals
occurred at startup and idle/download transitions. R agcounts also modifies
zero-valued periods internally. These computational comparisons do not establish
universal export reproduction or behavioural validity.

## API verification and benchmark scope

The installed API reproduced the same 3,763,659 published-reference axis values.
Benchmark inputs explicitly used zero filling and GT9X startup padding; recordings
with gaps therefore do not satisfy the strict default policy.

Parser-to-count checks cover complete first trials for LEAP, wGT3X-BT and GT9X.
Legacy precision reproduces the upstream conversion. The audited GT9X trial
contains two one-second gaps, one within controlled excitation. Separate checks
cover gap rejection, carry-forward, boundary padding and affected-epoch flags.

`Rscript tools/validate.R` runs all nine package checks using synthetic signals
and deterministic fixtures, without downloads or external benchmark software.

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
