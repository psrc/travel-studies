# Extract variables (columns) used by the codebase from the HTS RDS schemas.
#
# Primary output: a table of (table, column) that appear to be referenced in code.
# Secondary output: a filtered version of schema_diffs.csv limited to used columns.
#
# Usage (from repo root):
#   Rscript scripts/extract_used_variables.R
#
# Optional args:
#   --root=<path>       Root folder containing Cleaned_* and Dataset_* (default: hts_data_for_weighting)
#   --cleaned=<path>    Explicit Cleaned_* folder path
#   --code=<path>       Code root to scan (default: repo root / current working directory)
#   --out-vars=<path>   Output CSV for used variables (default: used_variables.csv)
#   --diffs=<path>      Input schema diffs CSV (default: schema_diffs.csv)
#   --out-diffs=<path>  Output CSV for filtered diffs (default: schema_diffs_used.csv)
#   --include-manual=<true|false>  Include manual/*.qmd in scan (default: true)
#
# Notes
# - This is heuristic static analysis: a column is considered "used" if its name appears in code
#   as a standalone token (word-ish boundary). This errs slightly on the side of including.

parse_args <- function(argv) {
  args <- list(
    root = file.path(getwd(), "hts_data_for_weighting"),
    cleaned = NA_character_,
    code = getwd(),
    out_vars = file.path(getwd(), "used_variables.csv"),
    diffs = file.path(getwd(), "schema_diffs.csv"),
    out_diffs = file.path(getwd(), "schema_diffs_used.csv"),
    include_manual = TRUE
  )

  for (a in argv) {
    if (!grepl("^--[^=]+=", a)) next
    key <- sub("^--([^=]+)=.*$", "\\1", a)
    val <- sub("^--[^=]+=", "", a)

    if (key == "include-manual") {
      args$include_manual <- tolower(val) %in% c("true", "t", "1", "yes", "y")
      next
    }

    key2 <- gsub("-", "_", key)
    if (key2 %in% names(args)) args[[key2]] <- val
  }

  args
}

pick_latest_dir <- function(root, prefix) {
  dirs <- list.dirs(root, full.names = TRUE, recursive = FALSE)
  dirs <- dirs[grepl(paste0("^", prefix, "_"), basename(dirs))]
  if (length(dirs) == 0) return(NA_character_)
  dirs[order(basename(dirs), decreasing = TRUE)][1]
}

as_table_like <- function(x) {
  if (is.data.frame(x)) return(x)
  if (inherits(x, "data.table")) return(as.data.frame(x))
  if (inherits(x, "tbl")) return(as.data.frame(x))
  NULL
}

get_columns_from_rds <- function(path) {
  obj <- readRDS(path)
  tab <- as_table_like(obj)
  if (is.null(tab)) {
    stop("RDS object is not a data.frame/data.table-like table; got class: ", paste(class(obj), collapse = "/"))
  }
  cn <- names(tab)
  if (is.null(cn)) cn <- character(0)
  cn
}

list_rds_files <- function(dir_path) {
  list.files(dir_path, pattern = "\\.rds$", full.names = TRUE, ignore.case = TRUE)
}

base_name_no_ext <- function(path) {
  sub("\\.rds$", "", basename(path), ignore.case = TRUE)
}

extract_identifier_tokens <- function(text) {
  m <- gregexpr("[A-Za-z][A-Za-z0-9_]*", text, perl = TRUE)
  toks <- regmatches(text, m)[[1]]
  unique(toks)
}

read_text_file_safe <- function(path) {
  x <- tryCatch(readLines(path, warn = FALSE, encoding = "UTF-8"), error = function(e) NULL)
  if (is.null(x)) return("")
  paste(x, collapse = "\n")
}

main <- function() {
  args <- parse_args(commandArgs(trailingOnly = TRUE))

  if (!dir.exists(args$root)) stop("Root folder not found: ", args$root)
  if (!dir.exists(args$code)) stop("Code folder not found: ", args$code)

  cleaned_dir <- args$cleaned
  if (is.na(cleaned_dir) || cleaned_dir == "") cleaned_dir <- pick_latest_dir(args$root, "Cleaned")
  if (is.na(cleaned_dir) || !dir.exists(cleaned_dir)) {
    stop("Cleaned folder not found. Provide --cleaned=<path> or ensure a Cleaned_* folder exists under: ", args$root)
  }

  # Gather code files
  r_files <- list.files(file.path(args$code, "R"), pattern = "\\.R$", full.names = TRUE, recursive = TRUE)
  qmd_files <- character(0)
  if (isTRUE(args$include_manual)) {
    qmd_files <- list.files(file.path(args$code, "manual"), pattern = "\\.qmd$", full.names = TRUE, recursive = TRUE)
  }
  code_files <- unique(c(r_files, qmd_files))

  message("Extracting used variables")
  message("- Cleaned: ", cleaned_dir)
  message("- Code files scanned: ", length(code_files))

  # Read all code once
  code_texts <- lapply(code_files, read_text_file_safe)
  names(code_texts) <- code_files
  combined_code <- paste(code_texts, collapse = "\n")
  code_tokens <- extract_identifier_tokens(combined_code)

  # Read schemas from Cleaned RDS files
  cleaned_files <- list_rds_files(cleaned_dir)
  cleaned_tables <- vapply(cleaned_files, base_name_no_ext, character(1))

  used_rows <- list()

  for (i in seq_along(cleaned_files)) {
    table_name <- cleaned_tables[[i]]
    cols <- tryCatch(get_columns_from_rds(cleaned_files[[i]]), error = function(e) {
      message("Skipping ", table_name, " (failed to read): ", conditionMessage(e))
      character(0)
    })

    if (length(cols) == 0) next

    # Drop generic placeholder names that create lots of false positives.
    cols <- setdiff(cols, c("V1"))

    # Determine used columns by identifier token presence in code.
    # (Heuristic, but fast; treats columns as used if their name appears as an identifier.)
    used_flags <- cols %in% code_tokens

    used_cols <- cols[used_flags]
    if (length(used_cols) == 0) next

    used_rows[[length(used_rows) + 1]] <- data.frame(
      table = table_name,
      column = used_cols,
      stringsAsFactors = FALSE
    )
  }

  used <- if (length(used_rows) == 0) {
    data.frame(table = character(0), column = character(0), stringsAsFactors = FALSE)
  } else {
    out <- do.call(rbind, used_rows)
    rownames(out) <- NULL
    out[order(out$table, out$column), ]
  }

  utils::write.csv(used, args$out_vars, row.names = FALSE)
  message("- Wrote used variables: ", args$out_vars)
  message(sprintf("- Used variables found: %d", nrow(used)))

  # Filter schema diffs, if present
  if (file.exists(args$diffs)) {
    diffs <- utils::read.csv(args$diffs, stringsAsFactors = FALSE)

    # Keep table-level missing file rows always; filter column-level rows to used set
    used_key <- paste0(used$table, "::", used$column)
    diffs_key <- paste0(diffs$table, "::", diffs$column)

    keep <- is.na(diffs$column) | diffs$column == "" | diffs$issue %in% c("missing_file_in_dataset", "missing_file_in_cleaned") | (diffs_key %in% used_key)

    diffs_used <- diffs[keep, , drop = FALSE]
    utils::write.csv(diffs_used, args$out_diffs, row.names = FALSE, na = "")

    message("- Wrote filtered diffs: ", args$out_diffs)
    message(sprintf("- Filtered diff rows: %d (of %d)", nrow(diffs_used), nrow(diffs)))
  } else {
    message("- Diffs file not found (skipping): ", args$diffs)
  }
}

main()
