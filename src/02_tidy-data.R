library(tidyverse)
library(edwr)
library(icd)
library(stringr)

dir_raw <- "data/raw"

diagnosis <- read_data(dir_raw, "diagnosis", FALSE) %>%
    as.diagnosis() %>%
    filter(diag.type == "FINAL")

# comorbidities ----------------------------------------
# HL = E78; CAD = I20-I25
icd_comorbid <- list(HL = icd_children(as.icd10("E78")),
                     CAD = icd_children(c("I20", "I21", "I22", "I23", "I24", "I25"))) %>%
    as.icd_comorbidity_map()

diag_comorbid <- icd10_comorbid(diagnosis, icd_comorbid, short_code = FALSE, return_df = TRUE)

data_comorbid <- icd10_comorbid_elix(diagnosis, return_df = TRUE) %>%
    select(millennium.id, CHF, HTN, Pulmonary) %>%
    left_join(diag_comorbid, by = "millennium.id")

write_rds(data_comorbid, "data/tidy/data_comorbidities.Rds", "gz")

# diabetes types ---------------------------------------

# Type 1 = E10; Type 2 = E11; Other = E13; (MODY = E13.9); NDM = P70.2
icd_dm <- list(DM1 = icd_children(as.icd10("E10")),
               DM2 = icd_children(as.icd10("E11")),
               DM_other = icd_children(as.icd10("E13")),
               DM_preg = icd_children(as.icd10("O24")),
               DM_mody = "E139",
               DM_neonatal = "P702")

data_dm_diag <- icd10_comorbid(diagnosis, icd_dm, short_code = FALSE, return_df = TRUE) %>%
    mutate(dm_type = case_when(DM1 ~ "Type 1",
                               DM2 ~ "Type 2",
                               DM_preg ~ "Gestational",
                               DM_neonatal ~ "Neonatal",
                               DM_other ~ "Other",
                               TRUE ~ "Unknown"))

write_rds(data_dm_diag, "data/tidy/data_dm_diagnosis.Rds", "gz")

# a1c --------------------------------------------------

data_a1c <- read_data(dir_raw, "labs-a1c", FALSE) %>%
    as.labs() %>%
    tidy_data() %>%
    group_by(millennium.id) %>%
    summarize_at(c("lab.result", "censor.low"), max, na.rm = TRUE) %>%
    mutate_at("lab.result", funs(na_if(., -Inf))) %>%
    mutate_at("censor.low", as.logical) %>%
    mutate(low_a1c = lab.result <= 8 | censor.low,
           high_a1c = !low_a1c) %>%
    select(-low_a1c)

write_rds(data_a1c, "data/tidy/data_a1c.Rds", "gz")

# home meds --------------------------------------------

insulin <- med_lookup("insulin")

meds_home <- read_data(dir_raw, "meds-home", FALSE) %>%
    as.meds_home()

data_insulin_home <- meds_home %>%
    filter(med.type == "Recorded / Home Meds",
           med %in% insulin$med.name)

data_insulin_dc <- meds_home %>%
    filter(med.type == "Prescription/Discharge Order",
           med %in% insulin$med.name)

med_rec <- read_data(dir_raw, "med-rec") %>%
    distinct() %>%
    filter(`Reconciliation Type` == "Discharge")
