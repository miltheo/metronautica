\name{dm_fit_vm_calibration}
\alias{dm_fit_vm_calibration}
\title{Fit a reference-based vector-magnitude calibration}
\description{\if{latex}{\out{\sloppy}} Fit a reference-based vector-magnitude calibration.}
\usage{
dm_fit_vm_calibration(test_clips, ref_clips, window_s = 5, select_by
    = c("AIC", "AICc", "BIC", "linear"), fit_unit = c("window",
    "sample"), direction = c("ref_on_test", "test_on_ref"))
}
\arguments{
\item{test_clips}{\if{latex}{\out{\sloppy}} Test-device stage bundle returned by \code{clip_dynamic_stages}.}
\item{ref_clips}{\if{latex}{\out{\sloppy}} Reference-device stage bundle with matching stage names.}
\item{window_s}{\if{latex}{\out{\sloppy}} Duration in seconds of paired-VM averaging bins when fit_unit is window. Index-paired samples are averaged before fitting. Unused for fit_unit = sample.}
\item{select_by}{\if{latex}{\out{\sloppy}} Select the linear or quadratic candidate using AIC, corrected AIC (AICc), or BIC; \code{"linear"} forces the linear candidate.}
\item{fit_unit}{\if{latex}{\out{\sloppy}} window fits paired epoch-mean VM values; sample fits the paired sample values. Pairing is by existing stage/sample-index rules and is not timestamp alignment.}
\item{direction}{\if{latex}{\out{\sloppy}} ref_on_test fits reference VM as a function of test VM, producing coefficients suitable for application. test_on_ref reverses the regression for inspection and must not be applied as a test-to-reference correction.}
}
\value{\if{latex}{\out{\sloppy}} A list with summary (one-row coefficients/model-selection results), fit_linear and fit_quadratic (lm objects), chosen_fit and pairs (test_vm/reference_vm fitting data). Insufficient pairs yield no fitted model and NA coefficients; application rejects those coefficients.}
\seealso{\code{\link{metronautica-package}}}

\section{Method}{\if{latex}{\out{\sloppy}} Form VM from each matched stage and pair reference observations using the retained evenly spaced sample-index rule. Fit linear and quadratic candidates in the requested regression direction; select by the supplied criterion or force linear. This is within-recording fitted calibration, not independent validation. Apply only ref_on_test coefficients to test recordings.}

\section{Implementation}{\if{latex}{\out{\sloppy}} Implemented by \code{dm_fit_vm_calibration} in \code{R/m_dynamic.R}. See \code{\link{implementation-guide}} for the framework and function map.}

\examples{
t0 <- as.POSIXct("2026-01-01", tz = "UTC")
seconds <- (0:5999) / 100
test_vm <- 1 + .2 * sin(2 * pi * .17 * seconds) + .003 * seconds
meta <- list(acquisition = list(fs_derived_hz = 100,
    full_scale_range_g = 16))
test <- as_accel_tbl(t0 + seconds, rep(0, 6000), rep(0, 6000),
    test_vm, meta)
reference <- as_accel_tbl(t0 + seconds, rep(0, 6000), rep(0, 6000),
    .02 + 1.1 * test_vm, meta)
stage <- function(x) list(full = x, stages = list(rpm_50 = x),
    meta = accel_meta(x))
fit <- dm_fit_vm_calibration(stage(test), stage(reference),
    select_by = "linear", fit_unit = "window", window_s = 5)
fit$summary[, c("vm_calibration_intercept", "vm_calibration_slope")]
calibrated <- dm_apply_vm_calibration_tbl(attach_qc(test), fit$summary)
is.null(accel_meta(calibrated)$processing$qc)  # Previous QC was removed
calibrated <- attach_qc(calibrated)           # Diagnostics for changed signal
accel_meta(calibrated)$processing$signal_pipeline
}
