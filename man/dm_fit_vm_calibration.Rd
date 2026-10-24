\name{dm_fit_vm_calibration}
\alias{dm_fit_vm_calibration}
\title{Fit a reference-based vector-magnitude calibration}
\description{\if{latex}{\out{\sloppy}} Select a linear or quadratic mapping between paired test/reference VM values.}
\usage{
dm_fit_vm_calibration(test_clips, ref_clips, window_s = 5, select_by
    = c("AIC", "AICc", "BIC", "linear"), fit_unit = c("window",
    "sample"), direction = c("ref_on_test", "test_on_ref"))
}
\arguments{
\item{test_clips}{\if{latex}{\out{\sloppy}} Test-device stage bundle returned by \code{clip_dynamic_stages}.}
\item{ref_clips}{\if{latex}{\out{\sloppy}} Reference-device stage bundle with matching stage names.}
\item{window_s}{\if{latex}{\out{\sloppy}} Paired-VM averaging-bin duration (s) for fit_unit = window; unused for sample fitting.}
\item{select_by}{\if{latex}{\out{\sloppy}} Select the linear or quadratic candidate using AIC, corrected AIC (AICc), or BIC; \code{"linear"} forces the linear candidate.}
\item{fit_unit}{\if{latex}{\out{\sloppy}} Fit paired window-mean or sample VM. Pairing follows stage/sample-index rules, without timestamp alignment.}
\item{direction}{\if{latex}{\out{\sloppy}} ref_on_test maps test to reference VM for application. test_on_ref reverses the regression for inspection only; do not apply it as a correction.}
}
\value{\if{latex}{\out{\sloppy}} A list with summary (one-row coefficients/model-selection results), fit_linear and fit_quadratic (lm objects), chosen_fit and pairs (test_vm/reference_vm fitting data). Insufficient pairs yield no fitted model and NA coefficients; application rejects those coefficients.}
\seealso{\if{latex}{\out{\sloppy}} \href{https://github.com/miltheo/metronautica/blob/main/examples/calibration.R}{Calibration example}, \code{\link{dm_apply_vm_calibration_tbl}}, \code{\link{dm_apply_vm_calibration_bundle}}}

\section{Method}{\if{latex}{\out{\sloppy}} Pair matched-stage VM using evenly spaced sample indices. Fit linear/quadratic candidates in the requested direction and select by criterion, or force linear. Within-recording fitting requires independent validation; apply only ref_on_test coefficients.}

\examples{
path <- system.file("extdata", "example_motion.csv",
    package = "metronautica", mustWork = TRUE)
x <- parse_raw_auto(path)
reference <- x
reference[c("ax_g", "ay_g", "az_g")] <-
    1.1 * reference[c("ax_g", "ay_g", "az_g")]
stage <- function(x) list(full = x, stages = list(rpm_50 = x))
fit <- dm_fit_vm_calibration(stage(x), stage(reference),
    select_by = "linear", fit_unit = "sample")
fit$summary
}
