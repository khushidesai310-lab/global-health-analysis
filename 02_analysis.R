# ================================================
# Script 2: Analysis and Visualizations
# Project: Healthcare Investment & Life Expectancy
# Author: Khushi Desai | Johns Hopkins University
# ================================================

library(tidyverse)
library(ggplot2)
library(scales)
library(patchwork)
library(viridis)

dir.create("C:/Users/KHUSHI/amr_project/outputs/figures", recursive = TRUE)

# Load the cleaned merged dataset
merged_full <- read_csv("C:/Users/KHUSHI/amr_project/data/processed/merged_full.csv")

# Remove NAs in key columns and remove regional aggregates
df <- merged_full %>%
  filter(
    !is.na(health_spending_per_capita),
    !is.na(wb_life_expectancy),
    !is.na(region),
    !is.na(cause),
    cause != "NA",
    year %in% c(2000, 2005, 2010, 2015, 2019)
  )

cat("Rows for analysis:", nrow(df), "\n")
cat("Countries:", n_distinct(df$country), "\n")
cat("Diseases:", unique(df$cause), "\n")

# ================================================
# PLOT 1: Healthcare Spending vs Life Expectancy
# One dot per country, colored by region
# ================================================

# Use 2019 data only for this plot
df_2019 <- df %>%
  filter(year == 2019) %>%
  distinct(country, country_code, region,
           health_spending_per_capita, wb_life_expectancy)

plot1 <- ggplot(df_2019,
                aes(x = health_spending_per_capita,
                    y = wb_life_expectancy,
                    color = region)) +
  geom_point(alpha = 0.7, size = 2.5) +
  geom_smooth(method = "lm", se = TRUE,
              color = "black", linewidth = 0.8) +
  scale_x_log10(labels = dollar_format(prefix = "$")) +
  labs(
    title = "Healthcare Spending vs Life Expectancy (2019)",
    subtitle = "Each dot represents one country. X axis is log scale.",
    x = "Healthcare Spending per Capita (USD, log scale)",
    y = "Life Expectancy at Birth (years)",
    color = "Region",
    caption = "Sources: World Bank, GBD 2023"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold"),
    legend.position = "bottom",
    legend.text = element_text(size = 8)
  )

ggsave("C:/Users/KHUSHI/amr_project/outputs/figures/plot1_spending_vs_lifeexp.png",
       plot1, width = 10, height = 7, dpi = 300)

cat("Plot 1 saved\n")

# ================================================
# PLOT 2: Disease Death Rates by Region (2019)
# Compare all diseases across regions
# ================================================

df_disease_region <- df %>%
  filter(
    year == 2019,
    cause != "Total cancers"  # remove duplicate cancer entry
  ) %>%
  group_by(region, cause) %>%
  summarise(avg_death_rate = mean(death_rate_per_100k, na.rm = TRUE),
            .groups = "drop")

plot2 <- ggplot(df_disease_region,
                aes(x = reorder(cause, avg_death_rate),
                    y = avg_death_rate,
                    fill = region)) +
  geom_col(position = "dodge") +
  coord_flip() +
  scale_fill_viridis_d() +
  labs(
    title = "Average Disease Death Rates by Region (2019)",
    subtitle = "Deaths per 100,000 population",
    x = "Disease",
    y = "Average Death Rate per 100,000",
    fill = "Region",
    caption = "Source: IHME GBD 2023"
  ) +
  theme_minimal(base_size = 11) +
  theme(
    plot.title = element_text(face = "bold"),
    legend.position = "bottom",
    legend.text = element_text(size = 7)
  )

ggsave("C:/Users/KHUSHI/amr_project/outputs/figures/plot2_disease_by_region.png",
       plot2, width = 12, height = 8, dpi = 300)

cat("Plot 2 saved\n")

# ================================================
# PLOT 3: Does spending reduce disease burden?
# Correlation between spending and death rate
# for each disease separately
# ================================================

df_corr <- df %>%
  filter(
    year == 2019,
    cause != "Total cancers",
    !is.na(death_rate_per_100k)
  ) %>%
  group_by(cause) %>%
  summarise(
    correlation = cor(log10(health_spending_per_capita),
                      death_rate_per_100k,
                      use = "complete.obs"),
    n_countries = n(),
    .groups = "drop"
  ) %>%
  arrange(correlation)

