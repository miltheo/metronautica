\name{common-data-format}
\alias{common-data-format}
\title{Acceleration data and metadata contract}
\description{\if{latex}{\out{\sloppy}} The common data format shared by parsing, metrology and feature functions.}
\details{\if{latex}{\out{\sloppy}}
An \code{accel_tbl} has exactly four columns: \code{time} (POSIXct), \code{ax_g}, \code{ay_g}, \code{az_g} (numeric \eqn{g}; 1 \eqn{g} = 9.80665 m/s squared). UTC is the storage convention; the constructor preserves supplied instants/timezones without inferring units. Retain timestamps, gaps and invalid observations until diagnostics are inspected.

The \code{meta} list contains \code{acquisition} (identifiers, fs_nominal_hz, fs_derived_hz, full_scale_range_g, bounds, time provenance), \code{file} (source), and \code{processing} (parser/calibration, QC, history). Additional provenance is permitted. Range means full axis span, not positive limit. A parser bundle is \code{list(data = x, meta = accel_meta(x))}; keep both metadata representations synchronised.

\code{as_accel_tbl()} preserves metadata without estimating rate, attaching QC, sorting or repairing samples. \code{accel_meta()} reads it. Parsing enables QC by default; otherwise use \code{attach_qc()}. External subsetting can leave stale QC. Filtering invalidates QC; static/dynamic clipping recomputes it per window.

Feature rate precedence: explicit \code{fs_hz}, metadata, then timestamps. Axis filtering requires metadata \code{fs_derived_hz}. Neither nominal nor timestamp-derived rate independently validates a clock. Filters and index pairing additionally require suitable regularity/synchronisation.
}
\section{Sample-level feature inputs and epochs}{\if{latex}{\out{\sloppy}}
Feature helpers accept common-format tables or bundles with \code{data}/\code{full}. Table metadata takes precedence over bundle meta. Unwrapping preserves values/metadata without repairing samples; feature selection adds no calibration.

Unless documented otherwise, positive \code{epoch_s} defines elapsed-time bins from the first sample, retaining the final partial epoch. Different durations define different pipelines. The summary dispatcher sorts by timestamp; the constructor does not.

\code{anchor} selects an observed sample: start = first, end = last, center = ceiling of half the epoch sample count. Labels do not affect values. Activity Index uses one-second bin starts; MIMS retains upstream conventions; counts have separate boundaries. See \code{\link{compute_accel_summaries}} for exact-timestamp joins and feature settings.
}
\seealso{\code{\link{getting-started}}, \code{\link{metronautica-package}}, \code{\link{as_accel_tbl}}, \code{\link{qc_accel_tbl}}, \code{\link{clip_bundle}}}
