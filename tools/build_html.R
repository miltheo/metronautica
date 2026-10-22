# Generate browser documentation from the README, Markdown guides and R help.
# Run from any directory: Rscript tools/build_html.R
args <- commandArgs(trailingOnly = FALSE)
script <- sub("^--file=", "", grep("^--file=", args, value = TRUE)[1L])
root <- dirname(dirname(normalizePath(script, winslash = "/", mustWork = TRUE)))
docs <- file.path(root, "docs")
for (pkg in c("commonmark", "V8")) {
    if (!requireNamespace(pkg, quietly = TRUE))
        stop("HTML documentation requires ", pkg, "; install it explicitly.")
}
if (!exists("pkg2HTML", asNamespace("tools"), inherits = FALSE))
    stop("HTML reference generation requires R with tools::pkg2HTML().")
read_text <- function(path) paste(readLines(path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
write_text <- function(text, path) {
    # R's help converter can emit trailing spaces in tables and example headings.
    text <- gsub("(?m)[ \t]+$", "", enc2utf8(text), perl = TRUE)
    writeLines(text, path, useBytes = TRUE)
}
# The installed help examples are the maintained code source for guides/scripts.
example_code <- function(file) {
    out <- tempfile(fileext = ".R")
    on.exit(unlink(out), add = TRUE)
    tools::Rd2ex(tools::parse_Rd(file.path(root, "man", file)), out = out,
        commentDontrun = FALSE)
    lines <- readLines(out, warn = FALSE, encoding = "UTF-8")
    lines <- lines[!grepl("^(###|## Not run:|## End\\(Not run\\))", lines)]
    while (length(lines) && !nzchar(trimws(lines[[1L]]))) lines <- lines[-1L]
    while (length(lines) && !nzchar(trimws(tail(lines, 1L)))) lines <- head(lines, -1L)
    lines
}
native <- example_code("native-study-examples.Rd")
write_text(paste(c("# Generated from man/native-study-examples.Rd by tools/build_html.R.",
    "# Set options(metronautica.sample_dir = \"path/to/wam/samples\") before running.",
    native), collapse = "\n"), file.path(root, "examples", "quick_start.R"))
offline <- example_code("getting-started.Rd")
offline <- offline[seq_len(grep("^# AI uses", offline)[[1L]] - 1L)]
static_start <- grep("^# Static characterisation", native)[[1L]]
dynamic_start <- grep("^# Dynamic characterisation", native)[[1L]]
feature_start <- grep("^# Feature extraction", native)[[1L]]
blocks <- list(offline = offline,
    static = c("library(metronautica)", native[(static_start + 1L):(dynamic_start - 1L)]),
    dynamic = c("library(metronautica)", native[(dynamic_start + 1L):(feature_start - 1L)]))
guide <- file.path(docs, "GETTING_STARTED.md")
text <- read_text(guide)
for (name in names(blocks)) {
    begin <- paste0("<!-- EXAMPLE:", name, ":start -->")
    end <- paste0("<!-- EXAMPLE:", name, ":end -->")
    a <- regexpr(begin, text, fixed = TRUE)[[1L]]
    b <- regexpr(end, text, fixed = TRUE)[[1L]]
    if (a < 0L || b < a) stop("Missing example markers for ", name)
    text <- paste0(substr(text, 1L, a + nchar(begin) - 1L), "\n```r\n",
        paste(blocks[[name]], collapse = "\n"), "\n```\n", substring(text, b))
}
write_text(text, guide)
escape <- function(x) {
    x <- gsub("&", "&amp;", x, fixed = TRUE)
    x <- gsub('"', "&quot;", x, fixed = TRUE)
    x <- gsub("<", "&lt;", x, fixed = TRUE)
    gsub(">", "&gt;", x, fixed = TRUE)
}
repo <- "https://github.com/miltheo/metronautica/blob/main/"
pages <- c("GETTING_STARTED.md" = "getting-started.html",
    "REAL_DATA_EXAMPLES.md" = "recording-examples.html",
    "MEASUREMENT_DEFINITIONS.md" = "measurement-definitions.html",
    "ACTIGRAPH_COUNTS.md" = "activity-counts.html",
    "DEPENDENCY_LICENSING.md" = "dependency-licensing.html",
    "README.md" = "documentation.html")
nav <- paste0('<nav class="site-nav" aria-label="Documentation">',
    '<a href="index.html">Workflow</a><a href="getting-started.html">Getting started</a>',
    '<a href="recording-examples.html">Recordings</a><a href="reference.html">Function reference</a>',
    '<a href="metronautica-reference.pdf">PDF</a>',
    '<a href="https://github.com/miltheo/metronautica">GitHub</a></nav>')
wrap <- function(body, title) paste0('<!doctype html><html lang="en-GB"><head>',
    '<meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">',
    '<title>', escape(title), ' | Metronautica</title>',
    '<link rel="stylesheet" href="assets/reference.css"></head><body>',
    nav, '<main class="guide">', body, '</main></body></html>')

# Coordinates refer to the approved 2048 x 768 image. The image is not altered.
# Each SVG link has an accessible name, native tooltip and visible focus outline.
regions <- list(
    list("native-recordings", 25, 90, 310, 126, "Native recordings: GENEActiv/SENS BIN, Axivity CWA/AX3 CSV, ActiGraph GT3X/LEAP CSV/LEAP AGSD, HBK G-Link CSV. See decoder limits below."),
    list(paste0(repo, "R/m_parsers.R"), 347, 89, 328, 72, "Open m_parsers.R: parse_raw_auto(qc = TRUE) decodes the native recording and attaches primary-five diagnostics."),
    list("acceleration-tibble", 660, 90, 360, 135, "Acceleration tibble: time (POSIXct, UTC), ax_g, ay_g, az_g (numeric, g). Attached meta holds acquisition settings, provenance and QC."),
    list("static-characterisation", 660, 307, 360, 205, "Static characterisation: select a stationary interval; sampling frequency, noise floor, signed offset bias, drift and Allan deviation."),
    list("dynamic-characterisation", 1060, 307, 260, 205, "Dynamic characterisation: specify a reference, range and stage schedule; response slope, bias, non-linearity and composite error."),
    list("feature-extraction-and-visual-comparison", 1360, 307, 315, 205, "Feature extraction and visual comparison: compute epoch summaries or counts and inspect processed-signal plots."),
    list("metrology-and-feature-reports", 1715, 307, 305, 205, "Reports: retain error estimates, units, resolved settings and provenance."),
    list("optional-calibration", 975, 558, 425, 107, "Optional calibration: fit and apply a VM mapping; independently validate benefit and repeat assessments."),
    list("reference.html#attach_qc", 337, 558, 361, 107, "attach_qc(): open documentation for recomputing and attaching diagnostics to the calibrated signal before reassessment.")
)
hotspots <- vapply(regions, function(r) sprintf(
    '<a href="%s" aria-label="%s"><title>%s</title><rect class="hotspot" x="%s" y="%s" width="%s" height="%s"/></a>',
    if (grepl("^(https://|reference.html)", r[[1L]])) r[[1L]] else paste0("#", r[[1L]]),
    escape(r[[6L]]), escape(r[[6L]]), r[[2L]], r[[3L]], r[[4L]], r[[5L]]), "")
diagram <- paste0('<svg class="workflow" viewBox="0 0 2048 768" role="group" aria-label="Interactive processing workflow">',
    '<image href="assets/workflow-dark.svg" width="2048" height="768"/>',
    paste(hotspots, collapse = "\n"), '</svg>')
markdown_html <- function(text, home = FALSE) {
    # Supply stable section anchors for CommonMark, which does not add GitHub IDs.
    lines <- strsplit(text, "\n", fixed = TRUE)[[1L]]
    in_code <- FALSE
    for (i in seq_along(lines)) {
        if (grepl("^```", lines[[i]])) in_code <- !in_code
        if (!in_code && grepl("^#{1,6} ", lines[[i]])) {
            slug <- tolower(sub("^#{1,6} +", "", lines[[i]]))
            slug <- gsub("[^a-z0-9 -]", "", slug)
            slug <- gsub(" +", "-", slug)
            if (!grepl(paste0('name="', slug, '"'), text, fixed = TRUE))
                lines[[i]] <- paste0('<a name="', slug, '"></a>\n', lines[[i]])
        }
    }
    body <- commonmark::markdown_html(paste(lines, collapse = "\n"), extensions = TRUE)
    for (source in names(pages)) {
        for (prefix in c("docs/", ""))
            body <- gsub(paste0('href="', prefix, source), paste0('href="', pages[[source]]), body, fixed = TRUE)
    }
    body <- gsub('href="../README.md', 'href="index.html', body, fixed = TRUE)
    body <- gsub('href="docs/index.html', 'href="index.html', body, fixed = TRUE)
    body <- gsub('href="docs/reference.html', 'href="reference.html', body, fixed = TRUE)
    body <- gsub('href="docs/metronautica-reference.pdf', 'href="metronautica-reference.pdf', body, fixed = TRUE)
    # Repository-only source, citation and validation links stay on GitHub.
    body <- gsub('href="(R/|man/|tools/|examples/|inst/|tests/)', paste0('href="', repo, '\\1'), body)
    body <- gsub('href="(DESCRIPTION|CITATION.cff|LICENSE.md)', paste0('href="', repo, '\\1'), body)
    body <- gsub('href="(validation/)', paste0('href="', repo, 'docs/\\1'), body)
    if (home) {
        body <- sub('<p><img[^>]*src="docs/assets/workflow-dark.svg"[^>]*></p>', diagram, body)
        # The browser guide needs no GitHub-viewer instruction.
        body <- sub('The <a href="index.html">HTML guide</a> makes the diagram boxes interactive\\. Open HTML\nlocally in a browser; GitHub\x27s file viewer displays its source\\.', "Click a diagram box to open its stage description.", body)
    }
    body
}
write_text(wrap(markdown_html(read_text(file.path(root, "README.md")), home = TRUE),
    "Processing workflow"), file.path(docs, "index.html"))
for (source in names(pages)) {
    text <- read_text(file.path(docs, source))
    title <- sub("^# +", "", strsplit(text, "\n", fixed = TRUE)[[1L]][[1L]])
    write_text(wrap(markdown_html(text), title), file.path(docs, pages[[source]]))
}

reference <- file.path(docs, "reference.html")
tools::pkg2HTML("metronautica", dir = root, out = reference,
    stylesheet = "assets/reference.css", prism = FALSE,
    hooks = list(pkg_href = function(pkg)
        sprintf("https://stat.ethz.ch/R-manual/R-release/library/%s/html/00Index.html", pkg)))
html <- read_text(reference)
# R's default navigation logo otherwise points at the build machine's R directory.
html <- gsub('<img class="toplogo"[^>]*>', "", html)
html <- sub('<body>', paste0('<body>', nav), html, fixed = TRUE)
html <- sub('<h2>Contents</h2>', paste0('<h2>Function and guide index</h2>',
    '<label for="topic-filter">Filter names</label>',
    '<input id="topic-filter" type="search" placeholder="e.g. static, QC, counts" autocomplete="off">'), html, fixed = TRUE)
search <- '<script>document.getElementById("topic-filter").addEventListener("input", function () { const query = this.value.toLowerCase(); document.querySelectorAll("nav.package li").forEach(function (item) { item.hidden = !item.textContent.toLowerCase().includes(query); }); });</script>'
html <- sub('</body>', paste0(search, '</body>'), html, fixed = TRUE)
write_text(html, reference)
cat("Built HTML guide, six linked guides and reference from current sources.\n")
