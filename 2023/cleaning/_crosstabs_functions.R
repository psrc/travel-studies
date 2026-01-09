
format_crosstab_table = function(table_to_format) 
{
  variable = unique(table_to_format[, variable])
  description = unique(table_to_format[, description])
  logic = unique(table_to_format[, logic])
  table_to_format[, `:=`(variable, NULL)]
  table_to_format[, `:=`(value, NULL)]
  table_to_format[, `:=`(valid, NULL)]
  setnames(table_to_format, "value_label", variable)
  cat(paste0("#### ", description, "\n"))
  if (!is.na(logic)) {
    cat(paste0(logic, "\n"))
  }
  table_to_format[, `:=`(description, NULL)]
  table_to_format[, `:=`(logic, NULL)]
  column_width = (ncol(table_to_format) - 1)/2
  align_string = paste0("l", paste0(rep("r", column_width * 
                                          2), collapse = ""))
  table_to_format[is.na(table_to_format)] = ""
  table_to_format = table_to_format %>% 
    kable(align = align_string, digits = 0, format.args = list(big.mark = ",")) %>% 
    kable_styling(bootstrap_options = c("striped", "hover", 
                                        "condensed", "responsive"), font_size = 13) %>% add_header_above(c(` ` = 1, 
                                                                                                           Counts = column_width, Percentages = column_width)) %>% 
    column_spec(1, width = "30em", border_right = "1px solid lightgray") %>% 
    column_spec(1 + column_width, border_right = "1px solid lightgray") %>% 
    column_spec(1 + 2 * column_width, border_right = "1px solid lightgray")
  print(table_to_format)
}

format_checkbox_table = function(table_to_format) 
{
  table_to_format = table_to_format[order(variable_order)]
  table_to_format[, `:=`(variable_order, NULL)]
  label = unique(table_to_format[, common_name])
  logic = unique(table_to_format[, logic])
  table_to_format[, `:=`(common_name, NULL)]
  table_to_format[, `:=`(logic, NULL)]
  setnames(table_to_format, "specific_name", "")
  cat(paste0("#### ", label, "\n"))
  if (!is.na(logic)) {
    cat(paste0(logic, "\n"))
  }
  column_width = (ncol(table_to_format) - 1)/3
  align_string = paste0("l", paste0(rep("r", column_width * 
                                          3), collapse = ""))
  table_to_format = table_to_format %>% 
    kable(align = align_string, digits = 0, format.args = list(big.mark = ",")) %>% 
    kable_styling(bootstrap_options = c("striped", "hover", 
                                        "condensed", "responsive"), font_size = 13) %>% add_header_above(c(` ` = 1, 
                                                                                                           `Valid Counts` = column_width, Percentages = column_width, 
                                                                                                           `Missing Counts` = column_width)) %>% column_spec(1, 
                                                                                                                                                             width = "30em", border_right = "1px solid lightgray") %>% 
    column_spec(1 + column_width, border_right = "1px solid lightgray") %>% 
    column_spec(1 + 2 * column_width, border_right = "1px solid lightgray")
  print(table_to_format)
}

