\name{accel_metric_ai}
\alias{accel_metric_ai}
\title{Compute Activity Index}
\description{\if{latex}{\out{\sloppy}} Compute Activity Index.}
\usage{
accel_metric_ai(tbl, epoch_s, fs_hz, anchor = "center", ai_noise_var
    = NULL, ai_noise_mode = c("supplied", "window_start",
    "quiet_segments"),
    ai_noise_window_s = 30, ai_quiet_quantile = 0.1, ai_scale =
    c("absolute", "relative"), ai_epoch_summary = c("sum", "mean"))
}
\arguments{
\item{tbl}{\if{latex}{\out{\sloppy}} Acceleration data frame/tibble with POSIXct time and numeric ax_g, ay_g, az_g in g, or a parser/clip bundle containing data/full. Input conversion preserves values and metadata.}
\item{epoch_s}{\if{latex}{\out{\sloppy}} Positive output-epoch duration in seconds. Samples are grouped by elapsed time from the first sample; the final partial epoch is retained. Different epoch lengths define different processing pipelines.}
\item{fs_hz}{\if{latex}{\out{\sloppy}} Sampling frequency in Hz. Used to convert durations to sample windows or sums to time integrals. Supply one finite positive scalar. A NULL estimate is available only where shown in Usage.}
\item{anchor}{\if{latex}{\out{\sloppy}} Output timestamp selected from the one-second bin starts: first for start, last for end, or the middle bin start (ceiling of half the bin count) for center. This differs from sample-level anchors of ENMO/MAD and does not change the calculated values.}
\item{ai_noise_var}{\if{latex}{\out{\sloppy}} Mean per-axis stationary noise variance in g squared. Required by default when AI is requested; estimate with compute_ai_noise_var_from_static. An explicit zero requests no noise subtraction.}
\item{ai_noise_mode}{\if{latex}{\out{\sloppy}} Default supplied requires ai_noise_var. Explicit window_start or quiet_segments opts into estimation when ai_noise_var is NULL. The initial window must be stationary; quiet selection does not establish stationarity. Failed estimation errors rather than substituting zero. A supplied variance takes precedence.}
\item{ai_noise_window_s}{\if{latex}{\out{\sloppy}} Initial noise-window duration in seconds; used only for window_start estimation.}
\item{ai_quiet_quantile}{\if{latex}{\out{\sloppy}} Quantile strictly between zero and one for quiet_segments selection.}
\item{ai_scale}{\if{latex}{\out{\sloppy}} Absolute Activity Index in g (default) or dimensionless noise-relative Activity Index.}
\item{ai_epoch_summary}{\if{latex}{\out{\sloppy}} Sum (default) or mean of the one-second Activity Index values within each output epoch.}
}
\value{A tibble with \code{epoch_id}, \code{time} and \code{value}. Absolute output is in g; relative output is dimensionless. Sum and mean refer to the one-second indices, not acceleration samples. Timestamps select the first, last or middle one-second bin start within each output epoch. The \code{settings} attribute records noise variance/source, estimation settings, scale, aggregation, rate and duration; \code{ai_noise_var_used} also records the variance in g squared.}

\details{\if{latex}{\out{\sloppy}} Calculate sample variance per axis within one-second windows, average the three variances, subtract the stationary mean-axis noise variance, truncate negative excess to zero and take the square root. The absolute index is in g. Relative scaling divides excess variance by noise variance before the square root; zero noise variance gives undefined relative values. Aggregate the one-second indices by the selected sum or mean. See \code{\link{measurement-definitions}} for calculation definitions. No additional device calibration is performed by choosing a feature.}
\seealso{\code{\link{metronautica-package}}}

\section{Implementation}{\if{latex}{\out{\sloppy}} Implemented by \code{accel_metric_ai} in \code{R/m_accel_summary_suite.R}. See \code{\link{implementation-guide}} for the framework and function map.}

\references{Bai et al. (2016), \doi{10.1371/journal.pone.0160644}.}
