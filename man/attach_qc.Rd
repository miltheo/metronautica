\name{attach_qc}
\alias{attach_qc}
\title{Attach signal diagnostics to recording metadata}
\description{\if{latex}{\out{\sloppy}} Attach signal diagnostics to recording metadata.}
\usage{
attach_qc(x, scope = "whole parsed recording")
}
\arguments{
\item{x}{\if{latex}{\out{\sloppy}} Acceleration data frame/tibble with POSIXct time and numeric ax_g, ay_g, az_g in g, or a parser/clip bundle containing data/full and optional meta. The data attribute takes precedence over bundle metadata. No samples are repaired by input conversion.}
\item{scope}{\if{latex}{\out{\sloppy}} Text describing the recording interval to which the diagnostics apply.}
}
\value{\if{latex}{\out{\sloppy}} The same input container, with primary-five diagnostics in meta$processing$qc. Bundle and data metadata are synchronised.}
\seealso{\code{\link{metronautica-package}}}

\section{Implementation}{\if{latex}{\out{\sloppy}} Implemented by \code{attach_qc} in \code{R/m_qc.R}. See \code{\link{implementation-guide}} for the framework and manuscript mapping.}
