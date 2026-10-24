# Run tools/validate.R after installation.
script <- sub("^--file=", "", grep("^--file=", commandArgs(), value = TRUE)[1L])
root <- dirname(dirname(normalizePath(script, winslash = "/", mustWork = TRUE)))
for (name in c("check_engine.R", "check_compatibility.R", "check_direct_api.R", "check_feature_defaults.R",
    "check_priority_defaults.R", "check_input_contracts.R", "check_calibration_provenance.R", "check_counts.R",
    "check_report_attachment.R")) {
    source(file.path(root, "tests", name), chdir = FALSE)
}
