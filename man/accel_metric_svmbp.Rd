\name{accel_metric_svmbp}
\alias{accel_metric_svmbp}
\title{Compute band-pass vector magnitude}
\description{\if{latex}{\out{\sloppy}} Epoch summaries of VM recombined after axis band-pass filtering.}
\usage{
accel_metric_svmbp(tbl, epoch_s, fs_hz, anchor = "center",
    cutoffs_hz = c(0.2, 15), order = 4, output = c("mean_mg",
    "mean_g", "sum_mg", "sum_g", "g_seconds"), nyquist_action =
    c("stop", "clip"), quiet = FALSE)
}
\arguments{
\item{tbl}{\if{latex}{\out{\sloppy}} Acceleration table or parser/clip bundle; see \code{\link{common-data-format}}.}
\item{epoch_s}{\if{latex}{\out{\sloppy}} Positive epoch duration (s); see the pipeline epoch conventions in \code{\link{compute_accel_summaries}}.}
\item{fs_hz}{\if{latex}{\out{\sloppy}} Finite positive sampling frequency (Hz), used for sample windows or time integrals.}
\item{anchor}{\if{latex}{\out{\sloppy}} Observed-sample label: first (start), last (end), or ceiling of half the sample count (center). Labels do not change values.}
\item{cutoffs_hz}{\if{latex}{\out{\sloppy}} Lower and upper axis band-pass cutoffs in Hz, applied before vector-magnitude recombination. The upper cutoff must lie below fs_hz/2 unless clipping is explicitly selected.}
\item{order}{\if{latex}{\out{\sloppy}} Axis band-pass Butterworth order; default four, applied forward/reverse before VM recombination.}
\item{output}{\if{latex}{\out{\sloppy}} Band-pass VM aggregation: mean_mg and mean_g return epoch means; sum_mg and sum_g return sample sums; g_seconds divides the \eqn{g} sample sum by fs_hz. Sample sums depend on the sample count.}
\item{nyquist_action}{\if{latex}{\out{\sloppy}} stop (default) rejects upper cutoffs at/above Nyquist; clip adjusts them to 99 percent of Nyquist.}
\item{quiet}{\if{latex}{\out{\sloppy}} Suppress informational messages, retaining errors.}
}
\value{\if{latex}{\out{\sloppy}} A tibble with \code{time}, \code{epoch_id} and \code{value}. Units are m\eqn{g}/\eqn{g} for means, m\eqn{g}/\eqn{g} sample sums for sum_mg/sum_g, or \eqn{g} seconds for g_seconds. The \code{settings} attribute records requested/applied cutoffs, filter order, sampling frequency, Nyquist policy, output aggregation, epoch duration and anchor.}

\details{\if{latex}{\out{\sloppy}} Filter each acceleration axis using signal::butter and forward/reverse filtfilt, recombine the filtered axes as VM, then aggregate. Axis filtering precedes recombination; this differs from filtering VM or using the compensated standalone filter.}
\seealso{\code{\link{compute_accel_summaries}}}

\examples{
path <- system.file("extdata", "example_motion.csv",
    package = "metronautica", mustWork = TRUE)
x <- parse_raw_auto(path)
out <- accel_metric_svmbp(x, epoch_s = 5, fs_hz = 100,
    cutoffs_hz = c(.69, 10), quiet = TRUE)
head(out)
}
