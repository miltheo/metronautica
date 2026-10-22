\name{filter_accel_tbl}
\alias{filter_accel_tbl}
\title{Filter axes with a compensated Butterworth filter}
\description{\if{latex}{\out{\sloppy}} Apply forward-backward Butterworth filtering to each acceleration axis and record processing provenance.}
\usage{
filter_accel_tbl(x, cutoff, forder = 4, ftype = "low")
}
\arguments{
\item{x}{\if{latex}{\out{\sloppy}} Acceleration data frame/tibble with POSIXct time and numeric ax_g, ay_g, az_g in \eqn{g}, or a parser/clip bundle containing data/full and optional meta. The data attribute takes precedence over bundle metadata. No samples are repaired by input conversion.}
\item{cutoff}{\if{latex}{\out{\sloppy}} One cutoff for low/high pass, or increasing lower and upper cutoffs for pass/stop bands, in Hz.}
\item{forder}{\if{latex}{\out{\sloppy}} Positive integer Butterworth order before forward-backward application.}
\item{ftype}{\if{latex}{\out{\sloppy}} Filter type accepted by \code{signal::butter}: \code{"low"}, \code{"high"}, \code{"pass"}, \code{"stop"}.}
}
\value{\if{latex}{\out{\sloppy}} The same input container type with filtered axes, unchanged timestamps, appended processing history and invalidated inherited QC. Table and bundle metadata remain synchronised.}
\details{\if{latex}{\out{\sloppy}} The implemented cutoff adjustment is \eqn{f_c/(\sqrt{2}-1)^{1/(2n)}}, followed by normalisation to Nyquist and \code{signal::filtfilt()}. All adjusted cutoffs must lie strictly between zero and Nyquist. This helper applies the cutoff adjustment for the selected filter type; do not assume identical effective edges across filter types. The feature-suite band-pass filter is a separate implementation. The input must contain a finite positive acquisition$fs_derived_hz in its metadata; this helper does not substitute a nominal rate or infer a new rate. Regular sampling and an adequate contiguous, finite record are caller responsibilities; this function does not repair gaps.}
\seealso{\code{\link{metronautica-package}}}

\section{Implementation}{\if{latex}{\out{\sloppy}} Implemented by \code{filter_accel_tbl} in \code{R/m_filter.R}. See \code{\link{implementation-guide}} for the framework and function map.}

\section{Stage bundles}{
\if{latex}{\out{\sloppy}}
For a parser bundle, the filtered recording is returned in \code{data}. For a dynamic stage bundle, only \code{full} is filtered; \code{stages} and \code{schedule} are retained unchanged. They therefore do not become filtered stage inputs. Filter the acceleration table or parser bundle first, then call \code{\link{clip_dynamic_stages}} on the filtered result. The returned container is not a recursive transformation of every stored signal.
}
