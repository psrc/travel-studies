# Compare schemas between RDS tables in two hts_data_for_weighting subfolders.
#
# Usage (from repo root):
#   Rscript scripts/compare_rds_schemas.R
#
# Optional args:
#   --root=<path>       Root folder containing Cleaned_* and Dataset_* (default: hts_data_for_weighting)
#   --cleaned=<path>    Explicit Cleaned_* folder path
#   --dataset=<path>    Explicit Dataset_* folder path
#   --out=<path>        Output CSV path (default: schema_diffs.csv in working directory)
#   --strict            Exit with non-zero status if any diffs found
#
# Notes
# - Pairing logic: Cleaned_<date>/<name>.rds is paired with Dataset_<date>/toc_<name>.rds when present,
#   otherwise Dataset_<date>/<name>.rds.
# - This script reads full RDS objects to infer column types.
# - Type comparison: by default we compare primary column class; `integer` and `numeric` are treated as compatible.

parse_args <- function(argv) {
  args <- list(
    root = file.path(getwd(), "hts_data_for_weighting"),
    cleaned = NA_character_,
    dataset = NA_character_,
    out = file.path(getwd(), "schema_diffs.csv"),
    strict = FALSE
  )

  for (a in argv) {
    if (identical(a, "--strict")) {
      args$strict <- TRUE
      next
    }
    if (!grepl("^--[^=]+=", a)) next
    key <- sub("^--([^=]+)=.*$", "\\1", a)
    val <- sub("^--[^=]+=", "", a)
    if (key %in% names(args)) args[[key]] <- val
  }
  args
}

pick_latest_dir <- function(root, prefix) {
  dirs <- list.dirs(root, full.names = TRUE, recursive = FALSE)
  dirs <- dirs[basename(dirs) %in% basename(dirs[grepl(paste0("^", prefix, "_"), basename(dirs))])]
  dirs <- dirs[grepl(paste0("^", prefix, "_"), basename(dirs))]
  if (length(dirs) == 0) return(NA_character_)
  # Prefer lexicographically-latest (works for YYYYMMDD suffixes)
  dirs[order(basename(dirs), decreasing = TRUE)][1]
}

as_table_like <- function(x) {
  if (is.data.frame(x)) return(x)
  if (inherits(x, "data.table")) return(as.data.frame(x))
  # Some tables may be tibbles (still data.frame)
  if (inherits(x, "tbl")) return(as.data.frame(x))
  NULL
}

col_signature <- function(v) {
  cls <- class(v)
  data.frame(
    class_primary = if (length(cls) > 0) cls[[1]] else NA_character_,
    class_full = paste(cls, collapse = "/"),
    typeof = typeof(v),
    stringsAsFactors = FALSE
  )
}

classes_compatible <- function(class_a, class_b) {
  if (is.na(class_a) || is.na(class_b)) return(FALSE)
  if (identical(class_a, class_b)) return(TRUE)

  # Treat integer and numeric as compatible.
  numeric_like <- c("integer", "numeric")
  if (class_a %in% numeric_like && class_b %in% numeric_like) return(TRUE)

  FALSE
}

get_schema <- function(obj) {
  tab <- as_table_like(obj)
  if (is.null(tab)) {
    stop("RDS object is not a data.frame/data.table-like table; got class: ", paste(class(obj), collapse = "/"))
  }

  cn <- names(tab)
  if (is.null(cn)) cn <- character(0)

  if (length(cn) == 0) {
    return(data.frame(
      column = character(0),
      class_primary = character(0),
      class_full = character(0),
      typeof = character(0),
      stringsAsFactors = FALSE
    ))
  }

  sigs <- lapply(tab, col_signature)
  out <- data.frame(column = cn, do.call(rbind, sigs), stringsAsFactors = FALSE)
  rownames(out) <- NULL
  out
}

