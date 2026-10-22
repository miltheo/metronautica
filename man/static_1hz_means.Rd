\name{static_1hz_means}
\alias{static_1hz_means}
\title{Compute one-second triaxial and vector-magnitude means}
\description{\if{latex}{\out{\sloppy}} Compute one-second triaxial and vector-magnitude means.}
\usage{
static_1hz_means(x)
}
\arguments{
\item{x}{\if{latex}{\out{\sloppy}} Acceleration data frame/tibble with POSIXct time and numeric ax_g, ay_g, az_g in g, or a parser/clip bundle containing data/full and optional meta. The data attribute takes precedence over bundle metadata. No samples are repaired by input conversion.}
}
\value{\if{latex}{\out{\sloppy}} A tibble with sec (UTC second-bin start), ax_mean, ay_mean, az_mean and vm_mean (one-second means in g), and elapsed_h (hours since the first populated bin).}
\seealso{\code{\link{metronautica-package}}}

\section{Method}{\if{latex}{\out{\sloppy}} Bin timestamps by floor of Unix seconds. Within each populated second, average each axis and sample vector magnitude, omitting missing values. Empty UTC seconds are not filled. elapsed_h starts at the first populated bin. This is the input to the static drift and initial VM-offset calculations.}

\section{Implementation}{\if{latex}{\out{\sloppy}} Implemented by \code{static_1hz_means} in \code{R/m_static.R}. See \code{\link{implementation-guide}} for the framework and function map.}
