library(fs)
library(tidyverse)
library(pkgdown)

packages <- tribble(
  ~pkg_id, ~title, ~desc,
  "dynguidelines", "Choosing the optimal trajectory inference method", " ",
  "dynmethods", "Running trajectory inference methods", " ",
  "dynwrap", "Toolbox to transform trajectory models", " ",
  "dynplot", "Visualising trajectories", " ",
  "dynfeature", "Extracting relevant features from a trajectory", " "
)

reference <- pmap(packages, function(pkg_id, title, desc) {
  pkg_dir <- paste0("../", pkg_id, "/man/")

  man_files <- dir_ls(pkg_dir)

  walk(man_files, ~fs::file_copy(., paste0("./man/", fs::path_file(.)), overwrite=TRUE))

  man_ids <- man_files %>% {.[str_which(., ".*\\.Rd")]} %>% fs::path_file() %>% str_extract("[^\\.]*")

  list(
    title = str_glue("{title}"),
    desc = pkg_id,
    contents = man_ids
  )
})

config <- list(
  reference=reference,
  development = list(mode = "unreleased")
)

yaml::write_yaml(config, "_pkgdown.yml")

build_site(".", lazy=TRUE)

dir_walk("./man/", fs::file_delete)


