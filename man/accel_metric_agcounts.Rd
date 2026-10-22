\name{accel_metric_agcounts}
\alias{accel_metric_agcounts}
\title{Compute ActiGraph-compatible or modified activity counts}
\description{\if{latex}{\out{\sloppy}} Standalone activity-count calculation with the published coefficient-defined ActiGraph filter by default, explicit custom bandpass cutoffs, and auditable treatment of missing samples and boundaries.}
\usage{
accel_metric_agcounts(tbl, epoch_s = 1, fs_hz,
    lower_hz = NULL, upper_hz = NULL, filter_order = 4,
    lfe = FALSE, gap_policy = c("error", "zero", "carry_forward"),
    vm_round = TRUE, start_time = NULL, end_time = NULL,
    boundary = c("error", "pad"), pad_value = NULL,
    filter_guard_s = 60)
}
\arguments{
\item{tbl}{\if{latex}{\out{\sloppy}} Common-format data frame/tibble, parser bundle with data, or clip bundle with full. Required columns are POSIXct time and finite numeric ax_g, ay_g, az_g in \eqn{g}. Rows must be strictly time ordered on the supplied nominal sampling grid. Observed zero-valued samples are retained as observations.}
\item{epoch_s}{\if{latex}{\out{\sloppy}} Positive whole epoch duration in seconds. Axis counts are accumulated first; vector magnitude is calculated afterwards. Incomplete trailing raw epochs are discarded before rate conversion and the discarded sample count is recorded.}
\item{fs_hz}{\if{latex}{\out{\sloppy}} Nominal recording frequency in Hz, supplied explicitly. Supported rates are 30, 40, 50, 60, 70, 80, 90, 100, 32, 64, 128 and 256 Hz. A frequency estimated across recording gaps is not a substitute for the acquisition setting.}
\item{lower_hz,upper_hz}{\if{latex}{\out{\sloppy}} Both NULL retain the exact published filter coefficients; a nominal cutoff pair is not substituted for that response. Supplying both selects a modified causal Butterworth bandpass. These custom frequencies are the lower and upper -3-dB points, satisfying 0 < lower_hz < upper_hz < min(15, fs_hz/2). The historical internal processing rate is 30 Hz.}
\item{filter_order}{\if{latex}{\out{\sloppy}} Butterworth prototype order, integer 1 to 8; the bandpass transfer function has twice this order. Default 4. Ignored for the published filter, whose coefficient-defined order remains unchanged. Numerically unstable custom designs are rejected. Custom peak gain is matched to the published filter; subsequent historical scaling and count operations are retained.}
\item{lfe}{\if{latex}{\out{\sloppy}} FALSE uses the Normal-filter threshold rule: rectify, suppress values below 4, saturate at 128 and floor. TRUE selects the published low-frequency-extension threshold rule: suppress values below 1, use floor(value)-1 for 1 <= value < 4, and otherwise floor after saturation at 128. This changes the threshold rule, not the bandpass coefficients. Available real-data AGD validation used FALSE.}
\item{gap_policy}{\if{latex}{\out{\sloppy}} Default error rejects unobserved interior sample positions. zero inserts zero acceleration, while carry_forward repeats the last observed triaxial sample. These are explicit computational conventions, not evidence of the missing physical acceleration. NA/Inf axis values are rejected, not automatically reinterpreted as gaps.}
\item{vm_round}{\if{latex}{\out{\sloppy}} TRUE rounds sqrt(Axis1 squared + Axis2 squared + Axis3 squared) to the nearest integer, as in the R comparison implementation. FALSE retains the unrounded vector magnitude. Summing one-second vector magnitudes is not equivalent to accumulating axes before taking their magnitude.}
\item{start_time,end_time}{\if{latex}{\out{\sloppy}} Optional single POSIXct interval bounds; start is inclusive and end exclusive. Defaults are the first supplied sample and one nominal sample interval after the last. Epochs start at the resolved start_time, without implicit rounding to a civil-clock boundary. Native recording start and first observed sample are recorded separately when parser metadata is available. Process a continuous interval before selecting derived epochs when filter history is required.}
\item{boundary}{\if{latex}{\out{\sloppy}} Default error rejects requested bounds extending beyond observed coverage. pad permits only explicitly requested leading/trailing sample padding, with pad_value required. The function never automatically extends to a native header's start/stop time. Padding does not establish vendor compatibility.}
\item{pad_value}{\if{latex}{\out{\sloppy}} Three finite acceleration values in \eqn{g} for X, Y, Z, used only with boundary = "pad". Both requested ends use these explicit values. The number and location of padded samples are reported. No constant-first-sample startup padding is inserted implicitly.}
\item{filter_guard_s}{\if{latex}{\out{\sloppy}} Non-negative flagging interval after an imputed sample or initialisation, default 60 seconds. Power-of-two conversion additionally flags the preceding second around imputation and the final second of finite-record processing because its FIR stage is centred. This changes flags only, not counts. It is a user-selected processing-context guard, not a validated settling-time guarantee or measurement uncertainty bound; very low custom cutoffs can require a longer guard.}
}
\value{\if{latex}{\out{\sloppy}} A tibble with time, Axis1 (input Y), Axis2 (input X), Axis3 (input Z), Vector.Magnitude and value (the same vector magnitude). Additional columns input_samples, missing_samples and padded_samples count nominal positions within each output epoch. imputed identifies epochs containing inserted values; affected_by_imputation also includes the filter guard; boundary_affected identifies initialisation/finite-record context. These flags describe insertions by this count call, not values imputed before input was supplied. Counts are not replaced by NA when an explicit fill policy is chosen: inspect these flags before interpretation. The settings attribute records the reference, exact coefficients, filter choice, precision provenance where available, interval, gaps, padding, discarded samples, rounding and quality conventions.}
\details{\if{latex}{\out{\sloppy}} The published path converts each axis to 30 Hz using the rate-specific historical method, including the separate power-of-two path; rounds the converted acceleration to three decimals; applies the coefficient-defined causal filter with steady-state initialisation; rescales by (3/4096)/(2.6/256) times 237.5; rectifies, thresholds, saturates and quantises; averages and floors groups of three samples to 10 Hz; then accumulates epochs. Published finite-record behaviour of the power-of-two converter is retained. Custom filtering replaces only the bandpass stage. It is identified as modified counts and does not inherit validation of published behavioural thresholds.

The implementation uses supplied acceleration precision without reconstructing discarded digits. For GT3X inputs, parse_raw_auto uses native precision by default; precision = "legacy_3dp" explicitly retains the earlier read.gt3x rounded conversion. A manually rounded table remains rounded. Source timestamps and gaps are not repaired by parsing.

This function is available separately from compute_accel_summaries. The AG selector remains disabled, so existing summary pipelines are not silently changed. Neither agcounts nor Python is a runtime dependency.}
\section{Validation scope}{The original experiment included 89 native/AGD recording pairs: 45 static recordings tested in three 30-minute windows each and 44 secondary-shaker recordings over available raw coverage. The default matched the pinned official Python calculation exactly for 3,763,659 paired one-second axis values. Exact ActiLife export reproduction additionally depended on native precision, startup context and missing-sample conventions; it was not universal across all recording transitions. This is calculation validation, not validation of device interchangeability or behavioural thresholds. The package documentation includes the full agreement and coverage tables.}
\references{Neishabouri et al. (2022). Quantification of acceleration as activity counts in ActiGraph wearable. Scientific Reports 12, 11958. \doi{10.1038/s41598-022-16003-x}.

Published coefficients: ActiGraph/agcounts, GPL-3.0, commit 3137c9b9a26539ae2d9645d396586fe15faece59. \url{https://github.com/actigraph/agcounts}. Numerical coefficients are acknowledged from that source; the R implementation is provided by Metronautica.}
\examples{
fs <- 100
t <- (0:5999) / fs
x <- data.frame(time = as.POSIXct("2025-01-01", tz = "UTC") + t,
    ax_g = 0.5 * sin(2*pi*2*t), ay_g = 0.2 * cos(2*pi*t),
    az_g = rep(1, length(t)))
counts <- accel_metric_agcounts(x, epoch_s = 5, fs_hz = fs)
head(counts)
attr(counts, "settings")$filter
modified <- accel_metric_agcounts(x, epoch_s = 5, fs_hz = fs,
    lower_hz = 0.69, upper_hz = 10)
attr(modified, "settings")$algorithm
}
\seealso{\code{\link{parse_raw_auto}}, \code{\link{qc_accel_tbl}}, \code{\link{compute_accel_summaries}}}
\section{Implementation}{Implemented in R/m_agcounts.R. Standalone count calculation.}