list_rds_files <- function(dir_path) {
  files <- list.files(dir_path, pattern = "\\.rds$", full.names = TRUE, ignore.case = TRUE)
  # Ignore obvious temp/cache folders if present
  files <- files[!grepl("[/\\\\](cache|tmp|temp)[/\\\\]", files, ignore.case = TRUE)]
  files
}

base_name_no_ext <- function(path) {
  sub("\\.rds$", "", basename(path), ignore.case = TRUE)
}

normalize_dataset_table_name <- function(x) {
  # Dataset side often uses toc_<table>
  sub("^toc_", "", x)
}

read_schema_safe <- function(path) {
  obj <- readRDS(path)
  get_schema(obj)
}

compare_pair <- function(table_name, cleaned_path, dataset_path) {
  diffs <- list()

  cleaned_schema <- read_schema_safe(cleaned_path)
  dataset_schema <- read_schema_safe(dataset_path)

  cleaned_cols <- cleaned_schema$column
  dataset_cols <- dataset_schema$column

  missing_in_dataset <- setdiff(cleaned_cols, dataset_cols)
  missing_in_cleaned <- setdiff(dataset_cols, cleaned_cols)

  if (length(missing_in_dataset) > 0) {
    diffs[[length(diffs) + 1]] <- data.frame(
      table = table_name,
      column = missing_in_dataset,
      issue = "missing_in_dataset",
      cleaned_class = cleaned_schema$class_primary[match(missing_in_dataset, cleaned_schema$column)],
      cleaned_typeof = cleaned_schema$typeof[match(missing_in_dataset, cleaned_schema$column)],
      dataset_class = NA_character_,
      dataset_typeof = NA_character_,
      cleaned_file = cleaned_path,
      dataset_file = dataset_path,
      stringsAsFactors = FALSE
    )
  }

  if (length(missing_in_cleaned) > 0) {
    diffs[[length(diffs) + 1]] <- data.frame(
      table = table_name,
      column = missing_in_cleaned,
      issue = "missing_in_cleaned",
      cleaned_class = NA_character_,
      cleaned_typeof = NA_character_,
      dataset_class = dataset_schema$class_primary[match(missing_in_cleaned, dataset_schema$column)],
      dataset_typeof = dataset_schema$typeof[match(missing_in_cleaned, dataset_schema$column)],
      cleaned_file = cleaned_path,
      dataset_file = dataset_path,
      stringsAsFactors = FALSE
    )
  }

  common <- intersect(cleaned_cols, dataset_cols)
  if (length(common) > 0) {
    cs <- cleaned_schema[match(common, cleaned_schema$column), ]
    ds <- dataset_schema[match(common, dataset_schema$column), ]

    type_mismatch <- !mapply(classes_compatible, cs$class_primary, ds$class_primary)
    if (any(type_mismatch, na.rm = TRUE)) {
      mism_cols <- common[which(type_mismatch)]
      diffs[[length(diffs) + 1]] <- data.frame(
        table = table_name,
        column = mism_cols,
        issue = "type_mismatch",
        cleaned_class = cs$class_primary[type_mismatch],
        cleaned_typeof = cs$typeof[type_mismatch],
        dataset_class = ds$class_primary[type_mismatch],
        dataset_typeof = ds$typeof[type_mismatch],
        cleaned_file = cleaned_path,
        dataset_file = dataset_path,
        stringsAsFactors = FALSE
      )
    }
  }

  if (length(diffs) == 0) {
    return(data.frame(
      table = character(0),
      column = character(0),
      issue = character(0),
      cleaned_class = character(0),
      cleaned_typeof = character(0),
      dataset_class = character(0),
      dataset_typeof = character(0),
      cleaned_file = character(0),
      dataset_file = character(0),
      stringsAsFactors = FALSE
    ))
  }

  out <- do.call(rbind, diffs)
  rownames(out) <- NULL
  out
}

