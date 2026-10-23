\name{accel_metric_ai}
\alias{accel_metric_ai}
\title{Compute Activity Index}
\description{\if{latex}{\out{\sloppy}} Noise-adjusted one-second Activity Index, aggregated by epoch.}
\usage{
accel_metric_ai(tbl, epoch_s, fs_hz, anchor = "center", ai_noise_var
    = NULL, ai_noise_mode = c("supplied", "window_start",
    "quiet_segments"),
    ai_noise_window_s = 30, ai_quiet_quantile = 0.1, ai_scale =
    c("absolute", "relative"), ai_epoch_summary = c("sum", "mean"))
}
\arguments{
\item{tbl}{\if{latex}{\out{\sloppy}} Acceleration table or parser/clip bundle; see \code{\link{common-data-format}}.}
\item{epoch_s}{\if{latex}{\out{\sloppy}} Positive epoch duration (s); boundaries follow the common data format.}
\item{fs_hz}{\if{latex}{\out{\sloppy}} Finite positive sampling frequency (Hz), used for sample windows or time integrals.}
\item{anchor}{\if{latex}{\out{\sloppy}} Output timestamp selected from the one-second bin starts: first for start, last for end, or the middle bin start (ceiling of half the bin count) for center. This differs from sample-level anchors of ENMO/MAD and does not change the calculated values.}
\item{ai_noise_var}{\if{latex}{\out{\sloppy}} Mean-axis stationary noise variance (\eqn{g} squared), required by default for AI; estimate with \code{\link{compute_ai_noise_var_from_static}}. Zero disables noise subtraction.}
\item{ai_noise_mode}{\if{latex}{\out{\sloppy}} supplied (default) requires ai_noise_var. With NULL variance, window_start or quiet_segments enables estimation; supplied variance takes precedence. The initial window must be stationary; quiet selection does not prove stationarity. Failed estimation errors, without substituting zero.}
\item{ai_noise_window_s}{\if{latex}{\out{\sloppy}} Initial noise-window duration (s), for window_start only.}
\item{ai_quiet_quantile}{\if{latex}{\out{\sloppy}} quiet_segments selection quantile, strictly between zero and one.}
\item{ai_scale}{\if{latex}{\out{\sloppy}} Absolute Activity Index in \eqn{g} (default) or dimensionless noise-relative Activity Index.}
\item{ai_epoch_summary}{\if{latex}{\out{\sloppy}} Epoch sum (default) or mean of one-second Activity Index values.}
}
\value{\if{latex}{\out{\sloppy}} A tibble with \code{epoch_id}, \code{time} and \code{value}. Absolute output is in \eqn{g}; relative output is dimensionless. Sum/mean aggregate one-second indices, not acceleration samples. The \code{settings} attribute records noise variance/source, estimation settings, scale, aggregation, rate and duration; \code{ai_noise_var_used} also records the variance in \eqn{g} squared.}

\details{\if{latex}{\out{\sloppy}} Calculate sample variance per axis within one-second windows, average the three variances, subtract the stationary mean-axis noise variance, truncate negative excess to zero and take the square root. The absolute index is in \eqn{g}. Relative scaling divides excess variance by noise variance before the square root; zero noise variance gives undefined relative values. Aggregate the one-second indices by the selected sum or mean.}
\seealso{\code{\link{compute_accel_summaries}}}

\references{Bai et al. (2016), \doi{10.1371/journal.pone.0160644}.}
