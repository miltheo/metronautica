\name{plot_static_allan}
\alias{plot_static_allan}
\title{Plot axis-specific Allan deviation}
\description{\if{latex}{\out{\sloppy}} Plot axis-specific Allan deviation.}
\usage{
plot_static_allan(allan_df, title_prefix = "Allan deviation")
}
\arguments{
\item{allan_df}{\if{latex}{\out{\sloppy}} Allan-deviation table with axis, tau and adev columns: axis label, evaluated averaging time in seconds, and deviation in g. Obtain it with static_allan.}
\item{title_prefix}{\if{latex}{\out{\sloppy}} Character prefix for diagnostic plot titles; does not change computed outcomes.}
}
\value{\if{latex}{\out{\sloppy}} A ggplot object; supplied data are unchanged.}
\seealso{\code{\link{metronautica-package}}}

\section{Implementation}{\if{latex}{\out{\sloppy}} Implemented by \code{plot_static_allan} in \code{R/m_static.R}. See \code{\link{implementation-guide}} for the framework and manuscript mapping.}
