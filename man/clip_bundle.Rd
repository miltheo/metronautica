\name{clip_bundle}
\alias{clip_bundle}
\title{Select a time interval with provenance}
\description{\if{latex}{\out{\sloppy}} Select an inclusive time interval from an acceleration table or parser bundle.}
\usage{
clip_bundle(obj, start_time = NULL, duration_s = NULL, end_time =
    NULL, trim_pad_s = 0, keep_qc = FALSE)
}
\arguments{
\item{obj}{\if{latex}{\out{\sloppy}} An acceleration table, parser bundle with \code{data}, or dynamic bundle with \code{full}; see Stage bundles for the scope of clipping.}
\item{start_time}{\if{latex}{\out{\sloppy}} Inclusive UTC bounds (POSIXct or parseable text). Supply a start with an end or duration, or an end with a duration.}
\item{duration_s}{\if{latex}{\out{\sloppy}} Duration in seconds; used to infer a missing bound. Explicit start and end take precedence.}
\item{end_time}{\if{latex}{\out{\sloppy}} Inclusive UTC bounds (POSIXct or parseable text). Supply a start with an end or duration, or an end with a duration.}
\item{trim_pad_s}{\if{latex}{\out{\sloppy}} Seconds added before the start and after the end; a negative value contracts the interval.}
\item{keep_qc}{\if{latex}{\out{\sloppy}} Retain inherited diagnostics if TRUE. They are not recomputed and may describe the original recording.}
}
\value{\if{latex}{\out{\sloppy}} The same object form as the input. Acquisition bounds are updated and a clipping event is appended to \code{meta$processing$history}. Inherited QC and a top-level bundle QC entry are removed by default.}
\details{\if{latex}{\out{\sloppy}} Both endpoints are included. A 10-s interval sampled at 100 Hz can therefore contain 1001 samples. This differs deliberately from the exclusive end used by static and dynamic stage clipping. The input is unchanged. Invalid or empty intervals raise errors. Recompute \code{qc_accel_tbl()} for the selected interval.}
\seealso{\code{\link{metronautica-package}}}

\section{Implementation}{\if{latex}{\out{\sloppy}} Implemented by \code{clip_bundle} in \code{R/m_accel_clipper.R}. See \code{\link{implementation-guide}} for the framework and function map.}

\section{Stage bundles}{
\if{latex}{\out{\sloppy}}
A dynamic bundle with \code{full} is also accepted. The selected full recording is clipped, while existing \code{stages} and \code{schedule} are retained unchanged. Construct stages again from the intended clipped recording before stage-based metrology. This differs from \code{\link{dm_apply_vm_calibration_bundle}}, which explicitly transforms every stored signal.
}
