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
\item{accel_input}{\if{latex}{\out{\sloppy}} Common-format acceleration table, parser bundle with \code{data}, or dynamic clip bundle with \code{full}. A plain data frame with the four common columns is also accepted.}
\item{measures}{\if{latex}{\out{\sloppy}} Distinct case-insensitive identifiers listed in Feature identifiers, with their direct functions and default outputs.}
\item{epoch_s}{\if{latex}{\out{\sloppy}} Positive output-epoch duration in seconds. Samples are grouped by elapsed time from the first sample; the final partial epoch is retained. Different epoch lengths define different processing pipelines.}
\item{epoch_anchor}{\if{latex}{\out{\sloppy}} Timestamp assigned to an output epoch: start, end or center selects the first, last or middle observed sample respectively. Some upstream feature implementations retain their own anchors; inspect times before joining features.}
\item{fs_hz}{\if{latex}{\out{\sloppy}} Optional explicit input frequency in Hz. Otherwise use valid acquisition metadata, then the median positive timestamp interval. target_fs, when supplied, controls a separate interpolation step; neither setting establishes regular sampling.}
\item{target_fs}{\if{latex}{\out{\sloppy}} Optional positive target rate in Hz. Linear interpolation is applied when it differs from the input rate; this alone is not an anti-aliasing filter.}
\item{dynamic_range_g}{\if{latex}{\out{\sloppy}} Peak-to-peak configured axis measurement span in g: 16 means -8 to +8 g. The summary function uses valid acquisition metadata when NULL; MIMS fails if neither is available. The direct MIMS function requires this argument. No range is inferred from observed values.}
\item{vm_summary}{\if{latex}{\out{\sloppy}} Statistic of sample VM within each epoch: mean, sample SD, maximum, or the 95th percentile. All use sqrt(ax_g^2 + ay_g^2 + az_g^2).}
\item{vm_unit}{\if{latex}{\out{\sloppy}} Output unit for the VM statistic: g, or mg after multiplication by 1000. No calibration is implied.}
\item{enmo_mg}{\if{latex}{\out{\sloppy}} Logical; multiply the ENMO epoch mean by 1000 for mg when TRUE; otherwise retain g. Negative VM-minus-1-g samples are truncated before averaging.}
\item{mad_mg}{\if{latex}{\out{\sloppy}} Logical; multiply within-epoch mean absolute deviation of VM by 1000 for mg when TRUE; otherwise retain g.}
\item{odba_static_dynamic_method}{\if{latex}{\out{\sloppy}} Axis separation method for ODBA/VEDBA/PDBA. Subtract a centred running mean or low-pass static component, or use high-pass-filtered axes directly. These are distinct signal-processing choices.}
\item{odba_stroke_window_rule}{\if{latex}{\out{\sloppy}} Running-mean window rule: fixed three seconds; supplied custom duration; max(3, one or two supplied stroke periods); or a main-window result plus the specified sensitivity-window summaries.}
\item{odba_running_mean_window_s}{\if{latex}{\out{\sloppy}} Requested running-mean duration in seconds for custom_window_s or the main sensitivity result. fixed_3s overrides it; the resolved duration is returned in settings$odba.}
\item{odba_stroke_period_s}{\if{latex}{\out{\sloppy}} Supplied movement-cycle period in seconds for stroke-period rules; not estimated from the signal. A minimum three-second averaging window is retained.}
\item{odba_lowpass_cutoff_hz}{\if{latex}{\out{\sloppy}} Axis low-pass cutoff in Hz used only for low_pass_static_filter separation; the resulting static estimate is subtracted from the original axis.}
\item{odba_highpass_cutoff_hz}{\if{latex}{\out{\sloppy}} Axis high-pass cutoff in Hz used only for high_pass_dynamic_filter separation.}
\item{odba_filter_type}{\if{latex}{\out{\sloppy}} Separation implementation identifier; butterworth is supported. The method/cutoff/order together define the processing pipeline.}
\item{odba_filter_order}{\if{latex}{\out{\sloppy}} Butterworth order for low-/high-pass dynamic separation. The centred-running-mean method does not use this filter.}
\item{pdba_axes}{\if{latex}{\out{\sloppy}} Axis names selected for PDBA, from x, y and z. Default x/y sums their absolute dynamic components. This option does not change ODBA or VEDBA.}
\item{odba_unit}{\if{latex}{\out{\sloppy}} Output unit for ODBA/VEDBA/PDBA epoch means: mg or g. mg applies a factor of 1000.}
\item{odba_sensitivity_windows_s}{\if{latex}{\out{\sloppy}} Vector of alternative running-mean durations in seconds for the sensitivity_windows rule. Results are returned separately in settings$odba$sensitivity_summary; they do not replace the main feature values.}
\item{odba_edge_handling}{\if{latex}{\out{\sloppy}} partial_centered_window averages the available part of a centred window at the recording boundaries, rather than padding a stationary component.}
\item{odba_missing_data_policy}{\if{latex}{\out{\sloppy}} mean_na_rm omits missing values from means; it does not interpolate gaps or establish sufficient coverage.}
\item{svmg_output}{\if{latex}{\out{\sloppy}} Retained compatibility argument; the SVMGS/SVMGSEC/SVMGMEAN identifiers fix their output form.}
\item{svmg_rectify}{\if{latex}{\out{\sloppy}} Apply the absolute value to VM minus 1 g for the gravity-subtracted VM family; this differs from ENMO truncation.}
\item{svmbp_cutoffs}{\if{latex}{\out{\sloppy}} Custom lower/upper axis band-pass cutoffs in Hz for SVMBP. Named variants fix their cutoffs.}
\item{svmbp_order}{\if{latex}{\out{\sloppy}} Butterworth order for axis band-pass filtering before vector-magnitude recombination; default four with forward/reverse filtering.}
\item{svmbp_output}{\if{latex}{\out{\sloppy}} Band-pass VM aggregation: mean_mg and mean_g return epoch means; sum_mg and sum_g return sample sums; g_seconds divides the g sample sum by fs_hz. Sample sums depend on the sample count.}
\item{svmbp_nyquist_action}{\if{latex}{\out{\sloppy}} Default stop rejects an upper cutoff at or above Nyquist. Explicit clip preserves the historical adjustment to 99 percent of Nyquist.}
\item{rocam_median_s}{\if{latex}{\out{\sloppy}} Duration in seconds of the running median on the sample-to-sample triaxial acceleration-change series. Rounded to samples, raised to at least three, and made odd. No division by elapsed time is performed.}
\item{ai_noise_var}{\if{latex}{\out{\sloppy}} Mean per-axis stationary noise variance in g squared. Required by default when AI is requested; estimate with compute_ai_noise_var_from_static. An explicit zero requests no noise subtraction.}
\item{ai_noise_mode}{\if{latex}{\out{\sloppy}} Default supplied requires ai_noise_var. Explicit window_start or quiet_segments opts into estimation when ai_noise_var is NULL. The initial window must be stationary; quiet selection does not establish stationarity. Failed estimation errors rather than substituting zero. A supplied variance takes precedence.}
\item{ai_noise_window_s}{\if{latex}{\out{\sloppy}} Initial noise-window duration in seconds; used only for window_start estimation.}
\item{ai_quiet_quantile}{\if{latex}{\out{\sloppy}} Quantile strictly between zero and one for quiet_segments selection.}
\item{ai_scale}{\if{latex}{\out{\sloppy}} Absolute Activity Index in g (default) or dimensionless noise-relative Activity Index.}
\item{ai_epoch_summary}{\if{latex}{\out{\sloppy}} Sum (default) or mean of the one-second Activity Index values within each output epoch.}
\item{z_angle_output}{\if{latex}{\out{\sloppy}} mean_deg returns the epoch mean Z-angle; sd_deg returns its sample SD. Both are in degrees, using atan(z/sqrt(x^2+y^2)).}
\item{z_angle_change_median_s}{\if{latex}{\out{\sloppy}} Running-median duration in seconds applied to the Z-angle series before absolute successive differences. Rounded to an odd sample count of at least three.}
\item{z_angle_change_output}{\if{latex}{\out{\sloppy}} mean_abs_change_deg averages successive absolute differences of the smoothed Z-angle within each epoch; max_abs_change_deg returns their maximum. Neither is divided by elapsed time.}
\item{mims_filter_type}{\if{latex}{\out{\sloppy}} Filter family passed to MIMSunit::custom_mims_unit: butter (default), ellip or bessel as supported upstream. Its interpretation belongs to that implementation; select together with mims_cutoffs.}
\item{mims_cutoffs}{\if{latex}{\out{\sloppy}} Filter cutoffs in Hz; default c(0.2, 5). Use c(0.2, 10) explicitly for the altered passband.}
\item{mims_use_extrapolation}{\if{latex}{\out{\sloppy}} Logical passed to MIMSunit. TRUE enables its saturation/extrapolation step; FALSE skips that step while the upstream algorithm still interpolates to its processing grid. Does not mean extrapolating behavioural time.}
\item{mims_use_filtering}{\if{latex}{\out{\sloppy}} Logical; enable the specified internal MIMS band-pass processing. FALSE bypasses that internal filter, creating a different feature pipeline.}
\item{mims_combination}{\if{latex}{\out{\sloppy}} Axis-combination method passed to MIMSunit: sum adds axis summaries; vm combines them as a vector magnitude. The default is sum.}
\item{mims_allow_truncation}{\if{latex}{\out{\sloppy}} Logical; permit the upstream MIMS implementation to set sufficiently small summary values to zero. This is an algorithmic small-value operation, not clipping native recordings.}
\item{ag_lfe}{Retained count-specific compatibility argument. The AG selector is disabled in this summary function; this argument is not used by supported features. For counts use the separate \code{\link{accel_metric_agcounts}} function and its own parameters.}
\item{ag_preprocess}{Retained count-specific compatibility argument. The AG selector is disabled in this summary function; this argument is not used by supported features. For counts use the separate \code{\link{accel_metric_agcounts}} function and its own parameters.}
\item{ag_anchor}{Retained count-specific compatibility argument. The AG selector is disabled in this summary function; this argument is not used by supported features. For counts use the separate \code{\link{accel_metric_agcounts}} function and its own parameters.}
\item{ag_antialias_cutoff_hz}{Retained count-specific compatibility argument. The AG selector is disabled in this summary function; this argument is not used by supported features. For counts use the separate \code{\link{accel_metric_agcounts}} function and its own parameters.}
\item{ag_filter_order}{Retained count-specific compatibility argument. The AG selector is disabled in this summary function; this argument is not used by supported features. For counts use the separate \code{\link{accel_metric_agcounts}} function and its own parameters.}
\item{quiet}{\if{latex}{\out{\sloppy}} Logical; suppress optional progress/information messages. Errors remain enabled and calculations are unchanged.}
}
\value{\if{latex}{\out{\sloppy}} Resolved band-pass settings record requested and applied cutoffs, filter order, sampling rate and Nyquist handling. The summary settings also include named metric_units for plotting and a bandpass list for requested SVM band-pass pipelines. The settings list includes dynamic_range_g, dynamic_range_limits_g and dynamic_range_source (argument, metadata or unavailable). When requested, settings$mims records the resolved MIMS configuration and dependency version, and settings$ai records the noise variance, source, applicable estimation options, scale and aggregation. Unrequested feature settings are NULL. An invisible list with \code{data_wide} (time and one column per measure), \code{data_long} (time, measure, value), and \code{settings} (resolved rate, input provenance, dynamic range and selected processing details). No behavioural classification is returned. Save the complete call/settings when reproducing a pipeline; the returned settings do not enumerate every function argument.}
\details{\if{latex}{\out{\sloppy}} A feature-processing pipeline includes signal state, algorithm, filtering, sampling treatment and aggregation. The feature examples use five-second epochs; configurable alternatives are distinct pipelines. The input is sorted by timestamp for feature computation. Epochs are indexed by elapsed time from the first sample and the final partial epoch is retained. Feature-specific time anchors are retained from their implementations. Gaps are not automatically screened or repaired; inspect integrity before filtering or feature computation. MIMS requires optional MIMSunit. The AG selector is disabled in this summary function; standalone count computation is available through \code{\link{accel_metric_agcounts}}. MIMS requires a configured peak-to-peak measurement span from an explicit argument or valid metadata; no range is assumed. Activity Index requires a stationary noise variance unless estimation is explicitly selected. Optional packages are never installed during calculation.}
\seealso{\code{\link{metronautica-package}}}
\examples{
# Specify the complete feature pipeline, including aggregation and units.
library(metronautica)
path <- system.file("extdata", "example_motion.csv",
    package = "metronautica", mustWork = TRUE)
x <- parse_raw_auto(path)
configuration <- list(measures = c("VM", "ENMO", "MAD", "SVMBP_069_10"),
    epoch_s = 5, fs_hz = 100, svmbp_nyquist_action = "stop", quiet = TRUE)
five_seconds <- do.call(compute_accel_summaries,
    c(list(accel_input = x), configuration))
five_seconds$data_wide          # VM in g; ENMO, MAD and SVMBP_069_10 in mg

configuration_10s <- configuration
configuration_10s$epoch_s <- 10
ten_seconds <- do.call(compute_accel_summaries,
    c(list(accel_input = x), configuration_10s))
nrow(five_seconds$data_wide)    # 4
nrow(ten_seconds$data_wide)     # 2; aggregation is part of the pipeline

# Other built-in summaries, with an explicit noise variance for Activity Index.
# Here 0.001^2 / 2 is the variance of each stationary sine/cosine fluctuation
# used in the static tutorial; real analyses require their own noise estimate.
other <- compute_accel_summaries(x,
    measures = c("ODBA", "VEDBA", "PDBA", "SVMGS", "SVMGSEC", "SVMGMEAN",
        "ROCAM", "AI", "ZANGLE", "ZANGLE_CHANGE"),
    epoch_s = 5, odba_running_mean_window_s = 3,
    ai_noise_var = .001^2 / 2, quiet = TRUE)
head(other$data_long)
other$data_long[other$data_long$measure == "AI", ]
# Some feature implementations retain different timestamp anchors. A wide
# full join can therefore have additional rows and unpaired (NA) cells.
# Inspect each feature's timestamps before combining results by time.

# The standalone filter is a separate processing choice.
filtered <- filter_accel_tbl(x, cutoff = 10)
qc_accel_tbl(filtered)[c("n_samples", "median_dt_ms", "invalid_axis")]
# Do not prefilter x merely to request SVMBP_069_10: that feature filters axes.

# Resolved MIMS and AI settings are included when those measures are requested.
# Retain the full call and session for the complete processing record.
output_file <- tempfile(fileext = ".rds")
saveRDS(list(results = five_seconds, configuration = configuration,
    input_metadata = accel_meta(x), session = utils::sessionInfo()), output_file)
names(readRDS(output_file))
unlink(output_file)             # Remove only this example's temporary output
}

