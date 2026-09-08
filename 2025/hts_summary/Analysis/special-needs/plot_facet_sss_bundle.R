library(data.table)
library(ggplot2)

#' Faceted bar chart of a `bundle_sss_stat()` summary bundle
#'
#' One facet per question, with horizontal bars showing `share` for each level of
#' `group_var` (e.g. "Overall" plus a breakdown). Bars are colored by `group_var`, whose
#' labels appear directly on the y-axis, so no legend is drawn.
#'
#' @param bundle named list returned by `bundle_sss_stat()`
#' @param group_var string, name of the breakdown column within each bundle element
#'   (the same `group_var` passed to `bundle_sss_stat()`; use `"group"` if `bundle_sss_stat()`
#'   was called without a `group_var`)
#' @param wrap_width integer, character width to wrap facet question labels
#' @return a ggplot2 object
plot_facet_sss_bundle <- function(bundle, group_var = "group", wrap_width = 12) {
  stopifnot(is.list(bundle), length(bundle) > 0)

  dt <- data.table::rbindlist(bundle, use.names = TRUE)
  if (!group_var %in% colnames(dt)) {
    stop(sprintf(
      "`%s` not found in bundle output; pass the same `group_var` used in `bundle_sss_stat()`.",
      group_var
    ))
  }

  # Preserve question order as given to bundle_sss_stat(), not alphabetical.
  question_order <- vapply(bundle, function(x) x$description[1], character(1))
  label_levels <- stringr::str_wrap(unique(question_order), width = wrap_width)
  dt[, description := factor(
    stringr::str_wrap(as.character(description), width = wrap_width),
    levels = label_levels
  )]

  # "Overall" first in the data means last in factor levels so it plots at the
  # top of each facet after coord_flip().
  group_levels <- unique(dt[[group_var]])
  if ("Overall" %in% group_levels) {
    group_levels <- c(setdiff(group_levels, "Overall"), "Overall")
  }
  dt[[group_var]] <- factor(dt[[group_var]], levels = rev(group_levels))

  palette <- unname(psrcplot::psrc_colors$pognbgy_5[c(5, 4, 3, 1, 2)])
  palette <- rep_len(palette, length(group_levels))
  value_label_size <- if (length(bundle) >= 5 || length(group_levels) >= 5) 2.5 else 3.3
  axis_label_size <- if (length(bundle) >= 6) 7 else 8

  ggplot2::ggplot(dt, ggplot2::aes(x = .data[[group_var]], y = share, fill = .data[[group_var]])) +
    ggplot2::geom_col() +
    ggplot2::geom_text(
      ggplot2::aes(label = scales::percent(share, accuracy = 1)),
      hjust = -0.15, size = value_label_size
    ) +
    ggplot2::coord_flip(clip = "on") +
    ggplot2::facet_wrap(~description, nrow = 1) +
    ggplot2::scale_x_discrete(labels = function(x) stringr::str_wrap(x, width = 18)) +
    ggplot2::scale_y_continuous(
      breaks = c(0, 0.5, 1), labels = scales::percent,
      limits = c(0, 1.15), expand = c(0, 0)
    ) +
    ggplot2::scale_fill_manual(values = palette) +
    ggplot2::labs(x = NULL, y = "Weighted %") +
    ggplot2::guides(fill = "none") +
    ggplot2::theme_minimal() +
    ggplot2::theme(
      strip.background = ggplot2::element_rect(fill = "#91268F", color = NA),
      strip.text = ggplot2::element_text(color = "white", face = "bold", size = 9),
      panel.grid.major.y = ggplot2::element_blank(),
      panel.grid.minor = ggplot2::element_blank(),
      axis.text.x = ggplot2::element_text(size = 7, angle = 30, hjust = 0, vjust = 1),
      axis.text.y = ggplot2::element_text(size = axis_label_size, lineheight = 0.9)
    )
}
