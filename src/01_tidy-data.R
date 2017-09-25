library(tidyverse)
library(edwr)
library(icd)

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

write_rds(data_comorbid, "data/tidy/comorbidities.Rds", "gz")

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

write_rds(data_dm_diag, "data/tidy/dm_types.Rds", "gz")