cross_tab = function(
  data,
  variable_labels,
  value_labels,
  variables,
  tab_by = NULL,
  missing_values = NULL,
  row_totals = FALSE,
  rounding_precision = 1,
  weight_column = NULL
){
  
  if (row_totals == TRUE & is.null(tab_by)) {
    stop("Error: parameters row_totals and tab_by are inconsistent")
  }
  # browser()
  table = copy(data)
  
  if (is.null(weight_column)) {
    table[, weight := 1]
  } else {
    setnames(table, weight_column, "weight")
  }
  
  cross_tab_table =
    table[,
          c(variables, tab_by, "weight"),
          with = FALSE]
  
  cross_tab_table =
    suppressWarnings(
      melt(
        cross_tab_table,
        id.vars = c(tab_by, "weight")))
  
  cross_tab_table[, value := as.character(value)]
  value_labels[, value := as.character(value)]
  
  cross_tab_table = value_labels[cross_tab_table, on = .(variable, value)]
  
  cross_tab_table[is.na(value_label) & !is.na(value), value_label := value]
  
  cross_tab_table[value %in% missing_values, valid := FALSE]
  cross_tab_table[is.na(valid), valid := TRUE]
  
  cross_tab_table =
    rollup(
      cross_tab_table,
      j = sum(weight),
      c(tab_by, "valid", "variable", "value_label", "value"))
  
  setnames(cross_tab_table, "V1", "N")
  
  cross_tab_table = cross_tab_table[!(is.na(variable) & !is.na(valid))]
  
  cross_tab_table = cross_tab_table[!(is.na(value) & valid == FALSE)]
  
  if (row_totals == TRUE) {
    #browser()
    cross_tab_table =
      rbindlist(
        list(
          cross_tab_table,
          cross_tab_table[, .(N = sum(N)), .(value_label, valid, variable, value)]),
        use.names = TRUE,
        fill = TRUE)
    
    # things are alphabetical. This forces totals to the right. will rename
    # after casting
    cross_tab_table[is.na(get(tab_by)) & !is.na(variable), (tab_by) := 99999999]
    
  }
  
  cross_tab_table[
    valid == TRUE & !is.na(value),
    pct_valid := paste0(format(round(N / sum(N), rounding_precision + 2) * 100, nsmall = rounding_precision), "%"),
    by = c(tab_by, 'variable')]
  
  cross_tab_table = cross_tab_table[!(is.na(value) & !is.na(value_label))]
  
  if (!is.null(tab_by)) {
    
    cross_tab_table = cross_tab_table[!is.na(get(tab_by))]
    
  }
  
  cross_tab_table[valid == TRUE & is.na(value), pct_valid := paste0(format(100, nsmall = rounding_precision), "%")]
  
  totals = cross_tab_table[!is.na(value), .(N = sum(N)), c(tab_by, 'variable')]
  setnames(totals, "tab_by", ifelse(is.null(tab_by), '', tab_by), skip_absent = TRUE)
  
  totals[, value_label := "Total"]
  totals[, value := Inf]
  
  cross_tab_table = rbindlist(list(cross_tab_table, totals), use.names = TRUE, fill = TRUE)
  
  if (!is.null(tab_by)) {
    
    if (tab_by %in% value_labels[, variable]) {
      
      cross_tab_table[, (tab_by) := as.character(get(tab_by))]
      
      cross_tab_table =
        value_labels[
          variable == tab_by,
          .(tab_by_value = value,
            tab_by_value_label = value_label)] %>%
        .[cross_tab_table, on = c("tab_by_value" = tab_by)]
      
      cross_tab_table[tab_by_value == 99999999, tab_by_value_label := "zzzTotal"]
      
      cross_tab_table[, tab_by_value := NULL]
      
      setnames(cross_tab_table, "tab_by_value_label", tab_by)
      
    }
    
    cross_tab_table =
      dcast(
        cross_tab_table,
        variable + value + value_label + valid ~ get(tab_by),
        value.var = c("N", "pct_valid"),
        fun.aggregate = function(x){x[1]})
  }
  
  cross_tab_table =
    variable_labels[, .(variable, description, logic)] %>%
    .[cross_tab_table, on = .(variable)]
  
  for (name in names(cross_tab_table)[grepl("N_", names(cross_tab_table))]) {
    cross_tab_table[, (name) := format(round(get(name), 0), big.mark = ",", scientific = FALSE)]
    cross_tab_table[grepl("NA", get(name)), (name) := '']
  }
  
  names(cross_tab_table) = gsub("N_", "", names(cross_tab_table))
  names(cross_tab_table) = gsub("pct_valid_", "", names(cross_tab_table))
  names(cross_tab_table) = gsub("zzzT", "T", names(cross_tab_table))
  
  cross_tab_table[is.na(value_label) & valid == TRUE, value_label := "Valid total"]
  cross_tab_table[is.na(value_label) & valid == FALSE, value_label := "Missing total"]
  
  cross_tab_table = cross_tab_table[!is.na(variable)]
  
  cross_tab_table = suppressWarnings(cross_tab_table[order(variable, -valid, as.numeric(value))])
  
  return(cross_tab_table)
  
}


