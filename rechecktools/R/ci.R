#' Wrappers to run in CI
#'
#' To call in CI
#'
#' @export
#' @param path path to source package
#' @param which either be strong or most
install_recheck_deps <- function(path = '.', which = 'strong'){
  oldrepos <- enable_all_repos()
  oldtimeout <- options(timeout = 600)
  on.exit(options(c(oldrepos, oldtimeout)), add = TRUE)
  desc <- read.dcf(file.path(path, 'DESCRIPTION'))
  pkg <- desc[[1, 'Package']]
  cranrepo <- getOption('repos')['CRAN']
  cran <- utils::available.packages(repos = cranrepo)
  packages <- c(pkg, tools::package_dependencies(pkg, db = cran, which = which, reverse = TRUE)[[pkg]])
  if(grepl("Linux", Sys.info()[['sysname']])){
    preinstall_linux_binaries(packages)
  } else {
    utils::install.packages(packages, dependencies = TRUE)
    deps <- unique(unlist(unname(tools::package_dependencies(packages, recursive = TRUE))))
    update.packages(oldPkgs = deps, ask = FALSE)
  }
}
