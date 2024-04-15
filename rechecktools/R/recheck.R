#' Reverse Dependency Check
#'
#' Run a reverse dependency check similar to CRAN.
#'
#' @export
#' @rdname recheck
#' @param sourcepkg path or URL to a source package tarball
#' @param which passed to `tools::package_dependencies`; set to "most" to
#' also check reverse suggests.
#' @param preinstall_dependencies start by installing dependencies for all
#' packages to be checked.
recheck <- function(sourcepkg, which = "strong", preinstall_dependencies = TRUE){
  # Some temporary settings
  oldrepos <- enable_all_repos()
  oldtimeout <- options(timeout = 600)
  on.exit(options(c(oldrepos, oldtimeout)), add = TRUE)

  # Get the tarball
  if(grepl('^https:', sourcepkg)){
    curl::curl_download(sourcepkg, basename(sourcepkg))
    sourcepkg <- basename(sourcepkg)
  }
  if(!grepl("_", sourcepkg)){
    dl <- utils::download.packages(sourcepkg, '.')
    sourcepkg <- basename(dl[,2])
  }
  pkg <- sub("_.*", "", basename(sourcepkg))
  checkdir <- dirname(sourcepkg)
  cranrepo <- getOption('repos')['CRAN'] #
  cran <- utils::available.packages(repos = cranrepo)
  packages <- c(pkg, tools::package_dependencies(pkg, db = cran, which = which, reverse = TRUE)[[pkg]])
  if(preinstall_dependencies){
    group_output("Preparing dependencies", {
      if(grepl("Linux", Sys.info()[['sysname']])){
        preinstall_linux_binaries(packages)
      } else {
        utils::install.packages(packages, dependencies = TRUE)
        deps <- unique(unlist(unname(tools::package_dependencies(packages, recursive = TRUE))))
        update.packages(oldPkgs = deps, ask = FALSE)
      }
    })
  }
  check_args <- character()
  if(nchar(Sys.which('pdflatex')) == 0){
    message("No pdflatex found, skipping pdf checks")
    check_args <- c(check_args, '--no-manual --no-build-vignettes')
  }
  group_output("Running checks", {
    Sys.setenv('_R_CHECK_FORCE_SUGGESTS_' = 'false')
    if(.Platform$OS.type == 'windows') Sys.setenv(TAR = 'internal')
    tools::check_packages_in_dir(checkdir, basename(sourcepkg),
                                 reverse = list(repos = cranrepo, which = which),
                                 Ncpus = parallel::detectCores(),
                                 check_args = check_args)
  })
  group_output("Check results details", {
    details <- tools::check_packages_in_dir_details(checkdir)
    write.csv(details, file.path(checkdir, 'check-details.csv'))
    writeLines(paste(format(details), collapse = "\n\n"), file.path(checkdir, 'check-details.txt'))
    print(details)
  })
  tools::summarize_check_packages_in_dir_results(checkdir)
}

enable_all_repos <- function(){
  old <- options(repos = c(CRAN = 'https://cloud.r-project.org'))
  utils::setRepositories(ind = 1:4) #adds bioc
  my_universe <- Sys.getenv('MY_UNIVERSE')
  if(nchar(my_universe)){
    options(repos = c(my_universe = my_universe, getOption('repos')))
  }
  return(old)
}

group_output<- function(title, expr){
  if(Sys.getenv('CI') != ""){
    cat("::group::", title, "\n", sep = "")
    on.exit(cat("::endgroup::\n"))
  }
  cat("===========", title, "===========\n")
  eval(expr)
}

test_recheck <- function(pkg, which = 'strong'){
  checkdir <- paste(pkg, 'recheck', sep = '_')
  unlink(checkdir, recursive = TRUE)
  dir.create(checkdir)
  utils::download.packages(pkg, checkdir, repos = 'https://cloud.r-project.org')
  recheck(list.files(checkdir, pattern = 'tar.gz$', full.names = TRUE), which = which)
}
