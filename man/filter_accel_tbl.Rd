\name{filter_accel_tbl}
\alias{filter_accel_tbl}
\title{Filter axes with a compensated Butterworth filter}
\description{\if{latex}{\out{\sloppy}} Apply forward-backward Butterworth filtering to each acceleration axis and record processing provenance.}
\usage{
filter_accel_tbl(x, cutoff, forder = 4, ftype = "low")
}
\arguments{
\item{x}{\if{latex}{\out{\sloppy}} Acceleration table or parser/clip bundle; see \code{\link{common-data-format}}.}
\item{cutoff}{\if{latex}{\out{\sloppy}} One cutoff for low/high pass, or increasing lower and upper cutoffs for pass/stop bands, in Hz.}
\item{forder}{\if{latex}{\out{\sloppy}} Positive integer Butterworth order before forward-backward application.}
\item{ftype}{\if{latex}{\out{\sloppy}} Filter type accepted by \code{signal::butter}: \code{"low"}, \code{"high"}, \code{"pass"}, \code{"stop"}.}
}
\value{\if{latex}{\out{\sloppy}} The same input container type with filtered axes, unchanged timestamps, appended processing history and invalidated inherited QC. Table and bundle metadata remain synchronised.}
\details{\if{latex}{\out{\sloppy}} Adjust cutoffs by \eqn{f_c/(\sqrt{2}-1)^{1/(2n)}}, normalise to Nyquist, then apply \code{signal::filtfilt()}. Adjusted cutoffs must be strictly between zero and Nyquist. The adjustment applies to every supported filter type; effective edges need not match across types. Feature-suite band-pass filtering is separate. Requires finite positive acquisition$fs_derived_hz; no nominal/timestamp fallback. Supply a sufficiently long, contiguous, finite, regularly sampled recording; gaps are not repaired.}
\seealso{\code{\link{clip_dynamic_stages}}, \code{\link{accel_metric_svmbp}}, \code{\link{common-data-format}}}

\section{Stage bundles}{\if{latex}{\out{\sloppy}} Parser bundles return filtered \code{data}. Dynamic bundles filter only \code{full}, leaving \code{stages}/\code{schedule} unchanged. Filter first, then reconstruct stages with \code{\link{clip_dynamic_stages}}.}
