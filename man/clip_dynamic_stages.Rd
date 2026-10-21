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
\item{x}{\if{latex}{\out{\sloppy}} Acceleration data frame/tibble with POSIXct time and numeric ax_g, ay_g, az_g in g, or a parser/clip bundle containing data/full and optional meta. The data attribute takes precedence over bundle metadata. No samples are repaired by input conversion.}
\item{start_utc}{\if{latex}{\out{\sloppy}} UTC window start; POSIXct or parseable text.}
\item{n_stages}{\if{latex}{\out{\sloppy}} Required positive integer number of excitation stages; not inferred from the data.}
\item{stage_min}{\if{latex}{\out{\sloppy}} Required raw duration of each stage in minutes, before trimming.}
\item{buffer_min}{\if{latex}{\out{\sloppy}} Required non-negative interval in minutes between raw stages. It is excluded from the stage tables but retained within the full protocol span.}
\item{rpm_start}{\if{latex}{\out{\sloppy}} Required numerical RPM label assigned to the first stage; it is a supplied excitation condition, not a measured frequency.}
\item{rpm_step}{\if{latex}{\out{\sloppy}} Required increment in the RPM label between consecutive stages. The clipper assumes this regular schedule.}
\item{trim_start_min}{\if{latex}{\out{\sloppy}} Required non-negative minutes removed from the beginning of every raw stage. Start/end trims must sum to less than stage_min.}
\item{trim_end_min}{\if{latex}{\out{\sloppy}} Required non-negative minutes removed from the end of every raw stage. Trimming changes the analysed interval, not the native file.}
\item{keep_empty}{\if{latex}{\out{\sloppy}} Retain empty tables if TRUE; otherwise store NULL at the corresponding stage position.}
\item{verbose}{\if{latex}{\out{\sloppy}} Logical; print processing messages. Does not change calculations.}
\item{time_offset_s}{\if{latex}{\out{\sloppy}} Additive schedule-anchor shift in seconds; sample timestamps are unchanged.}
}
\value{\if{latex}{\out{\sloppy}} A list with \code{full} (untrimmed full-protocol table), \code{stages} (named list, e.g. \code{rpm_50}), \code{schedule} (raw and trimmed UTC bounds, settings and labels), and \code{meta}. Each clip has freshly computed QC.}
\details{\if{latex}{\out{\sloppy}} All schedule parameters must be supplied explicitly for the experiment; this helper does not infer an excitation protocol from the recording. The input is sorted by timestamp within this operation; inspect whole-recording QC beforehand. Each stage spans \eqn{[start,end)}. The first raw stage starts at \code{start_utc + time_offset_s}; consecutive starts are separated by \code{stage_min + buffer_min}. Trims must total less than the raw stage duration. Missing stages remain positionally identifiable; resolve them before requesting paired metrology.}
\seealso{\code{\link{metronautica-package}}}

\section{Implementation}{\if{latex}{\out{\sloppy}} Implemented by \code{clip_dynamic_stages} in \code{R/m_dynamic.R}. See \code{\link{implementation-guide}} for the framework and manuscript mapping.}

\section{Processing order}{
\if{latex}{\out{\sloppy}}
Apply any intended axis filtering to the recording before constructing stages. Filtering an existing dynamic bundle with \code{filter_accel_tbl} changes only its full recording, not its stored stage tables. Stage-based response uses \code{stages}, while some whole-recording diagnostics use \code{full}; these signals must represent the intended processing state.
}
