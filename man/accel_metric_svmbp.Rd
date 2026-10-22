\name{accel_metric_svmbp}
\alias{accel_metric_svmbp}
\title{Compute band-pass vector magnitude}
\description{\if{latex}{\out{\sloppy}} Compute band-pass vector magnitude.}
\usage{
accel_metric_svmbp(tbl, epoch_s, fs_hz, anchor = "center",
    cutoffs_hz = c(0.2, 15), order = 4, output = c("mean_mg",
    "mean_g", "sum_mg", "sum_g", "g_seconds"), nyquist_action =
    c("stop", "clip"), quiet = FALSE)
}
\arguments{
\item{tbl}{\if{latex}{\out{\sloppy}} Acceleration data frame/tibble with POSIXct time and numeric ax_g, ay_g, az_g in \eqn{g}, or a parser/clip bundle containing data/full. Input conversion preserves values and metadata.}
\item{epoch_s}{\if{latex}{\out{\sloppy}} Positive output-epoch duration in seconds. Samples are grouped by elapsed time from the first sample; the final partial epoch is retained. Different epoch lengths define different processing pipelines.}
\item{fs_hz}{\if{latex}{\out{\sloppy}} Sampling frequency in Hz. Used to convert durations to sample windows or sums to time integrals. Supply one finite positive scalar. A NULL estimate is available only where shown in Usage.}
\item{anchor}{\if{latex}{\out{\sloppy}} Output timestamp: start selects the first observed sample in an epoch, end the last, and center the middle observed sample (ceiling of half the epoch sample count). This labels the result without changing values.}
\item{cutoffs_hz}{\if{latex}{\out{\sloppy}} Lower and upper axis band-pass cutoffs in Hz, applied before vector-magnitude recombination. The upper cutoff must lie below fs_hz/2 unless clipping is explicitly selected.}
\item{order}{\if{latex}{\out{\sloppy}} Butterworth order for axis band-pass filtering before vector-magnitude recombination; default four with forward/reverse filtering.}
\item{output}{\if{latex}{\out{\sloppy}} Band-pass VM aggregation: mean_mg and mean_g return epoch means; sum_mg and sum_g return sample sums; g_seconds divides the \eqn{g} sample sum by fs_hz. Sample sums depend on the sample count.}
\item{nyquist_action}{\if{latex}{\out{\sloppy}} Default stop rejects an upper cutoff at or above Nyquist. Explicit clip preserves the historical adjustment to 99 percent of Nyquist.}
\item{quiet}{\if{latex}{\out{\sloppy}} Logical; suppress optional progress/information messages. Errors remain enabled and calculations are unchanged.}
}
\value{A tibble with \code{time}, \code{epoch_id} and \code{value}. Units are m\eqn{g}/\eqn{g} for means, m\eqn{g}/\eqn{g} sample sums for sum_mg/sum_g, or \eqn{g} seconds for g_seconds. The \code{settings} attribute records requested/applied cutoffs, filter order, sampling frequency, Nyquist policy, output aggregation, epoch duration and anchor.}

\details{\if{latex}{\out{\sloppy}} Filter each acceleration axis using signal::butter and forward/reverse filtfilt, recombine the filtered axes as VM, then aggregate. The requested and actual passband are retained. This is distinct from filtering the already-combined VM or from the compensated standalone filter. See \code{\link{measurement-definitions}} for calculation definitions. No additional device calibration is performed by choosing a feature.}
\seealso{\code{\link{metronautica-package}}}

\section{Implementation}{\if{latex}{\out{\sloppy}} Implemented by \code{accel_metric_svmbp} in \code{R/m_accel_summary_suite.R}. See \code{\link{implementation-guide}} for the framework and function map.}

\examples{
path <- system.file("extdata", "example_motion.csv",
    package = "metronautica", mustWork = TRUE)
x <- parse_raw_auto(path)
out <- accel_metric_svmbp(x, epoch_s = 5, fs_hz = 100,
    cutoffs_hz = c(.69, 10), quiet = TRUE)
head(out)
}
