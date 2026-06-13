FROM ghcr.io/r-devel/rcheckserver/ubuntu

# Install quarto (seems like CRAN has it?)
RUN \
  curl -L -o quarto.deb "https://github.com/quarto-dev/quarto-cli/releases/download/v1.10.11/quarto-1.10.11-linux-$(dpkg --print-architecture).deb" &&\
  dpkg -i quarto.deb &&\
  rm quarto.deb &&\
  quarto --version

COPY rechecktools /rechecktools
RUN R -e 'install.packages("remotes");remotes::install_local("/rechecktools");library(rechecktools)'
