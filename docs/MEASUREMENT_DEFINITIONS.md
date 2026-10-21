# Calculation definitions and manuscript correspondence

The approved study Methods and feature tables define the measurement outcomes.
This guide follows those definitions; it does not introduce new study criteria.
The R help sources (`man/*.Rd`) define the public interface and generate the PDF
manual. Study-level aggregation, inference and final comparison criteria remain outside this package.

## Static and dynamic characterisation

| Quantity | Definition and units | Implementation / study distinction |
|---|---|---|
| Vector magnitude (VM) | sqrt(ax^2 + ay^2 + az^2), in g | Sample-level VM; an epoch or stage mean is a specified summary |
| Timestamp-derived sampling frequency | Reciprocal of the implemented median timestamp interval, Hz | The static/QC helpers retain finite positive intervals; the dynamic helper uses its documented median interval. Reconstructed timestamps do not establish independent clock accuracy |
| Static noise floor | Maximum axis-specific residual SD after linear detrending over the selected stationary window | Study window: 24 h; reported in mg; engine `static_noise_floor_mg` |
| First-five-minute maximum-axis SD | Maximum axis-specific raw sample SD during the first five minutes | Not detrended; engine `static_noise_floor_5min_mg` is a retained field name |
| Signed 1-g VM offset bias | Mean of the initial five-minute one-second VM means minus 1 g | Engine g; study mg; includes the 300-s boundary |
| Signed VM drift rate | Least-squares slope of one-second VM means against elapsed hours | Engine g/h; study mg/h; axis-specific slopes are separate outputs |
| Raw SD | Sample SD with denominator n-1 | Distinct from detrended residual SD |
| Detrended residual SD | sqrt(sum(residual^2)/(n-2)) after linear detrending | Used in the operational static noise floor |
| Static CV | 100 SD / absolute mean | Percent; undefined below the configured near-zero mean guard |
| Allan deviation | sqrt(mean(diff(non-overlapping cluster means)^2)/2) at each averaging time | Axis-specific, g; retained candidate times require at least four complete clusters |
| Maximum-axis Allan minimum | Maximum across axes of their individual minimum Allan deviations over evaluated averaging times | Study summary in micro-g; axis-specific curves remain necessary for interpretation |
| Signed dynamic VM bias | Mean signed test-minus-reference VM difference within a stage | Engine `vm_bias_vs_reference`, g |
| Absolute VM bias | Absolute value of the stage-mean signed test-minus-reference VM difference | Study outcome; not the mean absolute sample-level difference |
| Response slope and intercept | Ordinary-least-squares test VM on length-matched reference VM | Slope dimensionless; intercept g. The feature-on-controlled-input fit is a distinct the study model |
| Scale-factor error | Response slope minus one | Engine fraction; study percentage = 100 times this value |
| VM integral non-linearity | 100 max absolute stage-specific fitted residual / (sqrt(3) F) | Engine `linearity_error_vs_reference`; F is axis peak-to-peak span in g |
| Trial-level composite error | 100 max absolute pooled fitted residual / (sqrt(3) F / 2) | Engine `composite_error`; differs from stage VM integral non-linearity in fitting scope and denominator |
| Within-stage epoch-mean VM CV | SD of epoch-mean VM / mean epoch-mean VM within one stage | Engine `repeatability_error_cv`, fraction; a within-stage variability diagnostic |
| Trial-to-trial VM repeatability CV | 100 SD / mean of stage-mean VM across repeated trials for the same unit, stage and pipeline | the study manuscript repeatability outcome; not the engine's within-stage CV |

For configured axis limits +/-A, F = 2A. The study VM normalising span is
sqrt(3) F; it is not the nonnegative VM output range [0, sqrt(3) A]. Supply 16
for +/-8 g. Conversions to mg and percentages are explicit reporting operations.
Neither the composite error nor a confidence interval is a complete measurement
uncertainty budget.

## Acceleration-derived features

All definitions identify the processing operation before aggregation. The study
uses five-second epochs; the public function supports other explicit settings.
Acceleration is numerical in g before conversion to mg.