checkbox_tab = function(
  data,
  value_labels,
  variable_labels,
  missing_values,
  checkbox_label_sep = ':',
  checkbox_variable_filter = NULL,
  checkbox_selected_value = 1,
  weight_column = NULL,
  tab_by = NULL,
  variables = NULL
){
  
  #browser()
  
  if ( is.null(variables) & is.null(checkbox_variable_filter) ){
    checkbox_variable_filter =
      "description %like% '--' & !(description %like% 'Other reason')"
  }
  
  data = copy(data)
  
  if (is.null(weight_column)) {
    data[, weight := 1]
  } else {
    setnames(data, weight_column, "weight")
  }
  
  labels = copy(variable_labels)
  labels[, common_name := gsub(paste0(checkbox_label_sep, '.*'), '', description)]
  labels[, specific_name := trimws(gsub(paste0('.*', checkbox_label_sep), '', description))]
  labels[, variable_order := seq_len(.N), by = .(common_name)]
  
  # move other/prefer not to answer to bottom
  variables_to_adjust = unique(labels[
    grepl("Other", specific_name) |
      grepl("Prefer ", specific_name) |
      grepl("No ", specific_name) |
      grepl("None", specific_name),
    common_name])
  #browser()
  
  if (is.null(variables_to_adjust)) {
    max_var_order = labels[
      common_name %in% variables_to_adjust,
      .(max_var_order = max(variable_order)),
      common_name]
    
    labels = max_var_order[labels, on = .(common_name)]
    
    labels[
      grepl("Other", specific_name) |
        grepl("No ", specific_name) |
        grepl("None", specific_name),
      variable_order := max_var_order + 1]
    
    labels[
      grepl("Prefer ", specific_name),
      variable_order := max_var_order + 2]
  }
  
  if ( !is.null(variables) ){
    
    checkbox_vars = labels[variable %in% variables, .(variable, common_name)]
    
  } else {
    
    checkbox_vars = labels[
      eval(parse(text = checkbox_variable_filter)),
      c('variable', 'common_name'),
      with = FALSE]
  }
  
  checkbox_vars = checkbox_vars[variable %in% names(data)]
  
  if (nrow(checkbox_vars) == 0) {
    message('No checkbox variables found')
    return(data.table(common_name = '', specific_name = ''))
  } else {
    # assigning a weight of 1 if weight is not specfied
    #browser()
    
    checkbox_table =
      data[,
           c(checkbox_vars[, variable], tab_by, "weight"),
           with = FALSE]
    
    checkbox_table =
      suppressWarnings(
        melt(
          checkbox_table,
          id.vars = c(tab_by, "weight")))
    
    checkbox_table[value %in% checkbox_selected_value, valid := TRUE]
    checkbox_table[value %in% missing_values, valid := FALSE]
    checkbox_table[is.na(valid), valid := TRUE]
    
    checkbox_table[value %in% checkbox_selected_value, selected := TRUE]
    checkbox_table[value %in% missing_values, selected := FALSE]
    checkbox_table[is.na(selected), selected := FALSE]
    
    checkbox_table = labels[,
                            c('variable', 'common_name', 'specific_name', 'variable_order', 'logic'),
                            with = FALSE] %>%
      .[checkbox_table, on = ('variable' = 'variable'), nomatch = 0]
    
    checkbox_table =
      rollup(
        checkbox_table,
        j = sum(weight),
        c(tab_by, "variable", "common_name", "specific_name", "variable_order", "logic", "valid", "selected"))
    
    setnames(checkbox_table, "V1", "N")
    
    checkbox_table = checkbox_table[!is.na(valid)]
    #checkbox_table = checkbox_table[!is.na(selected)]
    #checkbox_table = checkbox_table[valid == TRUE]
    
    checkbox_table =
      dcast(
        checkbox_table,
        formula = paste0(paste0(c('common_name',
                                  'specific_name',
                                  'variable_order',
                                  'logic',
                                  tab_by), collapse = ' + '),
                         ' ~ valid + selected'),
        value.var = "N",
        fun.aggregate = sum)
    
    new_cols = setdiff(c('TRUE_NA', 'FALSE_NA', 'TRUE_FALSE', 'TRUE_TRUE'), names(checkbox_table))
    
    if (length(new_cols > 0)) {
      checkbox_table[, (new_cols) := NA]
    }
    
    setnames(checkbox_table, "TRUE_NA", "valid_total")
    setnames(checkbox_table, "FALSE_NA", "missing_total")
    setnames(checkbox_table, "TRUE_FALSE", "valid_unselected")
    setnames(checkbox_table, "TRUE_TRUE", "valid_selected")
    
    if ( 'FALSE_FALSE' %in% names(checkbox_table) ){
      checkbox_table[, FALSE_FALSE := NULL]
    }
    
    checkbox_table[, pct_valid := valid_selected / valid_total]
    
    checkbox_table[, pct_valid := paste0(format(round(pct_valid, 3) * 100, nsmall = 1), "%")]
    
    if (!is.null(tab_by)) {
      
      if (tab_by %in% value_labels[, variable]) {
        
        checkbox_table[, (tab_by) := as.character(get(tab_by))]
        
        checkbox_table =
          value_labels[
            variable == tab_by,
            .(tab_by_value = value,
              tab_by_value_label = value_label)] %>%
          .[checkbox_table, on = c("tab_by_value" = tab_by)]
        
        checkbox_table[, tab_by_value := NULL]
        
        setnames(checkbox_table, "tab_by_value_label", tab_by)
        
      }
      
      checkbox_table =
        dcast(
          checkbox_table,
          common_name + specific_name + variable_order + logic ~ get(tab_by),
          value.var = c("valid_selected", "pct_valid", "missing_total"),
          fun.aggregate = function(x){return(x[1])})
      
    } else {
      
      checkbox_table =
        dcast(
          checkbox_table,
          common_name + specific_name + variable_order + logic ~ .,
          value.var = c("valid_selected", "pct_valid", "missing_total"),
          fun.aggregate = function(x){return(x[1])})
      
    }
    
    for (name in names(checkbox_table)[grepl("valid_selected_", names(checkbox_table))]) {
      checkbox_table[, (name) := format(round(get(name), 0), big.mark = ",", scientific = FALSE)]
      checkbox_table[grepl("NA", get(name)), (name) := '']
    }
    
    for (name in names(checkbox_table)[grepl("missing_total_", names(checkbox_table))]) {
      checkbox_table[, (name) := format(round(get(name), 0), big.mark = ",", scientific = FALSE)]
      checkbox_table[grepl("NA", get(name)), (name) := '']
    }
    
    names(checkbox_table) = gsub("valid_selected_", "", names(checkbox_table))
    names(checkbox_table) = gsub("pct_valid_", "", names(checkbox_table))
    names(checkbox_table) = gsub("missing_total_", "", names(checkbox_table))
    
    return(checkbox_table)
  }
}



