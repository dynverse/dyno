library(tidyverse)

url <- "https://www.ncbi.nlm.nih.gov/geo/download/?acc=GSE67310&format=file&file=GSE67310%5FiN%5Fdata%5Flog2FPKM%5Fannotated.txt.gz"
df <- read_tsv(url, col_types = cols(cell_name = "c", assignment = "c", experiment = "c", time_point = "c", .default = "d"))
expression <- df[, -c(1:5)] %>% as.matrix() %>% magrittr::set_rownames(df$cell_name)
cell_info <- df[, c(1:5)] %>% as.data.frame() %>% magrittr::set_rownames(df$cell_name) %>%
  rename(
    cell_id = cell_name,
    group_id = assignment
  )

expression <- expression[, expression %>% apply(2, sd) %>% sort() %>% tail(2000) %>% names]
counts <- 2^expression-1

fibroblast_reprogramming_treutlein <- wrap_data("id", rownames(expression)) %>%
  add_expression_to_wrapper(counts, expression) %>%
  add_grouping_to_wrapper(unique(cell_info$group_id), set_names(cell_info$group_id, cell_info$cell_id))

usethis::use_data(fibroblast_reprogramming_treutlein, overwrite = TRUE)
