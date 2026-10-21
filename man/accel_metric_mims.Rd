\name{accel_metric_mims}
\alias{accel_metric_mims}
\title{Compute MIMS-unit}
\description{\if{latex}{\out{\sloppy}} Compute MIMS-unit.}
\usage{
accel_metric_mims(tbl, epoch_s, dynamic_range_g, mims_filter_type =
    "butter", mims_cutoffs = c(0.2, 5), mims_use_extrapolation =
    TRUE, mims_use_filtering = TRUE, mims_combination = "sum",
    mims_allow_truncation = TRUE)
}
\arguments{
\item{tbl}{\if{latex}{\out{\sloppy}} Acceleration data frame/tibble with POSIXct time and numeric ax_g, ay_g, az_g in g, or a parser/clip bundle containing data/full. Input conversion preserves values and metadata.}
\item{epoch_s}{\if{latex}{\out{\sloppy}} Positive epoch duration in seconds, passed as the upstream MIMS epoch setting. MIMSunit controls epoch boundaries, timestamps and treatment of partial epochs; this helper does not impose the common elapsed-sample epoch index.}
\item{dynamic_range_g}{\if{latex}{\out{\sloppy}} Peak-to-peak configured axis measurement span in g: 16 means -8 to +8 g. The summary function uses valid acquisition metadata when NULL; MIMS fails if neither is available. The direct MIMS function requires this argument. No range is inferred from observed values.}
\item{mims_filter_type}{\if{latex}{\out{\sloppy}} Filter family passed to MIMSunit::custom_mims_unit: butter (default), ellip or bessel as supported upstream. Its interpretation belongs to that implementation; select together with mims_cutoffs.}
\item{mims_cutoffs}{\if{latex}{\out{\sloppy}} Filter cutoffs in Hz; default c(0.2, 5). Use c(0.2, 10) explicitly for the altered passband.}
\item{mims_use_extrapolation}{\if{latex}{\out{\sloppy}} Logical passed to MIMSunit. TRUE enables its saturation/extrapolation step; FALSE skips that step while the upstream algorithm still interpolates to its processing grid. Does not mean extrapolating behavioural time.}
\item{mims_use_filtering}{\if{latex}{\out{\sloppy}} Logical; enable the specified internal MIMS band-pass processing. FALSE bypasses that internal filter, creating a different feature pipeline.}
\item{mims_combination}{\if{latex}{\out{\sloppy}} Axis-combination method passed to MIMSunit: sum adds axis summaries; vm combines them as a vector magnitude. The study uses sum.}
\item{mims_allow_truncation}{\if{latex}{\out{\sloppy}} Logical; permit the upstream MIMS implementation to set sufficiently small summary values to zero. This is an algorithmic small-value operation, not clipping native recordings.}
}
\value{A tibble with \code{time} (upstream MIMS epoch labels), \code{epoch_id} (sequential row number), and \code{value} (the combined MIMS-unit output per epoch). These values are not g or mg. The \code{settings} attribute records measurement span/limits, filter and cutoffs, extrapolation, truncation, combination, duration and MIMSunit version. Upstream epoch boundaries and partial-epoch handling are retained.}

\details{\if{latex}{\out{\sloppy}} Call MIMSunit::custom_mims_unit with triaxial g inputs, configured axis limits and the selected internal processing. Retain its timestamps and combined MIMS output. Default 0.2-5 Hz and explicit altered 0.2-10 Hz are different pipelines; resolved settings and dependency version are returned. See \code{\link{measurement-definitions}} for manuscript-aligned definitions. No additional device calibration is performed by choosing a feature.}
\seealso{\code{\link{metronautica-package}}}

\section{Implementation}{\if{latex}{\out{\sloppy}} Implemented by \code{accel_metric_mims} in \code{R/m_accel_summary_suite.R}. See \code{\link{implementation-guide}} for the framework and manuscript mapping.}

\references{John et al. (2019), An open-source monitor-independent movement summary for accelerometer data processing. \doi{10.1123/jmpb.2018-0068}.}
