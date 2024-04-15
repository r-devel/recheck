FROM ghcr.io/r-devel/rcheckserver/ubuntu

COPY rechecktools /rechecktools
RUN R -e 'install.packages("remotes");remotes::install_local("/rechecktools");library(rechecktools)'
