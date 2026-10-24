\name{accel_metric_enmo}
\alias{accel_metric_enmo}
\title{Compute Euclidean norm minus one}
\description{\if{latex}{\out{\sloppy}} Epoch mean of max(VM - 1 \eqn{g}, 0).}
\usage{
accel_metric_enmo(tbl, epoch_s, anchor = "center", out_unit =
    c("mg", "g"))
}
\arguments{
\item{tbl}{\if{latex}{\out{\sloppy}} Acceleration table or parser/clip bundle; see \code{\link{common-data-format}}.}
\item{epoch_s}{\if{latex}{\out{\sloppy}} Positive epoch duration (s); see the pipeline epoch conventions in \code{\link{compute_accel_summaries}}.}
\item{anchor}{\if{latex}{\out{\sloppy}} Observed-sample label: first (start), last (end), or ceiling of half the sample count (center). Labels do not change values.}
\item{out_unit}{\if{latex}{\out{\sloppy}} Output unit: \eqn{g}, or m\eqn{g} (result multiplied by 1000).}
}
\value{\if{latex}{\out{\sloppy}} Tibble: \code{time} (selected epoch label), \code{epoch_id} (elapsed-time bin, starting at one), \code{value} (selected \eqn{g} or m\eqn{g} unit).}

\details{\if{latex}{\out{\sloppy}} Negative differences are truncated to zero before epoch averaging.}
\seealso{\code{\link{compute_accel_summaries}}}

\examples{
path <- system.file("extdata", "example_motion.csv",
    package = "metronautica", mustWork = TRUE)
x <- parse_raw_auto(path)
out <- accel_metric_enmo(x, epoch_s = 5)
head(out)
}
