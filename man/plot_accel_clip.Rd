\name{plot_accel_clip}
\alias{plot_accel_clip}
\title{Plot triaxial acceleration and optional vector magnitude}
\description{\if{latex}{\out{\sloppy}} Plot triaxial acceleration and optional vector magnitude.}
\usage{
plot_accel_clip(x, include_vm = FALSE, demean_vm = FALSE, title =
    NULL)
}
\arguments{
\item{x}{\if{latex}{\out{\sloppy}} Acceleration data frame/tibble with POSIXct time and numeric ax_g, ay_g, az_g in g, or a parser/clip bundle containing data/full and optional meta. The data attribute takes precedence over bundle metadata. No samples are repaired by input conversion.}
\item{include_vm}{\if{latex}{\out{\sloppy}} Add sample-level vector magnitude to the triaxial plot.}
\item{demean_vm}{\if{latex}{\out{\sloppy}} For the optional VM trace, plot max(VM minus 1 g, 0) instead of VM.}
\item{title}{\if{latex}{\out{\sloppy}} Optional plot title.}
}
\value{\if{latex}{\out{\sloppy}} An interactive Plotly htmlwidget. Display thinning does not alter the input recording.}
\seealso{\code{\link{metronautica-package}}}

\section{Implementation}{\if{latex}{\out{\sloppy}} Implemented by \code{plot_accel_clip} in \code{R/m_plotter.R}. See \code{\link{implementation-guide}} for the framework and function map.}