build_pairs <- function(cleaned_map, dataset_map) {
  # Returns a data.frame of comparison pairs.
  # Columns: comparison_name, cleaned_table, dataset_table
  cleaned_tables <- names(cleaned_map)
  dataset_tables <- names(dataset_map)

  pairs <- list()

  for (ct in cleaned_tables) {
    if (ct %in% dataset_tables) {
      pairs[[length(pairs) + 1]] <- data.frame(
        comparison_name = ct,
        cleaned_table = ct,
        dataset_table = ct,
        stringsAsFactors = FALSE
      )
      next
    }

    # Special case: compare cleaned trip against dataset unlinked trip.
    if (identical(ct, "trip")) {
      # Dataset file naming varies by project; support both.
      if ("unlinked_trip" %in% dataset_tables) {
        pairs[[length(pairs) + 1]] <- data.frame(
          comparison_name = "trip__vs__unlinked_trip",
          cleaned_table = "trip",
          dataset_table = "unlinked_trip",
          stringsAsFactors = FALSE
        )
        next
      }
      if ("trip_unlinked" %in% dataset_tables) {
        pairs[[length(pairs) + 1]] <- data.frame(
          comparison_name = "trip__vs__trip_unlinked",
          cleaned_table = "trip",
          dataset_table = "trip_unlinked",
          stringsAsFactors = FALSE
        )
        next
      }
    }
  }

  if (length(pairs) == 0) {
    return(data.frame(
      comparison_name = character(0),
      cleaned_table = character(0),
      dataset_table = character(0),
      stringsAsFactors = FALSE
    ))
  }

  out <- do.call(rbind, pairs)
  rownames(out) <- NULL
  out
}

