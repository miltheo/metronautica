\name{accel_metric_enmo}
\alias{accel_metric_enmo}
\title{Compute Euclidean norm minus one}
\description{\if{latex}{\out{\sloppy}} Compute Euclidean norm minus one.}
\usage{
accel_metric_enmo(tbl, epoch_s, anchor = "center", out_unit =
    c("mg", "g"))
}
\arguments{
\item{tbl}{\if{latex}{\out{\sloppy}} Acceleration data frame/tibble with POSIXct time and numeric ax_g, ay_g, az_g in g, or a parser/clip bundle containing data/full. Input conversion preserves values and metadata.}
\item{epoch_s}{\if{latex}{\out{\sloppy}} Positive output-epoch duration in seconds. Samples are grouped by elapsed time from the first sample; the final partial epoch is retained. Different epoch lengths define different processing pipelines.}
\item{anchor}{\if{latex}{\out{\sloppy}} Output timestamp: start selects the first observed sample in an epoch, end the last, and center the middle observed sample (ceiling of half the epoch sample count). This labels the result without changing values.}
\item{out_unit}{\if{latex}{\out{\sloppy}} Output acceleration unit: mg multiplies the epoch result by 1000; g retains the input scale.}
}
\value{A tibble with \code{time} (the selected observed-sample epoch label), \code{epoch_id} (integer elapsed-time bin starting at one), and \code{value} (g or mg according to the selected output unit).}

\details{\if{latex}{\out{\sloppy}} Compute max(VM - 1, 0) for every sample, then average within each epoch. Rectification precedes averaging; this is the approved ENMO definition. See \code{\link{measurement-definitions}} for manuscript-aligned definitions. No additional device calibration is performed by choosing a feature.}
\seealso{\code{\link{metronautica-package}}}

\section{Implementation}{\if{latex}{\out{\sloppy}} Implemented by \code{accel_metric_enmo} in \code{R/m_accel_summary_suite.R}. See \code{\link{implementation-guide}} for the framework and manuscript mapping.}

\examples{
path <- system.file("extdata", "example_motion.csv",
    package = "metronautica", mustWork = TRUE)
x <- parse_raw_auto(path)
out <- accel_metric_enmo(x, epoch_s = 5)
head(out)
}
