\name{common-data-format}
\alias{common-data-format}
\title{Acceleration data and metadata contract}
\description{\if{latex}{\out{\sloppy}} The common data format shared by parsing, metrology and feature functions.}
\details{\if{latex}{\out{\sloppy}}
An \code{accel_tbl} is a tibble with exactly four columns: \code{time} (POSIXct), \code{ax_g}, \code{ay_g}, \code{az_g} (numeric acceleration in g, where 1 g corresponds to 9.80665 m/s squared). UTC is the storage convention. No unit inference is performed by the constructor. Preserve acquisition timestamps, gaps and invalid observations until the corresponding diagnostics have been inspected.

The \code{meta} attribute is a list. \code{acquisition} contains available device identifiers, \code{fs_nominal_hz}, \code{fs_derived_hz}, \code{full_scale_range_g}, recording bounds and time provenance. Range denotes the full axis span, not the positive limit. \code{file} records source information; \code{processing} records parser/calibration details, QC and history. Additional provenance can be retained. A parser bundle is \code{list(data = x, meta = accel_meta(x))}; keep these two metadata representations synchronised when constructing bundles externally.

The constructor \code{as_accel_tbl()} preserves the supplied metadata. It neither attaches QC nor estimates sampling frequency. Call \code{attach_qc()} explicitly to attach diagnostics; parsing through \code{parse_raw_auto()} enables QC by default. Parser paths populate available acquisition settings; feature functions resolve a missing rate as documented below. The constructor does not sort or repair the recording. \code{accel_meta()} returns the attached metadata. Subsetting externally may retain stale whole-recording QC; recompute it or use the provided clipping functions. Filtering invalidates inherited QC. Static/dynamic stage clipping recomputes QC for each selected window.

Feature rate resolution uses an explicit \code{fs_hz}, then metadata, then timestamps.

Axis filtering with \code{filter_accel_tbl()} requires \code{fs_derived_hz}. A nominal or timestamp-derived rate is not an independently validated clock rate. Sample-based filters and index pairing require appropriate regularity/synchronisation beyond the presence of metadata.
}
\seealso{\code{\link{getting-started}}, \code{\link{metronautica-package}}, \code{\link{as_accel_tbl}}, \code{\link{qc_accel_tbl}}, \code{\link{clip_bundle}}}
