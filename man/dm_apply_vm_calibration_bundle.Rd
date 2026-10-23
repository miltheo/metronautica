\name{dm_apply_vm_calibration_bundle}
\alias{dm_apply_vm_calibration_bundle}
\title{Apply vector-magnitude calibration to a stage bundle}
\description{\if{latex}{\out{\sloppy}} Apply a supplied VM mapping to every stored signal in a bundle.}
\usage{
dm_apply_vm_calibration_bundle(clips, cal_row)
}
\arguments{
\item{clips}{\if{latex}{\out{\sloppy}} Acceleration table, parser bundle with data, or dynamic bundle with full and stages. Every present signal is calibrated; NULL stages remain NULL.}
\item{cal_row}{\if{latex}{\out{\sloppy}} One-row table or named scalar list: finite vm_calibration_intercept, vm_calibration_slope, vm_calibration_quadratic (zero for linear). Optional vm_calibration_direction must be ref_on_test. Invalid/ambiguous rows error.}
}
\value{\if{latex}{\out{\sloppy}} The same table or bundle form. Apply identical coefficients to full/data and each non-NULL stage. Per-table metadata and top-level meta record the operation; inherited QC is removed from all modified signals and the top-level bundle.}
\seealso{\code{\link{dm_fit_vm_calibration}}, \code{\link{attach_qc}}, \code{\link{common-data-format}}}

\section{Method}{\if{latex}{\out{\sloppy}} Map test VM v to max(b0+b1*v+b2*v^2, 0); scale each axis by corrected_VM/v, using one for zero/undefined VM. This preserves vector direction, rather than calibrating axes independently. Source decoding provenance is retained separately from added calibration history.}