main <- function() {
  args <- parse_args(commandArgs(trailingOnly = TRUE))

  root <- args$root
  if (!dir.exists(root)) {
    stop("Root folder not found: ", root)
  }

  cleaned_dir <- args$cleaned
  dataset_dir <- args$dataset

  if (is.na(cleaned_dir) || cleaned_dir == "") cleaned_dir <- pick_latest_dir(root, "Cleaned")
  if (is.na(dataset_dir) || dataset_dir == "") dataset_dir <- pick_latest_dir(root, "Dataset")

  if (is.na(cleaned_dir) || !dir.exists(cleaned_dir)) {
    stop("Cleaned folder not found. Provide --cleaned=<path> or ensure a Cleaned_* folder exists under: ", root)
  }
  if (is.na(dataset_dir) || !dir.exists(dataset_dir)) {
    stop("Dataset folder not found. Provide --dataset=<path> or ensure a Dataset_* folder exists under: ", root)
  }

  message("Comparing schemas")
  message("- Cleaned: ", cleaned_dir)
  message("- Dataset: ", dataset_dir)

  cleaned_files <- list_rds_files(cleaned_dir)
  dataset_files <- list_rds_files(dataset_dir)

  cleaned_names <- vapply(cleaned_files, base_name_no_ext, character(1))
  dataset_names_raw <- vapply(dataset_files, base_name_no_ext, character(1))
  dataset_names <- normalize_dataset_table_name(dataset_names_raw)

  # Prefer toc_<table>.rds if multiple dataset files map to same table
  dataset_rank <- ifelse(grepl("^toc_", dataset_names_raw), 0L, 1L)
  dataset_order <- order(dataset_names, dataset_rank)
  dataset_files <- dataset_files[dataset_order]
  dataset_names_raw <- dataset_names_raw[dataset_order]
  dataset_names <- dataset_names[dataset_order]

  # Keep first occurrence per dataset table name after ranking
  keep <- !duplicated(dataset_names)
  dataset_files <- dataset_files[keep]
  dataset_names <- dataset_names[keep]

  cleaned_map <- stats::setNames(cleaned_files, cleaned_names)
  dataset_map <- stats::setNames(dataset_files, dataset_names)

  pairs <- build_pairs(cleaned_map, dataset_map)

  diffs_all <- list()

  # File presence diffs should account for any override pairings.
  paired_cleaned <- unique(pairs$cleaned_table)
  paired_dataset <- unique(pairs$dataset_table)

  only_in_cleaned <- setdiff(names(cleaned_map), paired_cleaned)
  only_in_dataset <- setdiff(names(dataset_map), paired_dataset)

  if (length(only_in_cleaned) > 0) {
    diffs_all[[length(diffs_all) + 1]] <- data.frame(
      table = only_in_cleaned,
      column = NA_character_,
      issue = "missing_file_in_dataset",
      cleaned_class = NA_character_,
      cleaned_typeof = NA_character_,
      dataset_class = NA_character_,
      dataset_typeof = NA_character_,
      cleaned_file = unname(cleaned_map[only_in_cleaned]),
      dataset_file = NA_character_,
      cleaned_table = only_in_cleaned,
      dataset_table = NA_character_,
      stringsAsFactors = FALSE
    )
  }

  if (length(only_in_dataset) > 0) {
    diffs_all[[length(diffs_all) + 1]] <- data.frame(
      table = only_in_dataset,
      column = NA_character_,
      issue = "missing_file_in_cleaned",
      cleaned_class = NA_character_,
      cleaned_typeof = NA_character_,
      dataset_class = NA_character_,
      dataset_typeof = NA_character_,
      cleaned_file = NA_character_,
      dataset_file = unname(dataset_map[only_in_dataset]),
      cleaned_table = NA_character_,
      dataset_table = only_in_dataset,
      stringsAsFactors = FALSE
    )
  }

  for (i in seq_len(nrow(pairs))) {
    comp_name <- pairs$comparison_name[[i]]
    ct <- pairs$cleaned_table[[i]]
    dt <- pairs$dataset_table[[i]]

    cleaned_path <- unname(cleaned_map[[ct]])
    dataset_path <- unname(dataset_map[[dt]])

    d <- tryCatch(
      compare_pair(comp_name, cleaned_path, dataset_path),
      error = function(e) {
        data.frame(
          table = comp_name,
          column = NA_character_,
          issue = paste0("error: ", conditionMessage(e)),
          cleaned_class = NA_character_,
          cleaned_typeof = NA_character_,
          dataset_class = NA_character_,
          dataset_typeof = NA_character_,
          cleaned_file = cleaned_path,
          dataset_file = dataset_path,
          stringsAsFactors = FALSE
        )
      }
    )

    if (nrow(d) > 0) {
      d$cleaned_table <- ct
      d$dataset_table <- dt
      diffs_all[[length(diffs_all) + 1]] <- d
    }
  }

  diffs <- if (length(diffs_all) == 0) {
    data.frame(
      table = character(0),
      column = character(0),
      issue = character(0),
      cleaned_class = character(0),
      cleaned_typeof = character(0),
      dataset_class = character(0),
      dataset_typeof = character(0),
      cleaned_file = character(0),
      dataset_file = character(0),
      cleaned_table = character(0),
      dataset_table = character(0),
      stringsAsFactors = FALSE
    )
  } else {
    out <- do.call(rbind, diffs_all)
    rownames(out) <- NULL
    out
  }

  utils::write.csv(diffs, args$out, row.names = FALSE, na = "")

  # Console summary
  message("\nSummary")
  message("- Tables in cleaned: ", length(cleaned_files))
  message("- Tables in dataset: ", length(dataset_files))
  message("- Tables compared: ", nrow(pairs))
  message("- Diff rows written: ", nrow(diffs))
  message("- Output: ", args$out)

  if (nrow(diffs) > 0) {
    top_issues <- sort(table(diffs$issue), decreasing = TRUE)
    message("\nIssues by type:")
    for (nm in names(top_issues)) {
      message(sprintf("- %s: %d", nm, top_issues[[nm]]))
    }
  }

  if (args$strict && nrow(diffs) > 0) {
    quit(status = 2)
  }
}

main()
