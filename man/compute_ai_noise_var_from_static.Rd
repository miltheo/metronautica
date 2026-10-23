\name{compute_ai_noise_var_from_static}
\alias{compute_ai_noise_var_from_static}
\title{Estimate stationary variance for the Activity Index}
\description{\if{latex}{\out{\sloppy}} Mean-axis sample variance across complete stationary windows.}
\usage{
compute_ai_noise_var_from_static(x, window_s = 1, fs_hz = NULL,
    use_middle_prop = 1)
}
\arguments{
\item{x}{\if{latex}{\out{\sloppy}} Acceleration table or parser/clip bundle; see \code{\link{common-data-format}}.}
\item{window_s}{\if{latex}{\out{\sloppy}} Non-overlapping window duration (s); round(fs_hz * window_s) must be at least two samples. Average axis sample variances within windows, then across complete windows.}
\item{fs_hz}{\if{latex}{\out{\sloppy}} NULL derives Hz from the median finite positive timestamp interval; otherwise use the supplied finite positive Hz to convert window_s to samples.}
\item{use_middle_prop}{\if{latex}{\out{\sloppy}} Central fraction retained before windowing, in (0, 1]: 1 uses all input; 0.8 uses the middle 80 percent. Stationarity is not tested.}
}
\value{\if{latex}{\out{\sloppy}} A list with ai_noise_var (mean per-axis stationary variance, \eqn{g} squared), ai_noise_sd (its square root, \eqn{g}), window_values (per-window variances), n_windows, fs_hz and window_s. Trailing incomplete sample windows are discarded. No finite estimates or fewer than two samples per window raises an error.}
\seealso{\code{\link{accel_metric_ai}}, \code{\link{static_axis_noise_metrics}}}

\section{Method}{\if{latex}{\out{\sloppy}} Average (var(x)+var(y)+var(z))/3 across complete windows for AI noise correction. Unlike the maximum-axis noise floor, this uses sample variances without detrending. No calibration or stationarity detection is performed.}

\examples{
seconds <- (0:5999) / 100
x <- as_accel_tbl(as.POSIXct("2026-01-01", tz = "UTC") + seconds,
    .001 * sin(2*pi*7*seconds), .001 * cos(2*pi*7*seconds),
    1 + .001 * sin(2*pi*11*seconds))
noise <- compute_ai_noise_var_from_static(list(data = x), window_s = 1)
noise[c("ai_noise_var", "ai_noise_sd", "n_windows")]
}
