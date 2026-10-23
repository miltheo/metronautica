\name{static_allan_minima_wide}
\alias{static_allan_minima_wide}
\title{Summarise axis-specific Allan minima}
\description{\if{latex}{\out{\sloppy}} Minimum evaluated Allan deviation and corresponding averaging time for each axis.}
\usage{
static_allan_minima_wide(allan_df)
}
\arguments{
\item{allan_df}{\if{latex}{\out{\sloppy}} Output of \code{\link{static_allan}}: axis, tau (s) and adev (\eqn{g}).}
}
\value{\if{latex}{\out{\sloppy}} A one-row tibble with x_allan_min_g, y_allan_min_g and z_allan_min_g (axis minima in \eqn{g}), plus x_cluster_time_s, y_cluster_time_s and z_cluster_time_s (the corresponding evaluated averaging times in seconds).}
\seealso{\code{\link{static_allan}}, \code{\link{measurement-definitions}}}

\section{Method}{\if{latex}{\out{\sloppy}} Find the smallest evaluated deviation separately for X, Y and Z and retain its averaging time. A maximum-axis Allan minimum is obtained separately by taking the maximum of these three axis minima.}
