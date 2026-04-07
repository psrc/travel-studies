# 2025 PSRC Household Travel Survey Data Analysis

## resources

-   HTS codebook: [variable list](https://github.com/psrc/travel-studies/blob/master/HTS_codebook/2025_codebook/final_variable_list_2025.csv) and [value labels](https://github.com/psrc/travel-studies/blob/master/HTS_codebook/2025_codebook/final_value_labels_2025.csv)
-   psrc.travelsurvey R package: [installation](https://psrc.github.io/psrc.travelsurvey/index.html) and [user guide for retrieving and summarizing data in R](https://psrc.github.io/psrc.travelsurvey/articles/retrieve-and-summarize-data.html)
-   [Quarto](https://quarto.org/): publishing system that offers tools to create analysis documents
    -   [install Quarto](https://quarto.org/docs/get-started/)

## example workflow (see [Topsheet folder](https://github.com/psrc/travel-studies/tree/master/2025/hts_summary/Analysis/Topsheet))

1.  create a topic folder in [travel-studies/2025/hts_summary/Analysis](https://github.com/psrc/travel-studies/tree/master/2025/hts_summary/Analysis)
2.  within your topic folder: develop your scripts and analysis using a combination of R scripts and Quarto markdown (Jupyter Notebooks if you prefer using Python)
3.  to render your analysis scripts into a [Quarto Book](https://quarto.org/docs/books/) locally
    -   you will need at least two files: [\_quarto.yml](https://github.com/psrc/travel-studies/blob/master/2025/hts_summary/Analysis/Topsheet/_quarto.yml) and [index.qmd](https://github.com/psrc/travel-studies/blob/master/2025/hts_summary/Analysis/Topsheet/index.qmd), plus any other analysis scripts you'd like to include
    -   render by running `quarto render` at your folder location in terminal
4.  to render the full summary report along with everyone's work
    -   make sure your script is listed in [here](https://github.com/psrc/travel-studies/blob/master/2025/hts_summary/_quarto.yml) as one of the chapters
    -   render by running `quarto render` at the hts_summary folder location in terminal

## products
- documents: HTML documents or Quarto Book containing each analyst's analysis work (example: [topsheet_summary.html, open file in file explorer](https://github.com/psrc/travel-studies/blob/master/2025/hts_summary/Analysis/Topsheet/topsheet-notebook/topsheet_summary.html))
- summary report (HTML): Quarto Book with everyone's analysis (example: [here, open file in file explorer](https://github.com/psrc/travel-studies/blob/master/2025/hts_summary/HTS-summary-notebook/index.html))
- presentations: multiple presentations for boards and committees that comes from different topic analyses