| Scientific name / identifier | Definition for the study-used implementation |
|---|---|
| Vector magnitude / `VM` | Epoch mean of sqrt(ax^2 + ay^2 + az^2); g by default |
| Euclidean Norm Minus One / `ENMO` | Epoch mean of max(VM - 1, 0); negative differences are truncated per sample before averaging; mg by default |
| Mean amplitude deviation / `MAD` | Epoch mean absolute deviation of VM from its within-epoch mean; mg by default |
| GENEActiv-style SVMgs / `SVMGS` | Epoch sum of abs(VM - 1); g samples per epoch; depends on sample count |
| Frequency-normalised SVMg.s / `SVMGSEC` | Epoch sum of abs(VM - 1) divided by sampling frequency; g seconds per epoch |
| Mean SVMg / `SVMGMEAN` | Epoch mean of abs(VM - 1); mg by default |
| Band-pass SVM / `SVMBP`, `SVMBP_02_15`, `SVMBP_069_10` | Filter each axis, recombine as VM, then take the epoch mean; mg by default. Named variants specify 0.2-15 Hz and 0.69-10 Hz |
| Overall dynamic body acceleration / `ODBA` | Epoch mean of abs(dx) + abs(dy) + abs(dz), where each dynamic component is the axis minus its centred 3-s running mean; mg by default |
| ROCAM / `ROCAM` | Epoch mean Euclidean sample-to-sample triaxial acceleration change, with a one-second running median applied to the difference series. No division by elapsed time or one-second resampling is performed; retained unit label: g/sample change |
| Activity Index / `AI` | Epoch sum of sqrt(max((vx + vy + vz)/3 - v0, 0)) over one-second windows. the study supplies unit-specific stationary noise variance v0; the generic package requires a supplied stationary noise variance by default; configured-window estimation requires explicit opt-in |
| MIMS-unit / `MIMS` | The specified MIMSunit implementation and settings. The manuscript distinguishes upstream-default 0.2-5 Hz from altered 0.2-10 Hz; this wrapper defaults to 0.2-5 Hz; request 0.2-10 Hz explicitly |
| ActiGraph counts / `AG` | Historical study observations retain their original provenance. A separate standalone count function is available in Metronautica; it does not regenerate or replace those observations. See its help for the published-filter and modified-filter definitions. |

The generic function also supports vectorial dynamic body acceleration (`VEDBA`:
epoch mean Euclidean norm of dynamic-axis components), partial dynamic body
acceleration (`PDBA`: epoch mean sum of selected absolute dynamic components),
full-vector Z-angle (`ZANGLE`: epoch mean atan(z/sqrt(x^2+y^2)) in degrees), and
full-vector Z-angle change (`ZANGLE_CHANGE`: epoch mean absolute successive change
after five-second running-median smoothing). Configurable separation, summary,
scaling and window choices define distinct pipelines, not equivalent defaults.

SVMgs, SVMg.s and Mean SVMg use absolute differences, whereas ENMO truncates
negative differences to zero. Named band-pass pipelines include their effective
cutoffs: the study's nominal 15-Hz upper cutoff was clipped for SENS motion.
The generic SVMbp sum/integral outputs are not the manuscript's mean-mg feature.

## Interpretation and responsibilities

The common data format contains timestamps and triaxial acceleration in g;
`accel_tbl` is its R implementation. A native signal can include stored device
calibration applied during decoding. It has no additional study filtering or
within-trial dynamic VM calibration.

The initial static window uses `elapsed_h <= 5/60` on one-second bins. Dynamic
reference length matching selects nearest positions on an evenly spaced
sample-index grid. It does not interpolate values or correct timestamps. The
pooled fit length-matches concatenated reference data once after concatenation,
separately from per-stage matching. the study reports timing sensitivity separately.

`filter_accel_tbl()` retains the fourth-order Butterworth implementation and its
forward-backward cutoff correction. The summary-suite band-pass helper has its
own implementation and settings; the two are not interchangeable by filter name.

the study calculates feature response integral non-linearity against the fitted feature
response span, and equivalence margins against the robust observed full-range
feature span. Neither is the VM full-scale normalisation above. The manuscript's
trial-to-trial repeatability, activation threshold, operational deadband endpoint,
spectral features and inferential decisions remain study-owned. The report's
activation/dead-band fields are unestimated placeholders.

Known-signal tests reconstruct implemented arithmetic. Experimental device
comparisons belong to the study. The engine does not establish behavioural validity,
universal interchangeability or a complete uncertainty budget for a downstream
algorithm. Retained output identifiers and numerical calculations are unchanged.
