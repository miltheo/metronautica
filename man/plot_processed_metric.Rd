\name{plot_processed_metric}
\alias{plot_processed_metric}
\title{Plot an epoch-level acceleration feature}
\description{\if{latex}{\out{\sloppy}} Interactive display of an existing epoch-level feature.}
\usage{
plot_processed_metric(result, metric, unit = NULL, title = metric)
}
\arguments{
\item{result}{\if{latex}{\out{\sloppy}} Summary result from compute_accel_summaries or its data_wide table.}
\item{metric}{\if{latex}{\out{\sloppy}} Name of the numeric column to plot from the processed summary table.}
\item{unit}{\if{latex}{\out{\sloppy}} Unit label displayed on the processed plot; does not rescale values. NULL uses result$settings$metric_units. Supply a label explicitly for a bare data_wide table or older outputs without this metadata; no m\eqn{g} unit is assumed.}
\item{title}{\if{latex}{\out{\sloppy}} Optional plot title.}
}
\value{\if{latex}{\out{\sloppy}} Plotly htmlwidget; values are unchanged.}
\seealso{\code{\link{compute_accel_summaries}}, \code{\link{feature-comparison}}}