print_summaries =
  function(
    data,
    variable_labels,
    value_labels,
    missing_values,
    tab_by = NULL,
    weight_column = NULL,
    variable_colname = 'variable',
    variable_label_colname = 'description',
    variable_logic_colname = 'logic',
    checkbox_label_sep = '--',
    checkbox_variable_filter = "description %like% '--' & !(description %like% 'Other reason')",
    checkbox_selected_value = 1,
    variables_to_exclude = NULL
  ) {
    
    # need to explicitly deal with excluding weight since we are renaming it
    # to a standard name
    
    variables_to_exclude = c(weight_column, variables_to_exclude)
    
    data = copy(data)
    
    
    if (is.null(weight_column)) {
      data[, weight := 1]
    } else {
      setnames(data, weight_column, "weight")
    }
    
    setnames(value_labels, variable_colname, 'variable')
    setnames(variable_labels, variable_colname, 'variable')
    setnames(variable_labels, variable_label_colname, 'description')
    
    # need to pass other parameters on if necessary
    checkbox_tabs =
      checkbox_tab(
        data = data,
        value_labels = value_labels,
        variable_labels = variable_labels,
        missing_values = missing_values,
        checkbox_variable_filter = checkbox_variable_filter,
        checkbox_label_sep = checkbox_label_sep,
        checkbox_selected_value = checkbox_selected_value,
        weight_column = "weight", #weight_column,
        tab_by = tab_by)
    
    variables_to_crosstab = intersect(names(data), value_labels[, variable])
    
    variables_to_crosstab =
      variables_to_crosstab[!variables_to_crosstab %in% variables_to_exclude]
    
    # need to pass other parameters on if necessary
    cross_tabs =
      cross_tab(
        data = data,
        variable_labels = variable_labels,
        value_labels = value_labels,
        variables = variables_to_crosstab,
        tab_by = tab_by,
        missing_values = missing_values,
        weight_column = "weight"# weight_column
      )
    
    variable_labels[, common_name := gsub(paste0(checkbox_label_sep, '.*'), '', description)]
    
    variable_labels = variable_labels[, .(variable = min(variable)), .(common_name, logic)][]
    
    for (variable_name in variable_labels[!variable %in% variables_to_exclude, variable]) {
      
      label = variable_labels[variable == variable_name, .(common_name)]
      logic = variable_labels[variable == variable_name, .(logic)]
      
      if (length(variable_labels[variable == variable_name, common_name]) == 0) {
        next
      }
      
      if (variable_labels[variable == variable_name, common_name] %in% checkbox_tabs[, common_name] ) {
        
        checkbox_tab = checkbox_tabs[common_name == variable_labels[variable == variable_name, common_name]]
        
        format_checkbox_table(checkbox_tab)
        
      } else if (variable_name %in% unique(cross_tabs[, variable])) {
        
        cross_tab = cross_tabs[variable == variable_name]
        
        format_crosstab_table(cross_tab)
        
      } else if (is.Date(data[, get(variable_name)])) {
        
        cat("\n")
        cat(paste0("#### ", label, "\n"))
        
        if (!is.na(logic)) {
          cat(paste0(logic, "\n"))
        }
        
        setnames(data, variable_name, "date")
        
        dates = data[!is.na(date), .N, by = c('date', tab_by)]
        
        if (!is.null(tab_by)) {
          
          if (tab_by %in% value_labels[, variable]) {
            
            dates[, (tab_by) := as.character(get(tab_by))]
            
            dates =
              value_labels[
                variable == tab_by,
                .(tab_by_value = value,
                  tab_by_value_label = value_label)] %>%
              .[dates, on = c("tab_by_value" = tab_by)]
            
            dates[, tab_by_value := NULL]
            
            setnames(dates, "tab_by_value_label", tab_by)
            
          }
        }
        
        plot = ggplot(dates, aes(x = date, y = N)) + geom_bar(stat = "identity") + facet_wrap(tab_by)
        cat('\n')
        print(plot)
        cat('\n\n')
        
        setnames(data, "date", variable_name)
        
      } else if (is.POSIXct(data[, get(variable_name)])) {
        
        cat("\n")
        cat(paste0("#### ", label, " - Unweighted\n"))
        
        setnames(data, variable_name, 'time_var')
        
        if (!is.na(logic)) {
          cat(paste0(logic, "\n"))
        }
        
        data[!is.na(time_var), hour := hour(time_var)]
        
        hours = data[!is.na(time_var), .N, by = c('hour', tab_by)]
        
        #browser()
        if (!is.null(tab_by)) {
          
          if (tab_by %in% value_labels[, variable]) {
            
            hours[, (tab_by) := as.character(get(tab_by))]
            
            hours =
              value_labels[
                variable == tab_by,
                .(tab_by_value = value,
                  tab_by_value_label = value_label)] %>%
              .[hours, on = c("tab_by_value" = tab_by)]
            
            hours[, tab_by_value := NULL]
            
            setnames(hours, "tab_by_value_label", tab_by)
            
          }
        }
        
        plot =
          ggplot(hours, aes(x = hour, y = N)) +
          geom_bar(stat = "identity") +
          facet_wrap(tab_by)
        
        cat('\n')
        print(plot)
        cat('\n\n')
        
        data[, time_var := NULL]
        
        
      } else if (is.numeric(data[, get(variable_name)]) & variable_name %in% variable_labels[[variable_colname]]) {
        
        cat("\n")
        cat(paste0("#### ", label, " - Statistics\n"))
        cat(variable_name)
        
        setnames(data, variable_name, "stats_var")
        
        stats = data[,
                     .(Min = min(stats_var * weight, na.rm = TRUE),
                       Median = as.double(median(stats_var * weight, na.rm = TRUE)),
                       Mean = mean(stats_var * weight, na.rm = TRUE),
                       Mode = get_mode_stat(stats_var * weight, na.rm = TRUE),
                       Max = max(stats_var * weight, na.rm = TRUE),
                       N_valid = sum(weight & !is.na(stats_var)),
                       N_NA = sum(weight * is.na(stats_var))),
                     by = tab_by]
        
        
        
        stats[is.infinite(Min), Min := '']
        stats[is.infinite(Max), Max := '']
        
        if (!is.null(tab_by)) {
          
          if (tab_by %in% value_labels[, variable]) {
            
            stats[, (tab_by) := as.character(get(tab_by))]
            
            stats =
              value_labels[
                variable == tab_by,
                .(tab_by_value = value,
                  tab_by_value_label = value_label)] %>%
              .[stats, on = c("tab_by_value" = tab_by)]
            
            stats[, tab_by_value := NULL]
            
            setnames(stats, "tab_by_value_label", tab_by)
            stats = stats[order(get(tab_by))]
            
          }
        }
        
        hist_data = data[!is.na(stats_var), .N, by = c('stats_var', tab_by)]
        
        #browser()
        if (!is.null(tab_by)) {
          
          if (tab_by %in% value_labels[, variable]) {
            
            hist_data[, (tab_by) := as.character(get(tab_by))]
            
            hist_data =
              value_labels[
                variable == tab_by,
                .(tab_by_value = value,
                  tab_by_value_label = value_label)] %>%
              .[hist_data, on = c("tab_by_value" = tab_by)]
            
            hist_data[, tab_by_value := NULL]
            
            setnames(hist_data, "tab_by_value_label", tab_by)
            
          }
        }
        
        plot =
          ggplot(hist_data, aes(x = stats_var, y = N)) +
          geom_bar(stat = "identity") +
          facet_wrap(tab_by)
        
        cat('\n')
        print(plot)
        cat('\n\n')
        
        print(format_table(stats))
        
        data[, stats_var := NULL]
      }
      
    }
  }

