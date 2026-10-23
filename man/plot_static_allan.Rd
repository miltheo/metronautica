\name{plot_static_allan}
\alias{plot_static_allan}
\title{Plot axis-specific Allan deviation}
\description{\if{latex}{\out{\sloppy}} Log-log Allan curves with axis minima and averaging-time labels.}
\usage{
plot_static_allan(allan_df, title_prefix = "Allan deviation")
}
\arguments{
\item{allan_df}{\if{latex}{\out{\sloppy}} Output of \code{\link{static_allan}}: axis, tau (s) and adev (\eqn{g}).}
\item{title_prefix}{\if{latex}{\out{\sloppy}} Plot-title prefix.}
}
\value{\if{latex}{\out{\sloppy}} ggplot object; data are unchanged.}
\details{\if{latex}{\out{\sloppy}} Both axes use log10 coordinates with inward logarithmic tick marks. Axis minima and their averaging times are labelled from the supplied table; plotting does not recalculate Allan deviation.}
\seealso{\code{\link{static_allan}}, \code{\link{static_allan_minima_wide}}}
