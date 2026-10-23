\name{static_1hz_means}
\alias{static_1hz_means}
\title{Compute one-second triaxial and vector-magnitude means}
\description{\if{latex}{\out{\sloppy}} Axis and sample-VM means in populated UTC-second bins.}
\usage{
static_1hz_means(x)
}
\arguments{
\item{x}{\if{latex}{\out{\sloppy}} Acceleration table or parser/clip bundle; see \code{\link{common-data-format}}.}
}
\value{\if{latex}{\out{\sloppy}} A tibble with sec (UTC second-bin start), ax_mean, ay_mean, az_mean and vm_mean (one-second means in \eqn{g}), and elapsed_h (hours since the first populated bin).}
\seealso{\code{\link{static_drift}}, \code{\link{static_offset_vm_5min}}}

\section{Method}{\if{latex}{\out{\sloppy}} Floor Unix timestamps to seconds. Average each axis and sample VM within populated bins, omitting missing values; leave empty seconds unfilled. elapsed_h starts at the first populated bin.}