get_mode_stat =
  function(
    vector,
    na.rm = FALSE) {
    #browser()
    uniqv = unique(vector)
    
    if (na.rm) {
      uniqv = uniqv[!is.na(uniqv)]
    }
    
    return(uniqv[which.max(tabulate(match(vector, uniqv)))])
  }

format_table = function(tab,footnote_text=NA){
  
  tab = tab %>%
    kable(format='html', row.names=FALSE,  format.args = list(big.mark = ",")) %>%
    kable_styling(full_width=FALSE, position='left',
                  bootstrap_options=c('striped', 'condensed', 'bordered', 'hover'))
  
  if(!is.na(footnote_text)){
    tab = tab %>% footnote(general = footnote_text)
  }
  
  return(tab)
  
}



read_codebook = function(
  codebook_path,
  varvals = TRUE,
  sheet = ifelse(varvals, 'Values', 'Overview'),
  label_col = 'label'){
  
  if (varvals) {
    
    sheet_names = excel_sheets(codebook_path)
    
    if (sheet %in% sheet_names) {
      vvalues = read_excel(path = codebook_path, sheet = sheet)
      setDT(vvalues)
      
    } else {
      
      # multi-sheet format codebook
      sheets = c('hh', 'person', 'day', 'vehicle', 'trip', 'location')
      vvalue_list = lapply(sheets, function(x){
        if (x %in% sheet_names) {
          message('Reading codebook sheet ', x)
          read_xlsx(codebook_path, sheet = x)
        } else {
          NULL
        }
      })
      
      vvalues = rbindlist(vvalue_list)
      vvalues = unique(vvalues)
    }
    
    vvalues[, label_value := paste(value, get(label_col))]
    
    if (!'val_order' %in% names(vvalues)) {
      vvalues[, value := as.numeric(value)]
      setorder(vvalues, variable, value)
      vvalues[, val_order := 1:.N, by = .(variable)]
    }
    
    return(vvalues[])
    
  } else {
    # read in variable labels and logic
    varnames = read_excel(path = codebook_path, sheet = sheet)
    setDT(varnames)
    return(varnames[])
  }
}
