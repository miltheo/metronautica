\name{dm_apply_vm_calibration_tbl}
\alias{dm_apply_vm_calibration_tbl}
\title{Apply vector-magnitude calibration to triaxial samples}
\description{\if{latex}{\out{\sloppy}} Apply vector-magnitude calibration to triaxial samples.}
\usage{
dm_apply_vm_calibration_tbl(df, cal_row)
}
\arguments{
\item{df}{\if{latex}{\out{\sloppy}} Acceleration table or parser/clip bundle with POSIXct time and numeric axes in g. Container type and timestamps are preserved.}
\item{cal_row}{\if{latex}{\out{\sloppy}} One-row data frame/tibble or named scalar list containing finite numeric vm_calibration_intercept, vm_calibration_slope and vm_calibration_quadratic. Supply zero for the quadratic term of a linear model. If vm_calibration_direction is present it must be ref_on_test. Invalid/ambiguous rows raise an error.}
}
\value{\if{latex}{\out{\sloppy}} The same input container type, with calibrated axes and unchanged timestamps. A parser bundle retains its data/meta structure; a stage bundle also calibrates its stages. Metadata records the applied row and processing event, marks the signal calibrated and removes pre-calibration QC. Call attach_qc to obtain diagnostics for the changed signal.}
\seealso{\code{\link{metronautica-package}}}

\section{Method}{\if{latex}{\out{\sloppy}} Map test VM v to max(b0+b1*v+b2*v^2, 0), then multiply every axis at that sample by corrected_VM/v. The original scale fallback of one for zero/undefined VM is retained. This scalar mapping preserves the instantaneous acceleration-vector direction; it is not a general axis-specific calibration. Finite single-row coefficients are required. When a direction is provided it must be ref_on_test. Source decoding provenance remains available; added calibration history is separate.}

\section{Implementation}{\if{latex}{\out{\sloppy}} Implemented by \code{dm_apply_vm_calibration_tbl} in \code{R/m_dynamic.R}. See \code{\link{implementation-guide}} for the framework and function map.}
