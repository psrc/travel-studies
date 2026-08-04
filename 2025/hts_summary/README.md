# 2025 PSRC Household Travel Survey Data Analysis

## example workflow (see [Delivery folder](https://github.com/psrc/travel-studies/tree/master/2025/hts_summary/Analysis/Delivery))

#### 1. create a topic folder in [travel-studies/2025/hts_summary/Analysis](https://github.com/psrc/travel-studies/tree/master/2025/hts_summary/Analysis)
#### 2. within your topic folder: develop your scripts and analysis using a combination of R scripts and Quarto markdown (Jupyter Notebooks if you prefer using Python)
-   required scripts: `index.qmd` as the cover page of your analysis for notes and progress; `data_processing.R` for your data processing script; `analysis.qmd` as your main analysis notebook; [`_quarto.yml`](https://github.com/psrc/travel-studies/blob/master/2025/hts_summary/Analysis/Delivery/_quarto.yml) for topic level document formats
-   tips for creating modules in your `analysis.qmd` script ([delivery trend module example](https://github.com/psrc/travel-studies/blob/3b2c02c0ec2bce86d69aa32a9f6d13e8c2d2f0d0/2025/hts_summary/Analysis/Delivery/delivery_analysis.qmd#L16-L134)):
    -   create a customized function to print your charts and supporting table
    -   reuse the function with [tabsets](https://quarto.org/docs/output-formats/html-basics.html#tabsets) to produce same charts but with different variables
#### 3. to render your analysis scripts into a [Quarto Book](https://quarto.org/docs/books/) in your topic folder
-   you will need at least two files: [\_quarto.yml](https://github.com/psrc/travel-studies/blob/master/2025/hts_summary/Analysis/Delivery/_quarto.yml) and [index.qmd](https://github.com/psrc/travel-studies/blob/master/2025/hts_summary/Analysis/Delivery/index.qmd), plus any other analysis scripts you'd like to include
-   render by running `quarto render` at your folder location in terminal
#### 4. add your analysis to the full "2025 HTS Exploration & Analysis report" along with everyone's work
-   make sure your Quarto notebooks are listed in [here](https://github.com/psrc/travel-studies/blob/master/2025/hts_summary/_quarto-exploration-analysis.yml) as one of the chapters
-   render by running `quarto render` at the `hts_summary` folder location in terminal
#### 5. summarize analysis results by creating a summary page
- create a `.qmd` file in the [SummaryReport](https://github.com/psrc/travel-studies/tree/master/2025/hts_summary/SummaryReport) folder (example: [`Delivery.qmd`](https://github.com/psrc/travel-studies/blob/master/2025/hts_summary/SummaryReport/Delivery.qmd))
- in the `.qmd` file, include necessary charts and tables from your analysis notebooks with [embed](https://quarto.org/docs/authoring/notebook-embed.html) shortcodes and describe analysis findings in bullet points
    - to be referenced with embed, figures and tables must be labeled with `#| label: fig-xxxxx` and `#| label: tbl-xxxxx` respectively ([example](https://github.com/psrc/travel-studies/blob/ca921bd80153fd4269fe54197e576488d818a91e/2025/hts_summary/Analysis/Delivery/delivery_analysis.qmd#L94-L109))
    - example figure size configuration: [example here](https://github.com/psrc/travel-studies/blob/ca921bd80153fd4269fe54197e576488d818a91e/2025/hts_summary/Analysis/Delivery/delivery_analysis.qmd#L96-L98)
    - bugs to be aware of:
      1. embed shortcode can't find any figures/tables nested within markdown div containers such as `:::{.panel-tabsets} :::`
      2. embed shortcode doesn't work with most table formatting packages ([kable() from kintr](https://github.com/psrc/travel-studies/blob/ca921bd80153fd4269fe54197e576488d818a91e/2025/hts_summary/Analysis/Delivery/delivery_analysis.qmd#L86) works well while directly printing tables, `gt` and `DT` didn't work when I tried them)

## resources

-   HTS codebook: [variable list](https://github.com/psrc/travel-studies/blob/master/HTS_codebook/2025_codebook/final_variable_list_2025.csv) and [value labels](https://github.com/psrc/travel-studies/blob/master/HTS_codebook/2025_codebook/final_value_labels_2025.csv)
-   2025 HTS questionnaire: "J:\Projects\Surveys\HHTravel\Survey2025\Planning\Questionnaire\Puget_Sound_HTS_Questionnaire_2025_v8.0.pdf"
-   psrc.travelsurvey R package: [installation](https://psrc.github.io/psrc.travelsurvey/index.html) and [user guide for retrieving and summarizing data in R](https://psrc.github.io/psrc.travelsurvey/articles/retrieve-and-summarize-data.html)
-   [Quarto](https://quarto.org/): publishing system that offers tools to create analysis documents. Useful links:
    -   [install Quarto](https://quarto.org/docs/get-started/)
    -   [execution options](https://quarto.org/docs/reference/cells/cells-knitr.html#code-output)
    -   [tabsets](https://quarto.org/docs/output-formats/html-basics.html#tabsets) when showing same charts by different segments
    -   [project profiles](https://quarto.org/docs/projects/profiles.html) to adapt options and content of your projects for different scenarios
    -   [embed shortcode](https://quarto.org/docs/authoring/notebook-embed.html) to include the output of another Quarto document
- HTS data in Elmer: the multi-year data is stored in Elmer as views ('HHSurvey.v_households','HHSurvey.v_persons','HHSurvey.v_days','HHSurvey.v_trips','HHSurvey.v_vehicles')

### size and formatting recommendations for ggplot figures on Quarto documents

1. simple barchart:

```
#| fig-height: 3
#| fig-width: 5.1
#| out-width: "350px"
```

2. faceted barcharts

```
#| fig-height: 4
#| fig-width: 7
#| out-width: "350px"
```
- see Quarto website for more figure settings: https://quarto.org/docs/computations/execution-options.html#figure-options

## products
- documents: HTML documents or Quarto Book containing each analyst's analysis work (example: [topsheet_summary.html, open file in file explorer](https://github.com/psrc/travel-studies/blob/master/2025/hts_summary/Analysis/Topsheet/topsheet-notebook/topsheet_summary.html))
- Exploration and Analysis (HTML): Quarto Book with everyone's exploration and analysis work(example: [here, open file in file explorer](https://github.com/psrc/travel-studies/blob/master/2025/hts_summary/HTS-summary-notebook/index.html))
- Summary Report (HTML): Quarto Book with everyone's analysis results and findings 
- presentations: multiple presentations for boards and committees that comes from different topic analyses
