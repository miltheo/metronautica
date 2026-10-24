\name{common-data-format}
\alias{common-data-format}
\alias{metronautica-tibble}
\title{Metronautica Tibble 0.1.0}
\description{\if{latex}{\out{\sloppy}} The sample-level acceleration data contract used by Metronautica.}
\details{\if{latex}{\out{\sloppy}}
Only four data columns are required, in this order:
\describe{
\item{time}{Sample timestamps of class POSIXct. UTC is the storage convention; the constructor preserves supplied instants and timezone.}
\item{ax_g, ay_g, az_g}{Numeric acceleration on the device X, Y and Z axes in \eqn{g}; 1 \eqn{g} = 9.80665 m/s squared.}
}
Columns have equal length, with one row per decoded observation. Missing/non-finite observations and timestamp defects are retained for diagnostics. Structural conformance does not establish signal quality or suitability for an analysis.

\code{as_accel_tbl()} returns an \code{accel_tbl} inheriting from \code{tbl_df}. No metadata field, class tag, version field, diagnostic or attachment is required for core conformance. The full versioned specification and optional field catalogue are in \href{https://github.com/miltheo/metronautica/blob/main/data-contract/0.1.0/SPECIFICATION.md}{data-contract/0.1.0/SPECIFICATION.md} in the repository.
}
\section{Optional pipeline implementations}{\if{latex}{\out{\sloppy}}
Optional \code{meta} contains \code{file}, \code{acquisition} and \code{processing} sections, read by \code{accel_meta()}. Parser bundles use \code{list(data = x, meta = accel_meta(x))}; table metadata takes precedence over bundle metadata. Individual analyses may require settings or explicit arguments beyond core conformance.

Parsing attaches primary-five diagnostics by default; \code{as_accel_tbl()} does not. Use \code{attach_qc()} for decoded samples. Diagnostics are the recommended minimum workflow assessment; unknown range makes near-limit results unavailable.

Static/noise and dynamic report functions default to \code{attach_report = TRUE}. Capture \code{result$data} to retain assessments at \code{meta$processing$reports$static} or \code{dynamic}; FALSE adds no record. Records retain results, assessed source/selection, settings, diagnostics and provenance; plots and raw signal copies remain separate. Records become historical after package clipping/filtering/calibration. External edits can leave stale records. Assessment schema \code{"1"} is versioned separately from this contract.

RDS retains typed samples and attachments. Keep native files, unfiltered samples, provenance and feature settings for later metric calculations when their input requirements are met. Epoch summaries cannot reconstruct original samples.
}
\section{Input and return contracts}{\if{latex}{\out{\sloppy}}
Raw-signal helpers accept four-column acceleration tables or data/full bundles. Unwrapping does not select, sort or repair samples. Table metadata takes precedence over top-level meta.
\describe{
\item{Container operations}{static_clip returns a table; clip_dynamic_stages creates a stage bundle. Generic clipping, QC, filtering and calibration preserve their documented input form.}
\item{Stage bundles}{filter_accel_tbl and clip_bundle change only full; existing stages remain unchanged. Perform these operations before constructing stages. Calibration application processes full and stages.}
\item{Derived inputs}{static_drift and static_offset_vm_5min require one-second means; Allan-minimum/plot helpers require an Allan table; allan_nonoverlap requires a numeric axis series. Dynamic reporting/fitting requires corresponding named stage bundles; m_dynamic_response also accepts numeric VM vectors. Parsers/loaders take paths or sample selectors.}
}
Calculation helpers return derived results rather than the original container.
}

\seealso{\code{\link{as_accel_tbl}}, \code{\link{qc_accel_tbl}}, \code{\link{compute_accel_summaries}}, \code{\link{getting-started}}}
