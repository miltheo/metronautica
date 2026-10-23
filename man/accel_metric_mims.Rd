\name{accel_metric_mims}
\alias{accel_metric_mims}
\title{Compute MIMS-unit}
\description{\if{latex}{\out{\sloppy}} MIMS-unit output using configurable upstream MIMSunit processing.}
\usage{
accel_metric_mims(tbl, epoch_s, dynamic_range_g, mims_filter_type =
    "butter", mims_cutoffs = c(0.2, 5), mims_use_extrapolation =
    TRUE, mims_use_filtering = TRUE, mims_combination = "sum",
    mims_allow_truncation = TRUE)
}
\arguments{
\item{tbl}{\if{latex}{\out{\sloppy}} Acceleration table or parser/clip bundle; see \code{\link{common-data-format}}.}
\item{epoch_s}{\if{latex}{\out{\sloppy}} Positive epoch duration in seconds, passed as the upstream MIMS epoch setting. MIMSunit controls epoch boundaries, timestamps and treatment of partial epochs; this helper does not impose the common elapsed-sample epoch index.}
\item{dynamic_range_g}{\if{latex}{\out{\sloppy}} Configured peak-to-peak axis span (\eqn{g}): 16 means -8 to +8 \eqn{g}. Required by the direct MIMS helper; the summary function accepts NULL only with valid acquisition metadata. Missing range errors; observed values never define it.}
\item{mims_filter_type}{\if{latex}{\out{\sloppy}} MIMSunit::custom_mims_unit filter: butter (default), ellip or bessel, as supported upstream; used with mims_cutoffs.}
\item{mims_cutoffs}{\if{latex}{\out{\sloppy}} Filter cutoffs in Hz; default c(0.2, 5). Use c(0.2, 10) explicitly for the altered passband.}
\item{mims_use_extrapolation}{\if{latex}{\out{\sloppy}} Enable MIMS saturation/extrapolation (TRUE). FALSE skips that step but retains upstream grid interpolation. This concerns acceleration, not behavioural-time extrapolation.}
\item{mims_use_filtering}{\if{latex}{\out{\sloppy}} Enable internal MIMS band-pass filtering; FALSE bypasses it and defines a different pipeline.}
\item{mims_combination}{\if{latex}{\out{\sloppy}} MIMS axis combination: sum (default) adds axis summaries; vm takes their vector magnitude.}
\item{mims_allow_truncation}{\if{latex}{\out{\sloppy}} Allow upstream MIMS to set small summaries to zero; unrelated to native-recording clipping.}
}
\value{\if{latex}{\out{\sloppy}} A tibble with \code{time} (upstream MIMS epoch labels), \code{epoch_id} (sequential row number), and \code{value} (the combined MIMS-unit output per epoch). These values are not \eqn{g} or m\eqn{g}. The \code{settings} attribute records measurement span/limits, filter and cutoffs, extrapolation, truncation, combination, duration and MIMSunit version. }

\details{\if{latex}{\out{\sloppy}} Call MIMSunit::custom_mims_unit with triaxial \eqn{g} inputs and configured axis limits. Default 0.2-5 Hz and altered 0.2-10 Hz passbands define different pipelines.}
\seealso{\code{\link{compute_accel_summaries}}}

\references{John et al. (2019), An open-source monitor-independent movement summary for accelerometer data processing. \doi{10.1123/jmpb.2018-0068}.}
