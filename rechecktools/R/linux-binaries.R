# The goal of this function is to speed up installation of dependencies.
# This is done in two ways:
#  - Try to get precompiled binaries when available (mainly on ubuntu)
#  - Download files in parallel using curl
# The latter can be removed once fixed in base-R: https://github.com/r-devel/r-svn/pull/155
preinstall_linux_binaries <- function(tocheck){
  rver <- getRversion()
  distro <- system2('lsb_release', '-sc', stdout = TRUE)
  options(HTTPUserAgent = sprintf("R/%s R (%s); r-universe (%s)", rver, paste(rver, R.version$platform, R.version$arch, R.version$os), distro))
  bioc <- sprintf("https://bioc.r-universe.dev/bin/linux/%s/4/", distro)
  cran <- sprintf("https://p3m.dev/cran/__linux__/%s/latest", distro)
  repos <- c(cran, bioc)
  db <- utils::available.packages(repos = c(CRAN = cran, BIOC = bioc, official_bioc_repos()))
  checkdeps <- unique(unlist(unname(tools::package_dependencies(tocheck, db = db, which = 'most'))))
  alldeps <- tools::package_dependencies(checkdeps, db = db, recursive = TRUE)
  packages <- unlist(lapply(checkdeps, function(x){
    c(rev(alldeps[[x]]), x)
  }))
  packages <- intersect(unique(packages), row.names(db))
  packages <- setdiff(packages, loadedNamespaces())
  versions <- db[packages, 'Version']
  mirrors <- db[packages, 'Repository']
  urls <- sprintf("%s/%s_%s.tar.gz", mirrors, packages,  versions)
  destdir <- tempfile()
  dir.create(destdir)
  pwd <- setwd(destdir)
  on.exit(setwd(pwd), add = TRUE)
  on.exit(unlink(destdir, recursive = TRUE), add = TRUE)
  res <- curl::multi_download(urls)
  res$ok <- res$success & res$status_code == 200
  failures <- res$destfile[!res$ok]
  if(length(failures)){
    warning("Failed downloads for: ", paste(failures, collapse = ', '))
    unlink(failures)
    res <- res[res$ok,]
  }
  utils::install.packages(res$destfile, repos = NULL, Ncpus = parallel::detectCores())
}

official_bioc_repos <- function(){
  version <- utils:::.BioC_version_associated_with_R_version()
  sprintf(c(
    BioCsoft = "https://bioconductor.org/packages/%s/bioc",
    BioCann = "https://bioconductor.org/packages/%s/data/annotation",
    BioCexp = "https://bioconductor.org/packages/%s/data/experiment"
  ), version)
}
