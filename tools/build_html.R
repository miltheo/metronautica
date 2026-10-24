# Build HTML from maintained documentation.
# Run tools/build_html.R from anywhere.
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
read_text <- function(path) {
    text <- paste(readLines(path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
    if (grepl("\u00c2[\u0080-\u00bf]|\u00c3[\u0080-\u00bf\u0192\u201a]|\u00e2[\u0080-\u00bf\u2010-\u203f\u20ac]|\ufffd", text, perl = TRUE))
        stop("Encoding-corrupted punctuation in ", path,
            "; restore the source encoding before rebuilding HTML.")
    text
}
write_text <- function(text, path) {
# Remove generated trailing whitespace.
    text <- gsub("(?m)[ \t]+$", "", enc2utf8(text), perl = TRUE)
    writeLines(text, path, useBytes = TRUE)
}
# Embed maintained example scripts.
native <- strsplit(read_text(file.path(root, "examples", "quick_start.R")), "\n", fixed = TRUE)[[1L]]
traces <- strsplit(read_text(file.path(root, "examples", "recording_traces.R")), "\n", fixed = TRUE)[[1L]]
trace_start <- grep("^# (Static trace|Dynamic trace|Signal diagnostics|Feature extraction|Processed feature trace)$", traces)
trace_block <- function(i) {
    end <- if (i < length(trace_start)) trace_start[i + 1L] - 1L else length(traces)
    trimws(paste(traces[(trace_start[i] + 1L):end], collapse = "\n"), which = "right")
}
static_start <- grep("^# Static characterisation", native)[[1L]]
dynamic_start <- grep("^# Dynamic characterisation", native)[[1L]]
feature_start <- grep("^# Feature extraction", native)[[1L]]
blocks <- list(static_trace = trace_block(1L), dynamic_trace = trace_block(2L),
    diagnostics = trace_block(3L),
    features = trace_block(4L), processed_trace = trace_block(5L),
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
site <- "https://miltheo.github.io/metronautica/"
pages <- c("GETTING_STARTED.md" = "getting-started.html",
    "MEASUREMENT_DEFINITIONS.md" = "measurement-definitions.html",
    "ACTIGRAPH_COUNTS.md" = "activity-counts.html",
    "DEPENDENCY_LICENSING.md" = "dependency-licensing.html",
    "README.md" = "documentation.html")
contract_source <- "data-contract/0.1.0/SPECIFICATION.md"
nav <- paste0('<nav class="site-nav" aria-label="Documentation">',
    '<a href="index.html">Workflow</a><a href="getting-started.html">Getting started</a>',
    '<a href="metronautica-tibble.html">Metronautica Tibble</a>',
    '<a href="reference.html">Function reference</a>',
    '<a href="metronautica-reference.pdf">PDF</a>',
    '<a href="https://github.com/miltheo/metronautica">GitHub</a></nav>')
wrap <- function(body, title) paste0('<!doctype html><html lang="en-GB"><head>',
    '<meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">',
    '<title>', escape(title), ' | Metronautica</title>',
    '<link rel="stylesheet" href="assets/reference.css"></head><body>',
    nav, '<main class="guide">', body, '</main></body></html>')

# Retain approved workflow image coordinates.
# Provide accessible workflow links.
regions <- list(
    list("native-recordings", 25, 90, 310, 126, "Native recordings: GENEActiv/SENS BIN, Axivity CWA/AX3 CSV, ActiGraph GT3X/LEAP CSV/LEAP AGSD, HBK G-Link CSV. See decoder limits below."),
    list(paste0(repo, "R/m_parsers.R"), 347, 89, 328, 72, "Open m_parsers.R: parse_raw_auto(qc = TRUE) decodes the native recording and attaches primary-five diagnostics."),
    list("metronautica-tibble", 660, 90, 360, 135, "Metronautica Tibble 0.1.0: only time (POSIXct), ax_g, ay_g, az_g (numeric g) are required. Metadata, diagnostics and reports are optional pipeline additions."),
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
# Add stable Markdown section anchors.
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
# Keep hosted links local.
    body <- gsub(paste0('href="', site, '"'), 'href="index.html"', body, fixed = TRUE)
    body <- gsub(paste0('href="', site), 'href="', body, fixed = TRUE)
    for (prefix in c("../", "")) {
        body <- gsub(paste0('href="', prefix, contract_source),
            'href="metronautica-tibble.html', body, fixed = TRUE)
        body <- gsub(paste0('href="', prefix, 'data-contract/README.md'),
            'href="../data-contract/README.md', body, fixed = TRUE)
    }
    # Resolve links from the versioned specification and the main guides.
    body <- gsub('href="../../docs/reference.html', 'href="reference.html', body, fixed = TRUE)
    body <- gsub('href="../../examples/', paste0('href="', repo, 'examples/'), body, fixed = TRUE)
    body <- gsub('href="../examples/', paste0('href="', repo, 'examples/'), body, fixed = TRUE)
    body <- gsub('href="../README.md">Specification index',
        'href="../data-contract/README.md">Specification index', body, fixed = TRUE)
    for (source in names(pages)) {
        for (prefix in c("docs/", ""))
            body <- gsub(paste0('href="', prefix, source), paste0('href="', pages[[source]]), body, fixed = TRUE)
    }
    body <- gsub('href="../data-contract/README.md#structure"',
        'href="metronautica-tibble.html#structure"', body, fixed = TRUE)
    body <- gsub('href="../data-contract/README.md',
        paste0('href="', repo, 'data-contract/README.md'), body, fixed = TRUE)
    body <- gsub('href="../README.md', 'href="index.html', body, fixed = TRUE)
    body <- gsub('href="docs/index.html', 'href="index.html', body, fixed = TRUE)
    body <- gsub('href="docs/reference.html', 'href="reference.html', body, fixed = TRUE)
    body <- gsub('href="docs/metronautica-reference.pdf', 'href="metronautica-reference.pdf', body, fixed = TRUE)
# Keep repository-only links on GitHub.
    body <- gsub('href="(R/|man/|tools/|examples/|inst/|tests/)', paste0('href="', repo, '\\1'), body)
    body <- gsub('href="(DESCRIPTION|CITATION.cff|LICENSE.md)', paste0('href="', repo, '\\1'), body)
    body <- gsub('href="(validation/)', paste0('href="', repo, 'docs/\\1'), body)
# Inline shared SVG guides.
    for (asset in c("tibble-structure", "epoch-labels", "calibration-validation")) {
        filename <- paste0(asset, ".svg")
        svg <- read_text(file.path(docs, "assets", "guides", filename))
        svg <- sub('role="img"', 'class="guide-diagram" role="group"', svg, fixed = TRUE)
        figure <- paste0('<div class="visual-guide">', svg,
            '<a class="diagram-open" href="assets/guides/', filename, '">Open diagram</a></div>')
        body <- gsub(paste0('<p><img[^>]*src="[^"]*assets/guides/',
            asset, '[.]svg"[^>]*></p>'), figure, body)
    }
    if (home) {
        body <- sub('<p><img[^>]*src="docs/assets/workflow-dark.svg"[^>]*></p>', diagram, body)
# Omit duplicated browser navigation.
        body <- sub('(?s)<p><a href="getting-started.html">Getting started</a> \\|.*?</p>\\n', "", body, perl = TRUE)
        body <- sub('(?s)<p><a href="#native-recordings"[^>]*>Native recordings</a>.*?</p>\\n', "", body, perl = TRUE)
        body <- sub('The browser guide provides clickable diagram boxes\\.',
            "Click a diagram box for details.", body)
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
# Reuse the contract index visual.
contract <- read_text(file.path(root, contract_source))
contract_index <- read_text(file.path(root, "data-contract", "README.md"))
contract_visual <- sub("(?s).*<!-- GUIDE:tibble:start -->(.*?)<!-- GUIDE:tibble:end -->.*",
    "\\1", contract_index, perl = TRUE)
if (identical(contract_visual, contract_index)) stop("Missing contract visual markers")
contract_visual <- gsub("../docs/assets/", "assets/", contract_visual, fixed = TRUE)
contract <- sub("# Metronautica Tibble", paste0("# Metronautica Tibble\n<a name=\"structure\"></a>\n", contract_visual),
    contract, fixed = TRUE)
write_text(wrap(markdown_html(contract), "Metronautica Tibble 0.1.0"),
    file.path(docs, "metronautica-tibble.html"))

reference <- file.path(docs, "reference.html")
tools::pkg2HTML("metronautica", dir = root, out = reference,
    stylesheet = "assets/reference.css", prism = FALSE,
    hooks = list(pkg_href = function(pkg)
        sprintf("https://stat.ethz.ch/R-manual/R-release/library/%s/html/00Index.html", pkg)))
html <- read_text(reference)
for (source in names(pages)) {
    html <- gsub(paste0(repo, "docs/", source), pages[[source]], html, fixed = TRUE)
}
html <- gsub(paste0(repo, contract_source), "metronautica-tibble.html", html, fixed = TRUE)
html <- gsub(paste0(repo, "README.md"), "index.html", html, fixed = TRUE)
# Resolve guide help anchors.
package_rd <- tools::parse_Rd(file.path(root, "man", "metronautica-package.Rd"))
guide_aliases <- vapply(Filter(function(x) identical(attr(x, "Rd_tag"), "\\alias"),
    package_rd), paste, "", collapse = "")
guide_aliases <- setdiff(guide_aliases, "metronautica-package")
alias_anchors <- paste0('<a id="', guide_aliases, '"></a>', collapse = "")
html <- sub("<h2 id='metronautica-package'>",
    paste0(alias_anchors, "<h2 id='metronautica-package'>"), html, fixed = TRUE)

# Remove build-machine logo references.
html <- gsub('<img class="toplogo"[^>]*>', "", html)
# Use the offline ORCID icon.
html <- gsub("https://cloud.R-project.org/web/resources/orcid.svg",
    "assets/orcid.svg", html, fixed = TRUE)
html <- sub('<body>', paste0('<body>', nav), html, fixed = TRUE)
source(file.path(root, "tools", "reference_navigation.R"))
html <- reference_navigation(html, escape)
write_text(html, reference)
cat("Built workflow, five linked guides, tibble specification and reference from current sources.\n")
