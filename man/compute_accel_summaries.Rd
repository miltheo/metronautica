\name{compute_accel_summaries}
\alias{compute_accel_summaries}
\title{Compute epoch-level acceleration features}
\description{\if{latex}{\out{\sloppy}} Compute time-domain summaries through explicitly configured processing pipelines.}
\usage{
compute_accel_summaries(accel_input, measures = c("ENMO", "MAD"),
    epoch_s = 5, epoch_anchor = c("center", "start", "end"), fs_hz =
    NULL, target_fs = NULL, dynamic_range_g = NULL, vm_summary =
    c("mean", "sd", "max", "p95"), vm_unit = c("g", "mg"), enmo_mg =
    TRUE, mad_mg = TRUE, odba_static_dynamic_method =
    c("centered_running_mean", "low_pass_static_filter",
    "high_pass_dynamic_filter"), odba_stroke_window_rule =
    c("fixed_3s", "custom_window_s", "stroke_period_1x",
    "stroke_period_2x", "sensitivity_windows"),
    odba_running_mean_window_s = 3, odba_stroke_period_s = NA_real_,
    odba_lowpass_cutoff_hz = 0.2, odba_highpass_cutoff_hz = 0.2,
    odba_filter_type = "butterworth", odba_filter_order = 4,
    pdba_axes = c("x", "y"), odba_unit = c("mg", "g"),
    odba_sensitivity_windows_s = c(1, 2, 3, 5, 10),
    odba_edge_handling = "partial_centered_window",
    odba_missing_data_policy = "mean_na_rm", svmg_output =
    c("g_seconds", "sample_sum_g", "mean_mg", "mean_g"),
    svmg_rectify = TRUE, svmbp_cutoffs = c(0.2, 15), svmbp_order =
    4, svmbp_output = c("mean_mg", "mean_g", "sum_mg", "sum_g",
    "g_seconds"), svmbp_nyquist_action = c("stop", "clip"),
    rocam_median_s = 1, ai_noise_var = NULL, ai_noise_mode =
    c("supplied", "window_start", "quiet_segments"), ai_noise_window_s = 30,
    ai_quiet_quantile = 0.1, ai_scale = c("absolute", "relative"),
    ai_epoch_summary = c("sum", "mean"), z_angle_output =
    c("mean_deg", "sd_deg"), z_angle_change_median_s = 5,
    z_angle_change_output = c("mean_abs_change_deg",
    "max_abs_change_deg"), mims_filter_type = "butter", mims_cutoffs
    = c(0.2, 5), mims_use_extrapolation = TRUE, mims_use_filtering
    = TRUE, mims_combination = "sum", mims_allow_truncation = TRUE,
    ag_lfe = FALSE, ag_preprocess = c("none", "regularise",
    "paper30", "antialias100"), ag_anchor = c("floor_sec",
    "round_sec"), ag_antialias_cutoff_hz = NULL, ag_filter_order =
    4, quiet = FALSE)
}
\arguments{
\item{accel_input}{\if{latex}{\out{\sloppy}} Acceleration table or parser/clip bundle with data/full; see \code{\link{common-data-format}}.}
\item{measures}{\if{latex}{\out{\sloppy}} Case-insensitive feature identifiers. Defaults: ENMO and MAD. Other choices are listed under Feature identifiers.}
\item{epoch_s}{\if{latex}{\out{\sloppy}} Positive epoch duration (s); see the pipeline epoch conventions in \code{\link{compute_accel_summaries}}.}
\item{epoch_anchor}{\if{latex}{\out{\sloppy}} Label each epoch by its first (start), last (end) or middle (center) observed sample. Upstream implementations may retain different anchors; inspect timestamps before joining.}
\item{fs_hz}{\if{latex}{\out{\sloppy}} Explicit input rate (Hz); otherwise acquisition metadata, then median positive timestamp interval. target_fs controls separate interpolation. Neither setting establishes regularity.}
\item{target_fs}{\if{latex}{\out{\sloppy}} Optional positive target rate in Hz. Linear interpolation is applied when it differs from the input rate; this alone is not an anti-aliasing filter.}
\item{dynamic_range_g}{\if{latex}{\out{\sloppy}} Configured peak-to-peak axis span (\eqn{g}); NULL uses acquisition metadata. Required for MIMS; see \code{\link{accel_metric_mims}}.}
\item{vm_summary}{\if{latex}{\out{\sloppy}} VM epoch statistic: mean, sample SD, maximum or 95th percentile.}
\item{vm_unit}{\if{latex}{\out{\sloppy}} VM output unit: \eqn{g} or m\eqn{g}.}
\item{enmo_mg}{\if{latex}{\out{\sloppy}} ENMO output in m\eqn{g} (TRUE) or \eqn{g} (FALSE).}
\item{mad_mg}{\if{latex}{\out{\sloppy}} MAD output in m\eqn{g} (TRUE) or \eqn{g} (FALSE).}
\item{odba_static_dynamic_method}{\if{latex}{\out{\sloppy}} Axis static/dynamic separation method; see \code{\link{accel_metric_odba}} for all body-acceleration settings below.}
\item{odba_stroke_window_rule}{\if{latex}{\out{\sloppy}} Running-mean window rule: fixed, custom, stroke-period-based or sensitivity_windows.}
\item{odba_running_mean_window_s}{\if{latex}{\out{\sloppy}} Custom/main sensitivity running-mean duration (s); fixed_3s overrides it.}
\item{odba_stroke_period_s}{\if{latex}{\out{\sloppy}} Supplied cycle period (s) for stroke-period rules; minimum averaging window 3 s.}
\item{odba_lowpass_cutoff_hz}{\if{latex}{\out{\sloppy}} Static-component low-pass cutoff (Hz), for low_pass_static_filter.}
\item{odba_highpass_cutoff_hz}{\if{latex}{\out{\sloppy}} Dynamic-component high-pass cutoff (Hz), for high_pass_dynamic_filter.}
\item{odba_filter_type}{\if{latex}{\out{\sloppy}} Separation filter: butterworth.}
\item{odba_filter_order}{\if{latex}{\out{\sloppy}} Separation Butterworth order; unused by running-mean methods.}
\item{pdba_axes}{\if{latex}{\out{\sloppy}} PDBA axes: x, y and/or z (default x/y).}
\item{odba_unit}{\if{latex}{\out{\sloppy}} Body-acceleration epoch means in m\eqn{g} or \eqn{g}.}
\item{odba_sensitivity_windows_s}{\if{latex}{\out{\sloppy}} Alternative running-mean durations (s); results in settings$odba$sensitivity_summary.}
\item{odba_edge_handling}{\if{latex}{\out{\sloppy}} partial_centered_window: average available boundary samples.}
\item{odba_missing_data_policy}{\if{latex}{\out{\sloppy}} mean_na_rm: omit missing observations from means.}
\item{svmg_output}{\if{latex}{\out{\sloppy}} Inactive compatibility argument; SVMGS/SVMGSEC/SVMGMEAN fix aggregation.}
\item{svmg_rectify}{\if{latex}{\out{\sloppy}} Rectify VM-minus-1-\eqn{g}; see \code{\link{accel_metric_svmg}}.}
\item{svmbp_cutoffs}{\if{latex}{\out{\sloppy}} Custom axis band-pass edges (Hz); named variants fix cutoffs. See \code{\link{accel_metric_svmbp}}.}
\item{svmbp_order}{\if{latex}{\out{\sloppy}} Axis band-pass Butterworth order (forward/reverse).}
\item{svmbp_output}{\if{latex}{\out{\sloppy}} Band-pass aggregation: epoch mean, sample sum or time integral; units follow the selected identifier.}
\item{svmbp_nyquist_action}{\if{latex}{\out{\sloppy}} stop rejects invalid upper cutoffs; clip limits them to 99 percent of Nyquist.}
\item{rocam_median_s}{\if{latex}{\out{\sloppy}} Change-series running-median duration (s); see \code{\link{accel_metric_rocam}} for sample rounding and units.}
\item{ai_noise_var}{\if{latex}{\out{\sloppy}} Stationary mean-axis noise variance (\eqn{g} squared); zero disables subtraction. See \code{\link{accel_metric_ai}}.}
\item{ai_noise_mode}{\if{latex}{\out{\sloppy}} supplied requires variance; window_start/quiet_segments enables estimation when variance is NULL. Supplied variance takes precedence.}
\item{ai_noise_window_s}{\if{latex}{\out{\sloppy}} Initial noise-window duration (s), for window_start.}
\item{ai_quiet_quantile}{\if{latex}{\out{\sloppy}} Quiet-selection quantile, strictly between zero and one.}
\item{ai_scale}{\if{latex}{\out{\sloppy}} absolute: \eqn{g}; relative: dimensionless noise-relative index.}
\item{ai_epoch_summary}{\if{latex}{\out{\sloppy}} Epoch sum or mean of one-second AI values.}
\item{z_angle_output}{\if{latex}{\out{\sloppy}} Epoch mean or sample SD in degrees; see \code{\link{accel_metric_z_angle}}.}
\item{z_angle_change_median_s}{\if{latex}{\out{\sloppy}} Z-angle running-median duration (s); see \code{\link{accel_metric_z_angle_change}}.}
\item{z_angle_change_output}{\if{latex}{\out{\sloppy}} Epoch mean or maximum absolute successive Z-angle change (degrees).}
\item{mims_filter_type}{\if{latex}{\out{\sloppy}} MIMS filter family; see \code{\link{accel_metric_mims}} for all MIMS settings below.}
\item{mims_cutoffs}{\if{latex}{\out{\sloppy}} MIMS band-pass cutoffs (Hz), default c(0.2, 5).}
\item{mims_use_extrapolation}{\if{latex}{\out{\sloppy}} Enable upstream saturation/extrapolation processing.}
\item{mims_use_filtering}{\if{latex}{\out{\sloppy}} Enable internal MIMS band-pass filtering.}
\item{mims_combination}{\if{latex}{\out{\sloppy}} Combine axis summaries by sum or vector magnitude (vm).}
\item{mims_allow_truncation}{\if{latex}{\out{\sloppy}} Allow upstream small-value truncation to zero.}
\item{ag_lfe, ag_preprocess, ag_anchor, ag_antialias_cutoff_hz, ag_filter_order}{\if{latex}{\out{\sloppy}} Inactive compatibility arguments. Use \code{\link{accel_metric_agcounts}} for counts.}
\item{quiet}{\if{latex}{\out{\sloppy}} Suppress informational messages, retaining errors.}
}
\value{\if{latex}{\out{\sloppy}} Invisible list: \code{data_wide} (time, one column per measure), \code{data_long} (time, measure, value), \code{settings} (resolved rate, input provenance, range, processing).

Settings include metric_units; bandpass (requested/applied cutoffs, order, rate, Nyquist handling); dynamic_range_g, dynamic_range_limits_g and dynamic_range_source (argument/metadata/unavailable). Requested mims settings record configuration/dependency version; ai records noise variance/source, applicable estimation options, scale and aggregation. Unrequested feature settings are NULL.

No behavioural classification is returned. Save the call alongside settings: not every argument is recorded.}
\details{\if{latex}{\out{\sloppy}} Input follows \code{\link{metronautica-tibble}} and is timestamp-sorted; epoch conventions below describe the feature pipeline. Feature-specific methods, limits and return settings are defined by the direct functions below. MIMS requires optional MIMSunit and a configured measurement span; AI requires noise variance unless estimation is selected. Inspect QC before processing; gaps are not repaired.}
\seealso{The \href{https://github.com/miltheo/metronautica/blob/main/examples/feature_settings.R}{feature-settings example} demonstrates explicit configuration. See \href{https://github.com/miltheo/metronautica/blob/main/docs/GETTING_STARTED.md#compare-feature-pipelines}{Feature comparison} for the dynamic comparison.}
\examples{
# Load the installed recording.
path <- system.file("extdata", "example_motion.csv",
    package = "metronautica", mustWork = TRUE)
x <- parse_raw_auto(path)
# Defaults: ENMO and MAD.
# Select features explicitly.
features <- compute_accel_summaries(x,
    measures = c("VM", "ENMO", "MAD", "SVMBP_069_10"),
    epoch_s = 5, fs_hz = 100, quiet = TRUE)
# Inspect values and units.
head(features$data_wide)
features$settings$metric_units
}


\section{Feature identifiers}{
\if{latex}{\out{\sloppy}}
\tabular{lll}{
Identifier \tab Direct function \tab Default output \cr
VM \tab \code{\link{accel_metric_vm}} \tab Mean, \eqn{g} \cr
ENMO \tab \code{\link{accel_metric_enmo}} \tab Mean, m\eqn{g} \cr
MAD \tab \code{\link{accel_metric_mad}} \tab Mean, m\eqn{g} \cr
ODBA \tab \code{\link{accel_metric_odba}} \tab Mean, m\eqn{g} \cr
VEDBA \tab \code{accel_metric_odba} \tab Mean, m\eqn{g} \cr
PDBA \tab \code{accel_metric_odba} \tab Mean, m\eqn{g} \cr
SVMGS \tab \code{\link{accel_metric_svmg}} \tab Sample sum, \eqn{g} \cr
SVMGSEC \tab \code{accel_metric_svmg} \tab Integral, \eqn{g} seconds \cr
SVMGMEAN \tab \code{accel_metric_svmg} \tab Mean, m\eqn{g} \cr
SVMBP \tab \code{\link{accel_metric_svmbp}} \tab Mean, m\eqn{g} \cr
SVMBP_02_15 \tab \code{accel_metric_svmbp} \tab Mean, m\eqn{g} \cr
SVMBP_069_10 \tab \code{accel_metric_svmbp} \tab Mean, m\eqn{g} \cr
ROCAM \tab \code{\link{accel_metric_rocam}} \tab Mean change, \eqn{g} \cr
AI \tab \code{\link{accel_metric_ai}} \tab Sum of 1-s AI, \eqn{g} \cr
ZANGLE \tab \code{\link{accel_metric_z_angle}} \tab Mean, degrees \cr
ZANGLE_CHANGE \tab \code{\link{accel_metric_z_angle_change}} \tab Mean change, degrees \cr
MIMS \tab \code{\link{accel_metric_mims}} \tab MIMS-units per epoch \cr
}

The SVM gravity-subtracted identifiers fix their aggregation; \code{svmg_rectify = FALSE} instead retains signed differences. SVMBP uses \code{svmbp_cutoffs}; the named variants fix their cutoffs, while \code{svmbp_output} still selects their aggregation. The direct helpers define processing alternatives. AG is not an available selector.
}

\section{Pipeline rate and epoch conventions}{\if{latex}{\out{\sloppy}}
These are optional pipeline conventions, not required fields of the Metronautica Tibble contract. Feature rate precedence is explicit \code{fs_hz}, metadata, then timestamps. Neither nominal nor timestamp-derived rate independently validates a clock. Filters and index pairing also require suitable regularity or synchronisation.

Unless documented otherwise, positive \code{epoch_s} defines elapsed-time bins from the first sample, retaining the final partial epoch. Different durations define different pipelines. \code{anchor} selects an observed sample: start = first, end = last, center = ceiling of half the epoch sample count. Labels do not affect values. Activity Index uses one-second bin starts; MIMS retains upstream conventions; activity counts have separate boundaries. The dispatcher sorts timestamps; \code{as_accel_tbl()} does not.
}
\section{Epoch timestamps and joins}{\if{latex}{\out{\sloppy}} Features can use different epoch labels. data_long preserves each feature's timestamps; data_wide joins exact timestamps, potentially creating extra rows and unpaired NA cells. These need not indicate missing acceleration; do not zero-fill them. See the \href{https://github.com/miltheo/metronautica/blob/main/examples/offline_workflow.R}{worked epoch-label example}.}