\section{Implementation}{\if{latex}{\out{\sloppy}} Implemented by \code{compute_accel_summaries} in \code{R/m_accel_summary_suite.R}. See \code{\link{implementation-guide}} for the framework and function map.}

\section{Feature identifiers}{
\if{latex}{\out{\sloppy}}
\tabular{lll}{
Identifier \tab Direct function \tab Default output \cr
VM \tab \code{\link{accel_metric_vm}} \tab Mean, g \cr
ENMO \tab \code{\link{accel_metric_enmo}} \tab Mean, mg \cr
MAD \tab \code{\link{accel_metric_mad}} \tab Mean, mg \cr
ODBA \tab \code{\link{accel_metric_odba}} \tab Mean, mg \cr
VEDBA \tab \code{\link{accel_metric_odba}} \tab Mean, mg \cr
PDBA \tab \code{\link{accel_metric_odba}} \tab Mean, mg \cr
SVMGS \tab \code{\link{accel_metric_svmg}} \tab Sample sum, g \cr
SVMGSEC \tab \code{\link{accel_metric_svmg}} \tab Integral, g seconds \cr
SVMGMEAN \tab \code{\link{accel_metric_svmg}} \tab Mean, mg \cr
SVMBP \tab \code{\link{accel_metric_svmbp}} \tab Mean, mg \cr
SVMBP_02_15 \tab \code{\link{accel_metric_svmbp}} \tab Mean, mg \cr
SVMBP_069_10 \tab \code{\link{accel_metric_svmbp}} \tab Mean, mg \cr
ROCAM \tab \code{\link{accel_metric_rocam}} \tab Mean change, g \cr
AI \tab \code{\link{accel_metric_ai}} \tab Sum of 1-s AI, g \cr
ZANGLE \tab \code{\link{accel_metric_z_angle}} \tab Mean, degrees \cr
ZANGLE_CHANGE \tab \code{\link{accel_metric_z_angle_change}} \tab Mean change, degrees \cr
MIMS \tab \code{\link{accel_metric_mims}} \tab MIMS-units per epoch \cr
}

Identifiers are case-insensitive. The SVM gravity-subtracted identifiers fix their aggregation; \code{svmg_rectify = FALSE} instead retains signed differences. SVMBP uses \code{svmbp_cutoffs}; the named variants fix their cutoffs, while \code{svmbp_output} still selects their aggregation. VM, ENMO/MAD, body-acceleration, AI and angle alternatives are specified in Arguments and their direct helpers. There are 17 accepted identifiers including the configurable SVMBP selector. Counts use the standalone \code{\link{accel_metric_agcounts}} function; AG is not an available selector.
}

\section{Epoch timestamps and joins}{
\if{latex}{\out{\sloppy}}
Sample-level features use elapsed-time bins from the first sample and select the first, last or middle observed sample as their label. AI first computes one-second indices and selects among their bin-start timestamps. MIMS retains upstream timestamps and epoch behaviour. Consequently the same nominal epoch duration does not guarantee identical timestamps across features.

\code{data_long} retains each feature's own timestamp/value pairs. \code{data_wide} is a full join on exact timestamps: different labels create separate rows and unpaired NA cells, even when each feature has the same number of epochs. With 20 seconds at 100 Hz and five-second center-labelled epochs, ENMO labels are 2.49, 7.49, 12.49 and 17.49 seconds after the first sample; AI labels are 2, 7, 12 and 17 seconds. Their wide join therefore has eight rows. Inspect labels and interval definitions before aligning or combining features. Do not interpret every unpaired cell as missing acceleration or replace it with zero. The function does not harmonise these anchors.
}
