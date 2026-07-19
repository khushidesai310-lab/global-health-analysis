# ================================================
# Script 1: Load and Clean All Datasets
# Project: Healthcare Investment & Life Expectancy
# Author: Khushi Desai | Johns Hopkins University
# ================================================

library(tidyverse)
library(janitor)
library(countrycode)

# ================================================
# STEP 1: Load GBD Life Expectancy Data
# ================================================

gbd_raw <- read_csv("./data/IHME-GBD_2023_DATA-38741f33-1.csv")

glimpse(gbd_raw)

gbd_clean <- gbd_raw %>%
  clean_names() %>%
  filter(sex_name == "Both") %>%
  select(
    country = location_name,
    year,
    gbd_life_expectancy = val
  )

cat("GBD rows after cleaning:", nrow(gbd_clean), "\n")
head(gbd_clean)

# ================================================
# STEP 2: Load World Bank Healthcare Spending
# ================================================

spending_raw <- read_csv(
  "./data/API_SH.XPD.CHEX.PC.CD_DS2_en_csv_v2_4562.csv",
  skip = 4  # World Bank CSVs have 4 header rows to skip
)

glimpse(spending_raw)

# Reshape from wide (years as columns) to long format
spending_long <- spending_raw %>%
  clean_names() %>%
  select(country = country_name,
         country_code,
         starts_with("x")) %>%
  pivot_longer(
    cols = starts_with("x"),
    names_to = "year",
    values_to = "health_spending_per_capita"
  ) %>%
  mutate(
    year = as.numeric(str_remove(year, "x")),
    health_spending_per_capita = as.numeric(health_spending_per_capita)
  ) %>%
  filter(!is.na(health_spending_per_capita))

cat("Spending rows after cleaning:", nrow(spending_long), "\n")
head(spending_long)

# ================================================
# STEP 3: Load World Bank Life Expectancy
# ================================================

le_raw <- read_csv(
  "./data/API_SP.DYN.LE00.IN_DS2_en_csv_v2_2473.csv",
  skip = 4
)

le_long <- le_raw %>%
  clean_names() %>%
  select(country = country_name,
         country_code,
         starts_with("x")) %>%
  pivot_longer(
    cols = starts_with("x"),
    names_to = "year",
    values_to = "wb_life_expectancy"
  ) %>%
  mutate(
    year = as.numeric(str_remove(year, "x")),
    wb_life_expectancy = as.numeric(wb_life_expectancy)
  ) %>%
  filter(!is.na(wb_life_expectancy))

cat("Life expectancy rows after cleaning:", nrow(le_long), "\n")
head(le_long)

# ================================================
# STEP 4: Load Hospital Beds Data
# ================================================

beds_raw <- read_csv(
  "./data/API_SH.MED.BEDS.ZS_DS2_en_csv_v2_5054.csv",
  skip = 4
)

beds_long <- beds_raw %>%
  clean_names() %>%
  select(country = country_name,
         country_code,
         starts_with("x")) %>%
  pivot_longer(
    cols = starts_with("x"),
    names_to = "year",
    values_to = "hospital_beds_per_1000"
  ) %>%
  mutate(
    year = as.numeric(str_remove(year, "x")),
    hospital_beds_per_1000 = as.numeric(hospital_beds_per_1000)
  ) %>%
  filter(!is.na(hospital_beds_per_1000))

cat("Hospital beds rows after cleaning:", nrow(beds_long), "\n")
head(beds_long)

# ================================================
# STEP 5: Add World Region using countrycode package
# This lets us analyse by region later
# ================================================

spending_long <- spending_long %>%
  mutate(
    region = countrycode(country_code,
                         origin = "wb",
                         destination = "region")
  )

# ================================================
# STEP 6: Merge all datasets
# ================================================

merged <- spending_long %>%
  left_join(le_long %>% select(country_code, year, wb_life_expectancy),
            by = c("country_code", "year")) %>%
  left_join(beds_long %>% select(country_code, year, hospital_beds_per_1000),
            by = c("country_code", "year")) %>%
  filter(!is.na(wb_life_expectancy)) %>%
  filter(!is.na(region))

cat("Final merged dataset rows:", nrow(merged), "\n")
glimpse(merged)

# ================================================
# STEP 7: Save cleaned merged dataset
# ================================================
dir.create("./data/processed", recursive = TRUE)
write_csv(merged,
          "./data/processed/merged_clean.csv")

cat("Saved successfully!\n")
cat("Countries in dataset:", n_distinct(merged$country), "\n")
cat("Years covered:", min(merged$year), "to", max(merged$year), "\n")
cat("Regions:", unique(merged$region), "\n")

