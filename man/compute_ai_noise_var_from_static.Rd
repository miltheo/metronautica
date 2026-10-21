\name{compute_ai_noise_var_from_static}
\alias{compute_ai_noise_var_from_static}
\title{Estimate stationary variance for the Activity Index}
\description{\if{latex}{\out{\sloppy}} Estimate stationary variance for the Activity Index.}
\usage{
compute_ai_noise_var_from_static(x, window_s = 1, fs_hz = NULL,
    use_middle_prop = 1)
}
\arguments{
\item{x}{\if{latex}{\out{\sloppy}} Acceleration data frame/tibble with POSIXct time and numeric ax_g, ay_g, az_g in g, or a parser/clip bundle containing data/full and optional meta. The data attribute takes precedence over bundle metadata. No samples are repaired by input conversion.}
\item{window_s}{\if{latex}{\out{\sloppy}} Duration in seconds of each non-overlapping stationary noise window. round(fs_hz * window_s) must be at least two samples. Axis sample variances are averaged within each window, then across retained complete windows.}
\item{fs_hz}{\if{latex}{\out{\sloppy}} NULL derives Hz from the median finite positive timestamp interval; otherwise use the supplied finite positive Hz to convert window_s to samples.}
\item{use_middle_prop}{\if{latex}{\out{\sloppy}} Fraction in (0, 1] of the central recording retained before windowing. One uses the complete supplied interval; 0.8 selects its middle 80 percent. No stationarity is inferred.}
}
\value{\if{latex}{\out{\sloppy}} A list with ai_noise_var (mean per-axis stationary variance, g squared), ai_noise_sd (its square root, g), window_values (per-window variances), n_windows, fs_hz and window_s. Trailing incomplete sample windows are discarded. No finite estimates or fewer than two samples per window raises an error.}
\seealso{\code{\link{metronautica-package}}}

\section{Method}{\if{latex}{\out{\sloppy}} For every complete stationary window calculate (var(x)+var(y)+var(z))/3 using sample variances. Average these window variances for the Activity Index noise correction. The estimate differs from the manuscript maximum-axis detrended noise floor. The supported table/bundle forms feed the same calculation; no calibration, detrending or stationarity detection is added.}

\section{Implementation}{\if{latex}{\out{\sloppy}} Implemented by \code{compute_ai_noise_var_from_static} in \code{R/m_accel_summary_suite.R}. See \code{\link{implementation-guide}} for the framework and manuscript mapping.}

\examples{
seconds <- (0:5999) / 100
x <- as_accel_tbl(as.POSIXct("2026-01-01", tz = "UTC") + seconds,
    .001 * sin(2*pi*7*seconds), .001 * cos(2*pi*7*seconds),
    1 + .001 * sin(2*pi*11*seconds))
noise <- compute_ai_noise_var_from_static(list(data = x), window_s = 1)
noise[c("ai_noise_var", "ai_noise_sd", "n_windows")]
}
