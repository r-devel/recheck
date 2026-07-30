#' Wrappers to run in CI
#'
#' To call in CI
#'
#' @export
#' @param path path to source package
#' @param which either be strong or most
#' @param check_bioc also include reverse dependencies from Bioconductor
#' @param pattern optional regular expression (case insensitive) to subset the
#' reverse dependencies by name, e.g. `'^[a-k]'`. This can be used to split a
#' very large reverse dependency check into multiple smaller runs.
#' @return the names of the (subset of) reverse dependencies for which the
#' dependencies were installed, invisibly. This can be passed as the `reverse`
#' argument of [tools::check_packages_in_dir] to check exactly these packages.

install_recheck_deps <- function(path = '.', which = 'strong', check_bioc = FALSE, pattern = ''){
  desc <- as.data.frame(read.dcf(file.path(path, 'DESCRIPTION')))
  pkg <- desc$Package
  repos <- c(
    CRAN = 'https://cloud.r-project.org',
    BIOC = if(isTRUE(check_bioc)) 'https://bioconductor.posit.co/packages/devel/bioc'
  )
  db <- utils::available.packages(repos = repos)
  revdeps <- as.character(tools::package_dependencies(pkg, db = db, which = which, reverse = TRUE)[[pkg]])
  if(nchar(pattern)){
    revdeps <- grep(pattern, revdeps, ignore.case = TRUE, value = TRUE)
    message(sprintf("Subsetting reverse dependencies matching '%s': %d packages", pattern, length(revdeps)))
  }
  packages <- setdiff(unique(c(desc_deps(desc), revdeps)), basepkgs())
  utils::install.packages(packages, dependencies = TRUE)
  #deps <- unique(unlist(unname(tools::package_dependencies(packages, recursive = TRUE))))
  #update.packages(oldPkgs = deps, ask = FALSE)
  invisible(revdeps)
}

desc_deps <- function(desc){
  deps <- c(desc$Package, desc$Depends, desc$Imports, desc$LinkingTo, desc$Suggests, desc$Enhances)
  unique(trimws(sub("\\(.*\\)", "", unlist(strsplit(as.character(deps), ',')))))
}

# Do not try to install base packages
basepkgs <- function(){
  c("R", rownames(installed.packages(priority="base")))
}

