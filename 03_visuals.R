library(tidyverse)
library(janitor)
library(ggrepel)
library(scales)
library(tidyr)
library(stringr)

# helper: clean + label positions nicely
pretty_pos <- function(x) {
  x_clean <- x |>
    str_to_lower() |>
    str_squish()

  dplyr::case_when(
    x_clean %in% c("c")        ~ "Catcher",
    x_clean %in% c("1b")       ~ "1B (First Base)",
    x_clean %in% c("2b")       ~ "2B (Second Base)",
    x_clean %in% c("3b")       ~ "3B (Third Base)",
    x_clean %in% c("ss","s")   ~ "SS (Shortstop)",
    x_clean %in% c("lf")       ~ "LF (Left Field)",
    x_clean %in% c("cf")       ~ "CF (Center Field)",
    x_clean %in% c("rf")       ~ "RF (Right Field)",
    x_clean %in% c("of")       ~ "OF (Outfield)",
    x_clean %in% c("inf")      ~ "INF (Infield)",
    x_clean %in% c("dh")       ~ "DH (Designated Hitter)",
    x_clean %in% c("rhp")      ~ "RHP",
    x_clean %in% c("lhp")      ~ "LHP",
    TRUE                       ~ str_to_upper(x_clean)  # fallback
  )
}


# ============================
# 0) Load combined player data
# ============================

players <- readr::read_csv("data/players_2025_combined.csv", show_col_types = FALSE) |>
  clean_names()

# Expecting columns: year, team, player, position, salary_usd, war
# Keep only rows with valid salary + WAR
players_clean <- players_clean |>
  mutate(
    position = if_else(is.na(position) | position == "", "Unknown", position),

    # primary position = first before "-" or "/"
    position_primary = position |>
      str_split("[-/]", simplify = TRUE) |>
      (\(m) m[, 1])() |>
      str_squish(),

    position_primary = if_else(position_primary == "", "Unknown", position_primary),

    # pretty labels
    position_label         = pretty_pos(position),
    position_primary_label = pretty_pos(position_primary),

    dollars_per_war = salary_usd / war,
    war_per_million = war / (salary_usd / 1e6)
  )

out_dir <- "outputs"
if (!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE)

# =====================================================
# 1) Split multi-position players & share WAR/salary
# =====================================================
# Example: "SS-2B" becomes two rows: SS and 2B,
# each with half WAR and half salary.

players_by_pos <- players_clean |>
  # split into one row per position
  separate_rows(position, sep = "[-/]") |>
  mutate(
    position = str_squish(position),
    position = if_else(position == "" | is.na(position), "Unknown", position)
  ) |>
  group_by(year, team, player, position_primary, salary_usd, war) |>
  mutate(
    n_positions = n(),                         # how many positions this player is listed at
    salary_split = salary_usd / n_positions,   # share salary across positions
    war_split    = war / n_positions           # share WAR across positions
  ) |>
  ungroup()

# At this point, sum(salary_split) per player == salary_usd,
# and sum(war_split) per player == war.

# =====================================================
# 2) Team $/WAR scatter (using split shares or originals)
# =====================================================

teams_agg <- players_by_pos |>
  group_by(team) |>
  summarise(
    team_salary_usd = sum(salary_split, na.rm = TRUE),
    team_war        = sum(war_split,    na.rm = TRUE),
    .groups = "drop"
  ) |>
  filter(!is.na(team), team != "", team_war > 0) |>
  mutate(
    dollars_per_war = team_salary_usd / team_war,
    war_per_million = team_war / (team_salary_usd / 1e6)
  )

p_team <- ggplot(teams_agg, aes(x = team_war, y = dollars_per_war, label = team)) +
  geom_point(size = 3, alpha = 0.85) +
  ggrepel::geom_text_repel(min.segment.length = 0) +
  scale_y_continuous(labels = label_dollar()) +
  labs(
    title = "2025 Team Contract Efficiency ($/WAR)",
    subtitle = "Salary and WAR split across multi-position players • Lower is better",
    x = "Team WAR (sum of players)",
    y = "Dollars per WAR"
  ) +
  theme_minimal(base_size = 13)

ggsave(file.path(out_dir, "2025_team_dollars_per_war.png"),
       p_team, width = 8, height = 5, dpi = 300)

# =====================================================
# 3) Positional $/WAR (using split shares)
# =====================================================

pos_agg <- players_by_pos |>
  filter(!is.na(position), position != "") |>
  mutate(position_label = pretty_pos(position)) |>
  group_by(position_label) |>
  summarise(
    n_player_rows   = n(),
    total_salary    = sum(salary_split, na.rm = TRUE),
    total_war       = sum(war_split,    na.rm = TRUE),
    dollars_per_war = total_salary / total_war,
    war_per_million = total_war / (total_salary / 1e6),
    .groups = "drop"
  ) |>
  filter(total_war > 0)


p_pos <- ggplot(pos_agg, aes(x = fct_reorder(position_label, dollars_per_war),
                             y = dollars_per_war)) +
  geom_col() +
  coord_flip() +
  scale_y_continuous(labels = label_dollar()) +
  labs(
    title = "2025 Positional Contract Efficiency ($/WAR)",
    subtitle = "Salary and WAR shared across all listed positions • Lower is better",
    x = "Position",
    y = "Dollars per WAR"
  ) +
  theme_minimal(base_size = 13)

ggsave(file.path(out_dir, "2025_position_dollars_per_war.png"),
       p_pos, width = 8, height = 5, dpi = 300)

# =====================================================
# 4) Top 20 value contracts (per player, not split)
# =====================================================

top20 <- players_clean |>
  filter(war > 0) |>
  arrange(dollars_per_war) |>
  slice_head(n = 20) |>
  mutate(
    label = paste0(player, " (", team, ", ", position_primary_label, ")"),
    label = fct_reorder(label, dollars_per_war)
  )

p_top <- ggplot(top20, aes(x = label, y = dollars_per_war)) +
  geom_col() +
  coord_flip() +
  scale_y_continuous(labels = label_dollar()) +
  labs(
    title = "Top 20 Value Contracts in 2025 (by $/WAR)",
    subtitle = "Per-player view • WAR and salary not split across positions",
    x = NULL,
    y = "Dollars per WAR"
  ) +
  theme_minimal(base_size = 13)

ggsave(file.path(out_dir, "2025_top20_value_contracts.png"),
       p_top, width = 9, height = 6, dpi = 300)

# =====================================================
# 5) Salary vs WAR scatter (per player, colored by primary position)
# =====================================================

p_scatter <- players_clean |>
  ggplot(aes(x = salary_usd,
             y = war,
             color = position_primary_label)) +
  geom_point(alpha = 0.8, size = 2.3) +
  scale_x_continuous(labels = label_dollar(scale = 1/1e6, suffix = "M")) +
  labs(
    title = "2025 Salary vs WAR by Primary Position",
    subtitle = "Each player shown once at primary position",
    x = "Salary (Millions USD)",
    y = "WAR",
    color = "Primary Position"
  ) +
  theme_minimal(base_size = 13)

ggsave(file.path(out_dir, "2025_salary_vs_war_by_position.png"),
       p_scatter, width = 8, height = 5, dpi = 300)

message ("✅ Saved all 4 charts into the outputs/ folder (team, position, top 20, scatter).")
