\name{accel_metric_agcounts}
\alias{accel_metric_agcounts}
\title{Compute ActiGraph-compatible or modified activity counts}
\description{\if{latex}{\out{\sloppy}} Standalone published-filter activity counts, with optional custom band-pass cutoffs and explicit gap/boundary handling.}
\usage{
accel_metric_agcounts(tbl, epoch_s = 1, fs_hz,
    lower_hz = NULL, upper_hz = NULL, filter_order = 4,
    lfe = FALSE, gap_policy = c("error", "zero", "carry_forward"),
    vm_round = TRUE, start_time = NULL, end_time = NULL,
    boundary = c("error", "pad"), pad_value = NULL,
    filter_guard_s = 60)
}
\arguments{
\item{tbl}{\if{latex}{\out{\sloppy}} Acceleration table or data/full bundle with POSIXct time and finite numeric ax_g, ay_g, az_g (\eqn{g}). Requires strict timestamp order on the nominal sampling grid; observed zero samples are retained.}
\item{epoch_s}{\if{latex}{\out{\sloppy}} Positive whole-second epoch duration. Accumulate axes before VM calculation. Discard incomplete trailing raw epochs before rate conversion; record discarded sample count.}
\item{fs_hz}{\if{latex}{\out{\sloppy}} Explicit nominal recording rate (Hz): 30, 40, 50, 60, 70, 80, 90, 100, 32, 64, 128 or 256. Gap-spanning timestamp estimates cannot substitute for acquisition settings.}
\item{lower_hz,upper_hz}{\if{latex}{\out{\sloppy}} Both NULL retain exact published coefficients, rather than substituting nominal cutoffs. Supplying both selects modified causal Butterworth filtering with -3-dB edges satisfying 0 < lower_hz < upper_hz < min(15, fs_hz/2). Internal processing remains 30 Hz.}
\item{filter_order}{\if{latex}{\out{\sloppy}} Custom Butterworth prototype order, integer 1--8 (default 4); ignored for the published filter. See Calculation stages in the counts guide for transfer order and gain matching.}
\item{lfe}{\if{latex}{\out{\sloppy}} Enable the published low-frequency-extension threshold rule (default FALSE), without changing filter coefficients. Quantisation rules are in the counts guide.}
\item{gap_policy}{\if{latex}{\out{\sloppy}} error (default) rejects missing interior sample positions; zero inserts zero acceleration; carry_forward repeats the last observed triaxial sample. Fill values are computational conventions, not measured missing acceleration. NA/Inf axes error rather than becoming gaps.}
\item{vm_round}{\if{latex}{\out{\sloppy}} TRUE rounds sqrt(Axis1 squared + Axis2 squared + Axis3 squared) to the nearest integer, matching the R comparator; FALSE retains unrounded VM. Summing one-second VM differs from accumulating axes before VM calculation.}
\item{start_time,end_time}{\if{latex}{\out{\sloppy}} Single POSIXct bounds, inclusive start/exclusive end; defaults: first sample and last sample plus one nominal interval. Epochs begin at resolved start_time without civil-clock rounding. Metadata distinguishes native start from first observation. Process continuous input before selecting epochs when filter history matters.}
\item{boundary}{\if{latex}{\out{\sloppy}} error (default) rejects bounds beyond coverage; pad permits explicitly requested end padding with required pad_value. Native-header bounds are never applied automatically; padding does not establish vendor compatibility.}
\item{pad_value}{\if{latex}{\out{\sloppy}} Three finite X/Y/Z accelerations (\eqn{g}) for boundary = "pad", used at both requested ends. Padding counts/locations are reported; no implicit constant-first-sample startup padding.}
\item{filter_guard_s}{\if{latex}{\out{\sloppy}} Non-negative flagging interval after imputation/initialisation (default 60 s). Centred-FIR power-of-two conversion also flags the second before imputation and the final processing second. Flags do not change counts. This context guard is not a validated settling time or uncertainty bound; lower custom cutoffs may need longer guards.}
}
\value{\if{latex}{\out{\sloppy}} Tibble: time, Axis1 (input Y), Axis2 (input X), Axis3 (input Z), Vector.Magnitude and value (same VM). Per-epoch input_samples, missing_samples and padded_samples count nominal positions; imputed marks inserted values; affected_by_imputation includes the filter guard; boundary_affected marks initialisation/finite-record context. Flags concern this call, not prior imputation. Explicit fill policies retain counts rather than NA; inspect flags before interpretation.

The settings attribute records reference, exact coefficients, filter, available precision provenance, interval, gaps, padding, discarded samples, rounding and quality conventions.}
\details{\if{latex}{\out{\sloppy}} Defaults use the published coefficient-defined filter. Custom cutoffs replace only that stage and produce modified counts, without inherited behavioural-threshold validation. \href{https://github.com/miltheo/metronautica/blob/main/docs/ACTIGRAPH_COUNTS.md#calculation-stages}{Calculation stages and validation} documents rate conversion, quantisation, precision, boundary effects and agreement results.}
\section{Validation scope}{\if{latex}{\out{\sloppy}} Default axis counts matched the pinned Python reference exactly for 3,763,659 paired one-second values. ActiLife export agreement depends on precision, startup context and gaps; see the \href{https://github.com/miltheo/metronautica/blob/main/docs/ACTIGRAPH_COUNTS.md#original-experimental-validation}{validation guide}.}
\references{\if{latex}{\out{\sloppy}} Neishabouri et al. (2022). Quantification of acceleration as activity counts in ActiGraph wearable. Scientific Reports 12, 11958. \doi{10.1038/s41598-022-16003-x}.

Published coefficients: ActiGraph/agcounts, GPL-3.0, commit 3137c9b9a26539ae2d9645d396586fe15faece59. \url{https://github.com/actigraph/agcounts}. Numerical coefficients are acknowledged from that source; the R implementation is provided by Metronautica.}
\examples{
path <- system.file("extdata", "example_motion.csv",
    package = "metronautica", mustWork = TRUE)
x <- parse_raw_auto(path)
counts <- accel_metric_agcounts(x, epoch_s = 5, fs_hz = 100)
head(counts)
}
\seealso{\code{\link{parse_raw_auto}}, \code{\link{qc_accel_tbl}}, \code{\link{compute_accel_summaries}}}