cat("Correlation by disease:\n")
print(df_corr)

plot3 <- ggplot(df_corr,
                aes(x = reorder(cause, correlation),
                    y = correlation,
                    fill = correlation < 0)) +
  geom_col() +
  coord_flip() +
  scale_fill_manual(values = c("TRUE" = "#2ecc71", "FALSE" = "#e74c3c"),
                    labels = c("TRUE" = "Negative (spending helps)",
                               "FALSE" = "Positive (spending does not help)")) +
  geom_hline(yintercept = 0, linewidth = 0.8) +
  labs(
    title = "Does Healthcare Spending Reduce Disease Death Rates?",
    subtitle = "Correlation between spending per capita and death rate per 100,000 (2019)",
    x = "Disease",
    y = "Correlation with Healthcare Spending (log scale)",
    fill = "Direction",
    caption = "Negative correlation means higher spending is associated with lower death rates\nSource: World Bank, IHME GBD 2023"
  ) +
  theme_minimal(base_size = 12) +
  theme(plot.title = element_text(face = "bold"),
        legend.position = "bottom")

ggsave("C:/Users/KHUSHI/amr_project/outputs/figures/plot3_spending_correlation.png",
       plot3, width = 10, height = 6, dpi = 300)

cat("Plot 3 saved\n")

# ================================================
# PLOT 4: Life Expectancy Trends Over Time
# By region from 2000 to 2019
# ================================================

df_trend <- df %>%
  distinct(country, country_code, region, year, wb_life_expectancy) %>%
  group_by(region, year) %>%
  summarise(avg_life_exp = mean(wb_life_expectancy, na.rm = TRUE),
            .groups = "drop")

plot4 <- ggplot(df_trend,
                aes(x = year,
                    y = avg_life_exp,
                    color = region,
                    group = region)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 2.5) +
  scale_x_continuous(breaks = c(2000, 2005, 2010, 2015, 2019)) +
  scale_color_viridis_d() +
  labs(
    title = "Life Expectancy Trends by Region (2000 to 2019)",
    subtitle = "Average life expectancy at birth",
    x = "Year",
    y = "Average Life Expectancy (years)",
    color = "Region",
    caption = "Source: World Bank"
  ) +
  theme_minimal(base_size = 12) +
  theme(plot.title = element_text(face = "bold"),
        legend.position = "bottom")

ggsave("C:/Users/KHUSHI/amr_project/outputs/figures/plot4_lifeexp_trends.png",
       plot4, width = 10, height = 6, dpi = 300)

cat("Plot 4 saved\n")

# ================================================
# PLOT 5: Top 10 and Bottom 10 countries
# by life expectancy in 2019
# ================================================

df_country_2019 <- df %>%
  filter(year == 2019) %>%
  distinct(country, region,
           wb_life_expectancy,
           health_spending_per_capita) %>%
  arrange(desc(wb_life_expectancy))

top10 <- head(df_country_2019, 10) %>% mutate(group = "Top 10")
bottom10 <- tail(df_country_2019, 10) %>% mutate(group = "Bottom 10")
top_bottom <- bind_rows(top10, bottom10)

plot5 <- ggplot(top_bottom,
                aes(x = reorder(country, wb_life_expectancy),
                    y = wb_life_expectancy,
                    fill = group)) +
  geom_col() +
  geom_text(aes(label = paste0("$",
                               round(health_spending_per_capita, 0))),
            hjust = -0.1, size = 3) +
  coord_flip() +
  scale_fill_manual(values = c("Top 10" = "#2ecc71",
                               "Bottom 10" = "#e74c3c")) +
  scale_y_continuous(limits = c(0, 100)) +
  labs(
    title = "Top 10 and Bottom 10 Countries by Life Expectancy (2019)",
    subtitle = "Labels show healthcare spending per capita in USD",
    x = "Country",
    y = "Life Expectancy (years)",
    fill = "",
    caption = "Source: World Bank, IHME GBD 2023"
  ) +
  theme_minimal(base_size = 11) +
  theme(plot.title = element_text(face = "bold"),
        legend.position = "top")

ggsave("C:/Users/KHUSHI/amr_project/outputs/figures/plot5_top_bottom_countries.png",
       plot5, width = 10, height = 8, dpi = 300)

cat("Plot 5 saved\n")
cat("All plots saved successfully!\n")