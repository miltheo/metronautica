# Retrieve verified native sample recordings.
# Input: sample selection and location.
# Output: native paths with provenance.

m_load_sample_data <- function(device = "LEAP", type = "static", dest_dir = file.path(getwd(), "metronautica-samples"),
    overwrite = FALSE, sample_dir = NULL, include_reference = TRUE, base_url = getOption("metronautica.sample_base_url",
        NULL)) {
    if (!is.character(device) || length(device) != 1L || is.na(device))
        stop("device must be LEAP, AX3, SENS or GENEActiv.", call. = FALSE)
    device <- match.arg(toupper(device), c("LEAP", "AX3", "SENS", "GENEACTIV"))
    type <- match.arg(tolower(type), c("static", "dynamic"))
    for (flag in list(overwrite = overwrite, include_reference = include_reference)) if (!is.logical(flag) ||
        length(flag) != 1L || is.na(flag))
        stop("overwrite and include_reference must be TRUE or FALSE.", call. = FALSE)
    if (!is.character(dest_dir) || length(dest_dir) != 1L || is.na(dest_dir) || !nzchar(dest_dir))
        stop("dest_dir must be one non-empty directory path.", call. = FALSE)
    if (is.null(sample_dir))
        sample_dir <- getOption("metronautica.sample_dir", NULL)
    if (!is.null(sample_dir) && (!is.character(sample_dir) || length(sample_dir) != 1L || is.na(sample_dir) ||
        !dir.exists(sample_dir)))
        stop("sample_dir must be an existing directory containing sample_index.csv.", call. = FALSE)
    if (!is.null(base_url)) {
        if (!is.character(base_url) || length(base_url) != 1L || is.na(base_url) || !grepl("^(https://|file:///)",
            base_url))
            stop("base_url must be an HTTPS release-asset directory (or file:/// directory for offline use).",
                call. = FALSE)
        base_url <- sub("/+$", "", base_url)
    }

    # Select configured sample catalogue ----
    catalog <- if (!is.null(sample_dir))
        file.path(sample_dir, "sample_index.csv") else system.file("extdata", "native", "sample_index.csv", package = "metronautica")
    if (!nzchar(catalog) || !file.exists(catalog))
        stop("Sample catalogue unavailable. Install metronautica or supply sample_dir containing sample_index.csv.",
            call. = FALSE)
    index <- utils::read.csv(catalog, stringsAsFactors = FALSE)
    required <- c("device", "type", "file_name", "storage_file", "native_sha256", "storage_sha256")
    if (!all(required %in% names(index)))
        stop("Sample catalogue is missing required fields.", call. = FALSE)

    # Validate filenames and checksums ----
    select_row <- function(device, type) {
        row <- index[index$device == device & index$type == type, , drop = FALSE]
        if (nrow(row) != 1L)
            stop("The selected sample is missing or ambiguous.", call. = FALSE)
        for (name in c("file_name", "storage_file")) {
            value <- row[[name]]
            if (is.na(value) || !nzchar(value) || value %in% c(".", "..") || grepl("[/\\\\:]", value))
                stop("Sample filenames must not contain directories.", call. = FALSE)
        }
        for (name in c("native_sha256", "storage_sha256")) if (is.na(row[[name]]) || !grepl("^[0-9a-fA-F]{64}$",
            row[[name]]))
            stop("Invalid sample checksum in catalogue.", call. = FALSE)
        row
    }
    row <- select_row(device, type)
    reference <- if (type == "dynamic" && include_reference)
        select_row("REFERENCE", "dynamic") else NULL

    # Retrieve or reuse verified files ----
    copy_sample <- function(row) {
        target <- file.path(dest_dir, row$file_name)
        same <- file.exists(target) && digest::digest(file = target, algo = "sha256") == tolower(row$native_sha256)
        if (file.exists(target) && !same && !overwrite)
            stop("A different file already exists: ", target, "; choose another dest_dir or use overwrite = TRUE.",
                call. = FALSE)
        if (!same) {
            source <- if (!is.null(sample_dir))
                file.path(sample_dir, row$storage_file) else ""
            downloaded <- NULL
            on.exit(if (!is.null(downloaded)) unlink(downloaded), add = TRUE)
            if (!nzchar(source) || !file.exists(source)) {
                if (is.null(base_url))
                  stop("Native study samples are distributed separately through WAM. Supply sample_dir (or options(metronautica.sample_dir = ...)) for local files, or configure base_url/options(metronautica.sample_base_url = ...) with the fixed WAM sample-release URL. See help('m_load_sample_data').",
                    call. = FALSE)

                # Download compressed recording ----
                downloaded <- tempfile("metronautica-download-", fileext = ".gz")
                timeout_before <- options(timeout = max(300, getOption("timeout", 60)))
                on.exit(options(timeout_before), add = TRUE)
                url <- paste0(base_url, "/", utils::URLencode(row$storage_file, reserved = TRUE))
                failure <- NULL
                status <- tryCatch(suppressWarnings(utils::download.file(url, downloaded, mode = "wb",
                  method = "libcurl", quiet = TRUE)), error = function(e) {
                  failure <<- conditionMessage(e)
                  1L
                })
                if (status != 0L || !file.exists(downloaded))
                  stop("Unable to retrieve sample ", row$file_name, ". Check the release URL/network or supply sample_dir for offline use.",
                    if (!is.null(failure))
                      paste0(" ", failure), call. = FALSE)
                source <- downloaded
            }
            if (digest::digest(file = source, algo = "sha256") != tolower(row$storage_sha256))
                stop("Compressed sample checksum does not match: ", row$storage_file, call. = FALSE)
            dir.create(dest_dir, recursive = TRUE, showWarnings = FALSE)
            if (!dir.exists(dest_dir))
                stop("Cannot create dest_dir.", call. = FALSE)
            staged <- tempfile(".metronautica-sample-", tmpdir = dest_dir)
            on.exit(unlink(staged), add = TRUE)

            # Restore native recording bytes ----
            input <- gzfile(source, "rb")
            output <- file(staged, "wb")
            tryCatch({
                repeat {
                  bytes <- readBin(input, "raw", n = 4L * 1024L * 1024L)
                  if (!length(bytes))
                    break
                  writeBin(bytes, output)
                }
            }, finally = {
                close(input)
                close(output)
            })
            if (digest::digest(file = staged, algo = "sha256") != tolower(row$native_sha256))
                stop("Restored sample checksum does not match: ", row$file_name, call. = FALSE)
            # Replace files only after verification.
            if (file.exists(target) && !file.remove(target))
                stop("Cannot replace target: ", target, call. = FALSE)
            if (!file.rename(staged, target))
                stop("Cannot place restored sample: ", target, call. = FALSE)
        }
        target <- normalizePath(target, winslash = "/", mustWork = TRUE)
        jsonlite::write_json(as.list(row), paste0(target, ".json"), pretty = TRUE, auto_unbox = TRUE)
        attr(target, "sample_info") <- as.list(row)
        target
    }

    # Attach recording provenance ----
    target <- copy_sample(row)
    if (!is.null(reference)) {
        ref_path <- copy_sample(reference)
        attr(target, "reference_file") <- as.character(ref_path)
        attr(target, "reference_info") <- attr(ref_path, "sample_info")
    }
    target
}
