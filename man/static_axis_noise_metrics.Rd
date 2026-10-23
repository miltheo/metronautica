\name{static_axis_noise_metrics}
\alias{static_axis_noise_metrics}
\title{Compute axis-specific stationary noise measures}
\description{\if{latex}{\out{\sloppy}} Raw, detrended and initial-window axis/VM variability.}
\usage{
static_axis_noise_metrics(x, cv_min_abs_mean_g = 0.005)
}
\arguments{
\item{x}{\if{latex}{\out{\sloppy}} Acceleration table or parser/clip bundle; see \code{\link{common-data-format}}.}
\item{cv_min_abs_mean_g}{\if{latex}{\out{\sloppy}} Absolute-mean threshold (\eqn{g}) below which CV is NA; default 0.005 \eqn{g} guards near-zero division.}
}
\value{\if{latex}{\out{\sloppy}} One-row tibble with raw and linearly detrended sample SDs, first-five-minute raw SDs, CVs, ranges and maximum-/median-axis summaries. Acceleration fields use \eqn{g} unless their name explicitly specifies m\eqn{g}; CV fields are percentages.}
\seealso{\code{\link{static_noise_summary_from_tbl}}, \code{\link{measurement-definitions}}}

\section{Returned fields}{
\if{latex}{\out{\sloppy}}
For each prefix x, y, z and vm, the one-row output contains \code{n} (finite samples used), \code{mean_g}, \code{sd_g} (sample SD), \code{detrended_sd_g} (linear-residual SD), \code{sd_5min_g} (raw SD within the first five minutes, inclusive boundary), \code{min_g}, \code{max_g}, \code{range_g}, \code{cv_percent} and \code{detrended_cv_percent}. Each prefix is joined to the field name by an underscore. Linear-residual SD uses n-2; raw SD uses n-1.

\code{max_axis_sd_g} and \code{median_axis_sd_g} summarise raw X/Y/Z SDs; \code{max_axis_noise_sd_g} and \code{median_axis_noise_sd_g} summarise detrended X/Y/Z SDs. Their maximum-axis identifiers end in \code{_axis}; analogous \code{sd_5min} fields use the initial raw window. \code{static_n_samples} counts supplied rows.

\code{static_noise_floor_mg} is 1000 times maximum-axis detrended SD. The retained \code{static_noise_floor_5min_mg} field is instead 1000 times initial raw maximum-axis SD; it is not detrended. \code{static_raw_max_axis_sd_mg} is the full-window raw maximum-axis SD in m\eqn{g}. \code{vm_sd_mg}, \code{vm_noise_sd_mg} and \code{vm_sd_5min_mg} give VM raw, detrended and initial raw SDs in m\eqn{g}; \code{vm_noise_cv_percent} is detrended VM CV. These operational outcomes do not independently establish stationarity.
}
