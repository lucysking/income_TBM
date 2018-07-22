Calculate Income-to-Needs at T1
================
Lucy King

-   [calculate income-to-needs](#calculate-income-to-needs)
    -   [Compare those included in sample to those not](#compare-those-included-in-sample-to-those-not)

``` r
##Libraries
library(tidyverse)
```

    ## ── Attaching packages ───────────────────────────────────────────────────────────── tidyverse 1.2.1 ──

    ## ✔ ggplot2 3.0.0     ✔ purrr   0.2.5
    ## ✔ tibble  1.4.2     ✔ dplyr   0.7.5
    ## ✔ tidyr   0.8.1     ✔ stringr 1.3.1
    ## ✔ readr   1.1.1     ✔ forcats 0.3.0

    ## ── Conflicts ──────────────────────────────────────────────────────────────── tidyverse_conflicts() ──
    ## ✖ dplyr::filter() masks stats::filter()
    ## ✖ dplyr::lag()    masks stats::lag()

``` r
##Parameters
#files
income_t1_file <- "~/Desktop/ELS/income_TBM/data/osf/income_t1.csv"
#in SPSS file, first cleaned variable "pplinhome_1_TEXT" and converted to numeric 
tbm_covariates_file <- "~/Desktop/ELS/income_TBM/data/osf/tbm_cov_income.csv"
```

calculate income-to-needs
-------------------------

``` r
#income reported in bins, used median for income to needs as in Yu et al. (2017) developmental science
inr <-
  read_csv(income_t1_file) %>% 
  select(
    ELS_ID,
    household_income = Household_Income,
    ppl_in_home = pplinhome_1_TEXT
  ) %>% 
  filter(
    !is.na(household_income)
    ) %>% 
  mutate(
    household_income = as.character(household_income),
    household_income_numeric = as.numeric(
      recode(
        household_income,
        "1" = "5000",
        "2" = "7500",
        "3" = "12500",
        "4" = "20000",
        "5" = "30000",
        "6" = "42500",
        "7" = "62500",
        "8" = "87500",
        "9" = "125000",
        "10" = "150000"
      )
    ),
#santa clara country low-income limit : 80% of median income (ratios <= 1 are therefore "low income")
#https://www.huduser.gov/portal/datasets/il/il2017/2017summary.odn
    SC_lowincome_limit = as.numeric(
      recode(
        ppl_in_home,
        "1" = "59350",
        "2" = "67800",
        "3" = "76300", 
        "4" = "84750",
        "5" = "91500",
        "6" = "98350",
        "7" = "105100",
        "8" = "111900",
        .default = "111900"
      )
    ),
    income_needs = household_income_numeric / SC_lowincome_limit
  )
```

    ## Parsed with column specification:
    ## cols(
    ##   ELS_ID = col_integer(),
    ##   Household_Income = col_integer(),
    ##   pplinhome_1_TEXT = col_integer()
    ## )

### Compare those included in sample to those not

``` r
inr <- 
  inr %>% 
  mutate(
    ELS_ID = as.integer(ELS_ID)
    ) %>%
  left_join(
    read_csv(tbm_covariates_file) %>% 
      select(
        ELS_ID,
        included = ICV
      ) %>% 
      mutate(ELS_ID = as.integer(ELS_ID)),
    by = "ELS_ID"
  ) %>% 
  mutate(
    included = if_else(
      !is.na(included), 
      "included", "not"
    )
  )
```

    ## Parsed with column specification:
    ## cols(
    ##   ELS_ID = col_integer(),
    ##   Age = col_double(),
    ##   Male = col_integer(),
    ##   Tanner = col_double(),
    ##   ICV = col_double(),
    ##   White = col_integer()
    ## )

``` r
t.test(inr$income_needs ~ inr$included)
```

    ## 
    ##  Welch Two Sample t-test
    ## 
    ## data:  inr$income_needs by inr$included
    ## t = 1.6255, df = 34.427, p-value = 0.1132
    ## alternative hypothesis: true difference in means is not equal to 0
    ## 95 percent confidence interval:
    ##  -0.05033377  0.45353258
    ## sample estimates:
    ## mean in group included      mean in group not 
    ##               1.304304               1.102705

\`\`\`
