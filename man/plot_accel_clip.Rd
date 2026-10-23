\name{plot_accel_clip}
\alias{plot_accel_clip}
\title{Plot triaxial acceleration and optional vector magnitude}
\description{\if{latex}{\out{\sloppy}} Interactive axis traces with optional VM or non-negative VM-minus-gravity trace.}
\usage{
plot_accel_clip(x, include_vm = FALSE, demean_vm = FALSE, title =
    NULL)
}
\arguments{
\item{x}{\if{latex}{\out{\sloppy}} Acceleration table or parser/clip bundle; see \code{\link{common-data-format}}.}
\item{include_vm}{\if{latex}{\out{\sloppy}} Add sample-level vector magnitude to the triaxial plot.}
\item{demean_vm}{\if{latex}{\out{\sloppy}} For the optional VM trace, plot max(VM minus 1 \eqn{g}, 0) instead of VM.}
\item{title}{\if{latex}{\out{\sloppy}} Optional plot title.}
}
\value{\if{latex}{\out{\sloppy}} An interactive Plotly htmlwidget. Display thinning does not alter the input recording.}
\seealso{\code{\link{parse_raw_auto}}, \code{\link{plot_processed_metric}}}
