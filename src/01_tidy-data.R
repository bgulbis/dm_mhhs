library(tidyverse)
library(edwr)
library(icd)

dir_raw <- "data/raw"

diagnosis <- read_data(dir_raw, "diagnosis", FALSE) %>%
    as.diagnosis()

# HL = E78; CAD = I20-I25
icd_comorbid <- list(HL = icd_children(as.icd10("E78")),
                     CAD = icd_children(c("I20", "I21", "I22", "I23", "I24", "I25"))) %>%
    as.icd_comorbidity_map()

diag_comorbid <- icd10_comorbid(diagnosis, icd_comorbid, short_code = FALSE, return_df = TRUE)

data_comorbid <- icd10_comorbid_elix(diagnosis, return_df = TRUE) %>%
    select(millennium.id, CHF, HTN, Pulmonary) %>%
    left_join(diag_comorbid, by = "millennium.id")

write_rds(data_comorbid, "data/tidy/comorbidities.Rds", "gz")
