#' Wrappers to run in CI
#'
#' To call in CI
#'
#' @export
#' @param path path to source package
#' @param which either be strong or most
install_recheck_deps <- function(path = '.', which = 'strong', check_bioc = FALSE){
  desc <- as.data.frame(read.dcf(file.path(path, 'DESCRIPTION')))
  pkg <- desc$Package
  repos <- c(
    CRAN = 'https://cloud.r-project.org',
    BIOC = if(isTRUE(check_bioc)) 'https://bioconductor.posit.co/packages/devel/bioc'
  )
  db <- utils::available.packages(repos = repos)
  revdeps <- tools::package_dependencies(pkg, db = db, which = which, reverse = TRUE)[[pkg]]
  packages <- setdiff(unique(c(desc_deps(desc), revdeps)), basepkgs())
  utils::install.packages(packages, dependencies = TRUE)
  #deps <- unique(unlist(unname(tools::package_dependencies(packages, recursive = TRUE))))
  #update.packages(oldPkgs = deps, ask = FALSE)
}

desc_deps <- function(desc){
  deps <- c(desc$Package, desc$Depends, desc$Imports, desc$LinkingTo, desc$Suggests, desc$Enhances)
  unique(trimws(sub("\\(.*\\)", "", unlist(strsplit(as.character(deps), ',')))))
}

# Do not try to install base packages
basepkgs <- function(){
  c("R", rownames(installed.packages(priority="base")))
}

