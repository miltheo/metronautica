\name{clip_dynamic_stages}
\alias{clip_dynamic_stages}
\title{Select trimmed excitation stages}
\description{\if{latex}{\out{\sloppy}} Build a timed excitation schedule and select trimmed, end-exclusive stages.}
\usage{
clip_dynamic_stages(x, start_utc, n_stages, stage_min,
    buffer_min, rpm_start, rpm_step, trim_start_min, trim_end_min,
    keep_empty = FALSE, verbose = FALSE,
    time_offset_s = 0)
}
\arguments{
\item{x}{\if{latex}{\out{\sloppy}} Acceleration table or parser/clip bundle; see \code{\link{common-data-format}}.}
\item{start_utc}{\if{latex}{\out{\sloppy}} UTC window start; POSIXct or parseable text.}
\item{n_stages}{\if{latex}{\out{\sloppy}} Required positive integer stage count; not inferred.}
\item{stage_min}{\if{latex}{\out{\sloppy}} Required raw stage duration (min), before trimming.}
\item{buffer_min}{\if{latex}{\out{\sloppy}} Required non-negative inter-stage interval (min); excluded from stages, retained in full.}
\item{rpm_start}{\if{latex}{\out{\sloppy}} Required first-stage RPM label: supplied excitation, not measured frequency.}
\item{rpm_step}{\if{latex}{\out{\sloppy}} Required RPM-label increment; assumes a regular schedule.}
\item{trim_start_min}{\if{latex}{\out{\sloppy}} Required non-negative start trim (min). Combined start/end trims must be less than stage_min.}
\item{trim_end_min}{\if{latex}{\out{\sloppy}} Required non-negative end trim (min); changes the selected interval, not the native file.}
\item{keep_empty}{\if{latex}{\out{\sloppy}} Retain empty tables if TRUE; otherwise store NULL at the corresponding stage position.}
\item{verbose}{\if{latex}{\out{\sloppy}} Print processing messages.}
\item{time_offset_s}{\if{latex}{\out{\sloppy}} Additive schedule-anchor shift in seconds; sample timestamps are unchanged.}
}
\value{\if{latex}{\out{\sloppy}} A list with \code{full} (untrimmed full-assessment table), \code{stages} (named list, e.g. \code{rpm_50}), \code{schedule} (raw and trimmed UTC bounds, settings and labels), and \code{meta}. Each clip has freshly computed QC.}
\details{\if{latex}{\out{\sloppy}} All schedule parameters are required. Input is timestamp-sorted; inspect whole-recording QC first. Stages use \eqn{[start,end)}. First raw start = start_utc + time_offset_s; subsequent starts differ by stage_min + buffer_min. Empty stages retain their positions; resolve them before pairing.}
\seealso{\code{\link{dynamic_metrology_report}}, \code{\link{filter_accel_tbl}}, \code{\link{clip_bundle}}}

\section{Processing order}{\if{latex}{\out{\sloppy}} Filter before constructing stages. \code{filter_accel_tbl} changes only an existing bundle's full recording; response uses stages and some diagnostics use full, so both must represent the intended signal state.}
