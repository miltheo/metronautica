\name{invalidate_qc}
\alias{invalidate_qc}
\title{Remove diagnostics inherited from an earlier signal state}
\description{\if{latex}{\out{\sloppy}} Remove diagnostics inherited from an earlier signal state.}
\usage{
invalidate_qc(x)
}
\arguments{
\item{x}{\if{latex}{\out{\sloppy}} Acceleration data frame/tibble with POSIXct time and numeric ax_g, ay_g, az_g in g, or a parser/clip bundle containing data/full and optional meta. The data attribute takes precedence over bundle metadata. No samples are repaired by input conversion.}
}
\value{\if{latex}{\out{\sloppy}} The same input container with inherited QC removed; acceleration samples are unchanged.}
\seealso{\code{\link{metronautica-package}}}

\section{Implementation}{\if{latex}{\out{\sloppy}} Implemented by \code{invalidate_qc} in \code{R/m_qc.R}. See \code{\link{implementation-guide}} for the framework and function map.}
