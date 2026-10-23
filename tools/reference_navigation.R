# Build reference topic navigation.
reference_navigation <- function(html, escape) {
    groups <- list(
        "Getting started" = c("metronautica-package", "getting-started", "implementation-guide",
            "native-recording-examples", "feature-comparison"),
        "Common data format and diagnostics" = c("common-data-format", "parse_raw_auto", "as_accel_tbl",
            "accel_meta", "qc_accel_tbl", "attach_qc", "invalidate_qc", "m_load_sample_data", "clip_bundle"),
        "Static characterisation" = c("static_metrology_from_tbl", "static_noise_summary_from_tbl",
            "static_clip", "static_1hz_means", "static_offset_vm_5min", "static_drift",
            "static_axis_noise_metrics", "static_allan", "allan_nonoverlap", "static_allan_minima_wide"),
        "Dynamic characterisation" = c("clip_dynamic_stages", "dynamic_metrology_report", "m_dynamic_response"),
        "Feature extraction" = c("compute_accel_summaries", "accel_metric_vm", "accel_metric_enmo",
            "accel_metric_mad", "accel_metric_svmg", "accel_metric_svmbp", "accel_metric_odba",
            "accel_metric_rocam", "accel_metric_ai", "compute_ai_noise_var_from_static",
            "accel_metric_mims", "accel_metric_agcounts", "accel_metric_z_angle", "accel_metric_z_angle_change"),
        "Filtering and calibration" = c("filter_accel_tbl", "dm_fit_vm_calibration",
            "dm_apply_vm_calibration_tbl", "dm_apply_vm_calibration_bundle"),
        "Visualisation" = c("plot_accel_clip", "plot_processed_metric", "plot_static_drift_vm", "plot_static_allan"),
        "Measurement definitions" = "measurement-definitions")
    lines <- strsplit(html, "\n", fixed = TRUE)[[1L]]
    topics <- list()
    current <- NULL
    for (i in seq_along(lines)) {
        heading <- regexec("<h2 id='([^']+)'>(.*?)</h2>", lines[[i]], perl = TRUE)
        found <- regmatches(lines[[i]], heading)[[1L]]
        if (length(found)) {
            current <- found[[2L]]
            topics[[current]] <- list(title = found[[3L]], sections = character())
        }
        if (!is.null(current) && grepl("<h3>.*?</h3>", lines[[i]], perl = TRUE)) {
            title <- sub(".*<h3>(.*?)</h3>.*", "\\1", lines[[i]], perl = TRUE)
            slug <- tolower(gsub("<[^>]+>", "", title))
            slug <- gsub("[^a-z0-9]+", "-", slug)
            slug <- gsub("(^-|-$)", "", slug)
            id <- paste(current, slug, sep = "--")
            if (id %in% names(topics[[current]]$sections)) stop("Duplicate reference section: ", id)
            topics[[current]]$sections[[id]] <- title
            lines[[i]] <- sub("<h3>", paste0('<h3 id="', id, '">'), lines[[i]], fixed = TRUE)
        }
    }
    listed <- unlist(groups, use.names = FALSE)
    if (anyDuplicated(listed) || !setequal(listed, names(topics)))
        stop("Reference groups must cover every topic exactly once.")
    topic_item <- function(id) {
        topic <- topics[[id]]
        sections <- vapply(names(topic$sections), function(section) paste0(
            '<li><a href="#', section, '">', topic$sections[[section]], '</a></li>'), "")
        paste0('<li class="topic-item" data-topic="', id, '"><details>',
            '<summary><a class="topic-link" href="#', id, '"><code>', escape(id),
            '</code><span class="topic-title">', topic$title, '</span></a></summary>',
            '<ul class="topic-sections">', paste(sections, collapse = "\n"), '</ul></details></li>')
    }
    sections <- vapply(names(groups), function(group) paste0(
        '<section class="topic-group"><h3>', escape(group), '</h3><ul class="menu">',
        paste(vapply(groups[[group]], topic_item, ""), collapse = "\n"), '</ul></section>'), "")
    navigation <- paste0('<nav class="package" aria-label="Reference navigation">',
        '<h2>Reference index</h2><label for="topic-filter">Find topics or sections</label>',
        '<input id="topic-filter" type="search" placeholder="e.g. noise floor, epochs, QC" autocomplete="off">',
        '<p id="topic-results" class="topic-results" role="status" aria-live="polite"></p>',
        paste(sections, collapse = "\n"), '</nav>')
    html <- paste(lines, collapse = "\n")
    html <- sub('(?s)<nav class="package".*?</nav>', navigation, html, perl = TRUE)
    script <- paste0('<script src="assets/reference-navigation.js" defer></script>')
    sub('</body>', paste0(script, '</body>'), html, fixed = TRUE)
}
