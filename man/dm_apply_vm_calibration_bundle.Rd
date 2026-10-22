\name{dm_apply_vm_calibration_bundle}
\alias{dm_apply_vm_calibration_bundle}
\title{Apply vector-magnitude calibration to a stage bundle}
\description{\if{latex}{\out{\sloppy}} Apply vector-magnitude calibration to a stage bundle.}
\usage{
dm_apply_vm_calibration_bundle(clips, cal_row)
}
\arguments{
\item{clips}{\if{latex}{\out{\sloppy}} Acceleration table, parser bundle with data, or dynamic bundle with full and stages. Every present signal is calibrated; NULL stages remain NULL.}
\item{cal_row}{\if{latex}{\out{\sloppy}} One-row data frame/tibble or named scalar list containing finite numeric vm_calibration_intercept, vm_calibration_slope and vm_calibration_quadratic. Supply zero for the quadratic term of a linear model. If vm_calibration_direction is present it must be ref_on_test. Invalid/ambiguous rows raise an error.}
}
\value{\if{latex}{\out{\sloppy}} The same table or bundle form. Apply identical coefficients to full/data and each non-NULL stage. Per-table metadata and top-level meta record the operation; inherited QC is removed from all modified signals and the top-level bundle.}
\seealso{\code{\link{metronautica-package}}}

\section{Method}{\if{latex}{\out{\sloppy}} Use dm_apply_vm_calibration_tbl for every stored signal. Missing stage entries remain NULL; present stage names and all timestamps remain unchanged. Invalid coefficients fail before a calibrated result is returned. The function neither refits the model nor validates its benefit on independent recordings.}

\section{Implementation}{\if{latex}{\out{\sloppy}} Implemented by \code{dm_apply_vm_calibration_bundle} in \code{R/m_dynamic.R}. See \code{\link{implementation-guide}} for the framework and function map.}
