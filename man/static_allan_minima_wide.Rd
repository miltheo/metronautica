\name{static_allan_minima_wide}
\alias{static_allan_minima_wide}
\title{Summarise axis-specific Allan minima}
\description{\if{latex}{\out{\sloppy}} Summarise axis-specific Allan minima.}
\usage{
static_allan_minima_wide(allan_df)
}
\arguments{
\item{allan_df}{\if{latex}{\out{\sloppy}} Allan-deviation table with axis, tau and adev columns: axis label, evaluated averaging time in seconds, and deviation in g. Obtain it with static_allan.}
}
\value{\if{latex}{\out{\sloppy}} A one-row tibble with x_allan_min_g, y_allan_min_g and z_allan_min_g (axis minima in g), plus x_cluster_time_s, y_cluster_time_s and z_cluster_time_s (the corresponding evaluated averaging times in seconds).}
\seealso{\code{\link{metronautica-package}}}

\section{Method}{\if{latex}{\out{\sloppy}} Find the smallest evaluated deviation separately for X, Y and Z and retain its averaging time. A maximum-axis Allan minimum is obtained separately by taking the maximum of these three axis minima.}

\section{Implementation}{\if{latex}{\out{\sloppy}} Implemented by \code{static_allan_minima_wide} in \code{R/m_static.R}. See \code{\link{implementation-guide}} for the framework and function map.}
