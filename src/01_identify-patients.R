library(tidyverse)
library(lubridate)
library(edwr)
library(icd)

dir_raw <- "data/raw/2018-01"
tz <- "US/Central"

icd10_dm <- c(
    icd10_map_ahrq$DM,
    icd10_map_ahrq$DMcx,
    icd10_map_elix$DM,
    icd10_map_elix$DMcx
) %>%
    icd_short_to_decimal() %>%
    unique()

mbo_icd10 <- str_c(icd10_dm, collapse = ";")

# ICD-10 codes: E08 - E13

# run MBO query
#   * Patients - by ICD
#       - Facility (Curr): HH HERMANN;HC Childrens;KM Katy;SG Sugar Land;MC Mem City;GH Greater Heights;SE Southeast;SW Southwest;TW The Woodland;NE Northeast;BL PEARLAND;CY CYPRESS
#       - Diagnosis Type: FINAL

patients <- read_data(dir_raw, "patients", FALSE) %>%
    as.patients() %>%
    filter(
        discharge.datetime >= mdy("1/1/2018", tz = tz),
        discharge.datetime < mdy("2/1/2018", tz = tz)
    )

write_rds(patients, "data/tidy/2018-01/data_patients_dm.Rds", "gz")

inpt <- filter(patients, visit.type == "Inpatient")

id_mbo <- concat_encounters(inpt$millennium.id)

insulin <- med_lookup("insulin") %>%
    arrange(med.name)

meds_insulin <- concat_encounters(c(insulin$med.name, "Insulin regular"))

# run MBO queries
#   * Diagnosis - ICD-9/10-CM
#   * Labs - Prompt
#       - Lab Event (FILTER ON): Hgb A1c
#   * Medications - Inpatient - Prompt
#       - Medication (Generic): results of meds_insulin
#   * Medications - Home and Discharge

# run EDW queries
#   * Identifiers - by Millennium Encounter ID

# ids <- read_data(dir_raw, "identifiers") %>%
#     as.id()
#
# id_pie <- concat_encounters(ids$pie.id)
# id_person <- concat_encounters(unique(ids$person.id))

# run EDW queries
#   * Encounters - by Person ID
#   * Medications - Reconciliation

# run MBO query
#   * Patients - by Visit Type
#       - Encounter Class Subtype: Inpatient

all_pts <- read_data(dir_raw, "all-pts", FALSE) %>%
    as.patients() %>%
    filter(
        discharge.datetime >= mdy("1/1/2018", tz = tz),
        discharge.datetime < mdy("2/1/2018", tz = tz)
    )

write_rds(all_pts, "data/tidy/2018-01/data_inpatients.Rds", "gz")
