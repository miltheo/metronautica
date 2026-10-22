\name{implementation-guide}
\alias{implementation-guide}
\title{Framework and function map}
\description{\if{latex}{\out{\sloppy}} Connect the public functions, source files and implemented measurement outcomes. Function help documents the resolved parameters; this guide identifies the measurement represented by each stage.}
\section{Common data format and signal diagnostics}{\if{latex}{\out{\sloppy}}
\code{R/m_parsers.R} implements decoding to POSIXct time and triaxial acceleration in g. Stored device coefficients may already be applied during decoding; native does not mean unscaled integer counts. Consult \code{\link{parse_raw_auto}} for the supported format and validated LEAP scope.

\code{R/m_qc.R} implements five post-parse signal diagnostic groups. \code{\link{qc_accel_tbl}} explains exact numerators, denominators, sequence eligibility and the near-limit threshold. These are operational screening rules, not a sensor acceptance standard. \code{\link{attach_qc}} stores the results; \code{\link{invalidate_qc}} removes diagnostics that no longer describe a modified signal.
}
\section{Static characterisation}{\if{latex}{\out{\sloppy}}
\code{R/m_static.R} implements static characterisation outcomes. \code{\link{static_1hz_means}} supplies one-second means; \code{\link{static_drift}} fits signed g/h slopes; \code{\link{static_offset_vm_5min}} estimates the specified initial VM offset relative to 1 g. \code{\link{static_axis_noise_metrics}} separates raw sample SD from the residual SD after linear detrending. The static noise floor is the maximum axis-specific detrended residual SD, not the Activity Index stationary variance.

\code{\link{static_allan}} uses \code{\link{allan_nonoverlap}} for non-overlapping cluster means. Its returned axis minima and evaluated averaging times are separate from the maximum across individual axis minima. Supplying a stationary window and assessing environmental stability remain experimental responsibilities.
}
\section{Dynamic characterisation and calibration}{\if{latex}{\out{\sloppy}}
\code{R/m_dynamic.R} implements explicit stage selection and VM response calculations. \code{\link{m_dynamic_response}} fits test VM on reference VM and returns signed bias, response slope/intercept and residual-based errors. The stage normalising span is sqrt(3) times the test-axis peak-to-peak span; the composite denominator is half that span. These operational definitions do not imply that VM occupies the symmetric axis measurement interval.

\code{\link{dynamic_metrology_report}} reports within-stage epoch-mean VM CV as a fraction. It is not trial-to-trial repeatability CV. Trial aggregation, activation threshold, deadband estimation, inter-device equivalence and Holm-adjusted regional tests are provided by WAM (\url{https://github.com/miltheo/wam}). The report's activation/deadband columns are unestimated placeholders.

Reference length matching remains nearest selection on an evenly spaced sample-index grid. Stage-wise and pooled matching are separate. Neither that operation nor diagnostic cross-correlation constitutes timestamp correction. \code{\link{dm_fit_vm_calibration}} estimates a VM mapping; \code{\link{dm_apply_vm_calibration_tbl}} applies that mapping and invalidates inherited QC. Independent validation is required to assess benefit outside the fitting recording.
}
\section{Application-specific features}{\if{latex}{\out{\sloppy}}
\code{R/m_accel_summary_suite.R} implements time-domain feature definitions and configurable alternatives. The exact operation and unit are given in each \code{accel_metric_*} help page. \code{\link{compute_accel_summaries}} combines requested features and returns resolved pipeline settings.

Epoch duration, sampling treatment, axis filtering, noise correction, calibration state and aggregation are part of a feature pipeline. ENMO truncates negative VM-minus-1-g values per sample; SVMgs variants use absolute differences. MAD is centred within the epoch. ROCAM is a sample-to-sample acceleration-change outcome with no elapsed-time division. The package does not infer physical activity, sleep, energy expenditure or behavioural validity from these features.
}
\section{Standalone activity counts}{\code{\link{accel_metric_agcounts}} in R/m_agcounts.R implements the acknowledged published count algorithm and explicit custom-filter alternatives. It operates as a standalone function, outside the summary selector. Report input precision, gap and boundary policies as well as filter/epoch settings; processing flags are not a complete uncertainty budget.}
\section{Error and uncertainty reporting}{\if{latex}{\out{\sloppy}}
VIM terminology and the cited IEEE sensor terminology/performance standards are used to distinguish measurement quantities and properties. The package returns operational estimates; it does not establish traceability or a complete uncertainty budget by itself. Report the reference, tested range, signal state, sampling/epoch/filter settings, timing diagnostics and units. Residual errors, between-unit variability and uncertainty of a downstream estimate are distinct quantities. See \code{\link{measurement-definitions}} for the calculation definitions.
}
\references{\if{latex}{\out{\sloppy}}
Joint Committee for Guides in Metrology (2012). International vocabulary of metrology: Basic and general concepts and associated terms, JCGM 200:2012. \doi{10.59161/JCGM200-2012}.

IEEE (2018). IEEE Std 2700-2017, Standard for Sensor Performance Parameter Definitions. \doi{10.1109/IEEESTD.2018.8277147}.

IEEE (2019). IEEE Std 1293-2018, Standard Specification Format Guide and Test Procedure for Linear Single-Axis, Nongyroscopic Accelerometers. \doi{10.1109/IEEESTD.2019.8653544}.

Bai et al. (2016). An activity index for raw accelerometry data and its comparison with other activity metrics. \doi{10.1371/journal.pone.0160644}.

Neishabouri et al. (2022). Quantification of acceleration as activity counts in ActiGraph wearable. \doi{10.1038/s41598-022-16003-x}.
}
\seealso{\code{\link{metronautica-package}}, \code{\link{measurement-definitions}}, \code{\link{native-recording-examples}}}

\section{Input and return contracts}{\if{latex}{\out{\sloppy}}
Raw-signal helpers accept the common four-column acceleration table or data/full bundles; extracting a bundle does not imply selecting, sorting or repairing samples. The table's metadata attribute is authoritative, with top-level meta as a fallback. Calculation helpers generally return a derived result, rather than the original container. Container behaviour depends on the operation: static_clip always returns an acceleration table; clip_dynamic_stages creates a new stage bundle; clip_bundle, QC helpers, filtering and calibration preserve their documented table/bundle form. For a dynamic stage bundle, filter_accel_tbl and clip_bundle modify only the selected full recording, leaving existing stages unchanged. Filter or clip the recording before constructing the stage bundle; do not use the unchanged stages as filtered or newly clipped data. Calibration application explicitly processes the stored stages as well as the full recording.

Derived-input helpers are deliberately different: static_drift and static_offset_vm_5min require one-second means; Allan-minimum/plot functions require an Allan table; allan_nonoverlap requires a numeric axis series; dynamic reporting and fitting require corresponding named stage bundles. m_dynamic_response also accepts numeric VM vectors. Parsers/sample loaders take paths or sample selectors, not acceleration tables. These distinctions follow the quantity each function calculates rather than imposing a common shell API.
}
