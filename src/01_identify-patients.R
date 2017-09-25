library(tidyverse)
library(stringr)
library(edwr)
library(icd)

dir_raw <- "data/raw"

icd10_dm <- c(icd10_map_ahrq$DM,
              icd10_map_ahrq$DMcx,
              icd10_map_elix$DM,
              icd10_map_elix$DMcx) %>%
    icd_short_to_decimal() %>%
    unique()

mbo_icd10 <- str_c(icd10_dm, collapse = ";")

# ICD-10 codes: E08 - E13

# run MBO query
#   * Patients - by ICD

patients <- read_data(dir_raw, "patients", FALSE) %>%
    as.patients()

write_rds(patients, "data/tidy/dm_patients.Rds", "gz")

inpt <- filter(patients, visit.type == "Inpatient")

id_mbo <- concat_encounters(inpt$millennium.id)

# run MBO queries
#   * Diagnosis - ICD-9/10-CM
#   * Labs - Prompt
#       - Lab Event (FILTER ON): Hgb A1c
#   * Medications - Inpatient - Prompt
#       - Insulin
#   * Medications - Home and Discharge

# run EDW queries
#   * Identifiers - by Millennium Encounter ID

# run EDW queries
#   * Encounters - by Person ID

# run MBO query
#   * Patients - by Visit Type

all_pts <- read_data(dir_raw, "all-pts", FALSE) %>%
    as.patients()

write_rds(all_pts, "data/tidy/all_inpatients.Rds", "gz")
