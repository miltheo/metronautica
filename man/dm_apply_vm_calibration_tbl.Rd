\name{dm_apply_vm_calibration_tbl}
\alias{dm_apply_vm_calibration_tbl}
\title{Apply vector-magnitude calibration to triaxial samples}
\description{\if{latex}{\out{\sloppy}} Apply a supplied scalar VM mapping while preserving vector direction.}
\usage{
dm_apply_vm_calibration_tbl(df, cal_row)
}
\arguments{
\item{df}{\if{latex}{\out{\sloppy}} Acceleration table or parser/clip bundle with POSIXct time and numeric axes in \eqn{g}. Container type and timestamps are preserved.}
\item{cal_row}{\if{latex}{\out{\sloppy}} One-row table or named scalar list: finite vm_calibration_intercept, vm_calibration_slope, vm_calibration_quadratic (zero for linear). Optional vm_calibration_direction must be ref_on_test. Invalid/ambiguous rows error.}
}
\value{\if{latex}{\out{\sloppy}} The same input container type, with calibrated axes and unchanged timestamps. A parser bundle retains its data/meta structure; a stage bundle also calibrates its stages. Metadata records the applied row and processing event, marks the signal calibrated and removes pre-calibration QC. Call attach_qc to obtain diagnostics for the changed signal.}
\seealso{\code{\link{dm_fit_vm_calibration}}, \code{\link{attach_qc}}, \code{\link{common-data-format}}}

\section{Method}{\if{latex}{\out{\sloppy}} Map test VM v to max(b0+b1*v+b2*v^2, 0); scale each axis by corrected_VM/v, using one for zero/undefined VM. This preserves vector direction, rather than calibrating axes independently. Source decoding provenance is retained separately from added calibration history.}
