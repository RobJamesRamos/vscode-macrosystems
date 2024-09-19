FROM gitpod/openvscode-server:latest

#===============================================================================
# Additions for cyverse, adapted from original vscode cyverse project
#===============================================================================
# Build-time metadata as defined at http://label-schema.org
ARG BUILD_DATE
ARG VCS_REF
ARG VERSION
LABEL org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.name="CyVerse VSCode" \
    org.label-schema.description="Built from GitPod Open VSCode, additional depends for CyVerse K8s workbench" \
    org.label-schema.url="https://cyverse.org" \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-url="e.g. https://github.com/cyverse-vice/vscode" \
    org.label-schema.vendor="CyVerse" \
    org.label-schema.version=$VERSION \
    org.label-schema.schema-version="1.0.0"

USER root

ARG DEBIAN_FRONTEND=noninteractive

# Install a few dependencies for iCommands, text editing, and monitoring instances
RUN apt-get update && \
    apt-get install -y lsb-release apt-transport-https curl gnupg2 libfuse2 gettext gcc less nodejs software-properties-common apt-utils glances htop nano  && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN apt-get update && \
    apt-get install -y vim-nox && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN apt-get update && \
    apt-get install -y emacs-nox && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN wget -qO - https://packages.irods.org/irods-signing-key.asc | apt-key add - && \
    echo "deb [arch=amd64] https://packages.irods.org/apt/ $(lsb_release -sc) main" >> /etc/apt/sources.list.d/renci-irods.list && \
    apt-get update && \
    apt install -y irods-icommands 
RUN wget -q -c \
    http://security.ubuntu.com/ubuntu/pool/main/o/openssl1.0/libssl1.0.0_1.0.2n-1ubuntu5_amd64.deb
RUN apt install -y \
    python3-urllib3 \
    python3-requests \
    ./libssl1.0.0_1.0.2n-1ubuntu5_amd64.deb && \
    rm -rf ./libssl1.0.0_1.0.2n-1ubuntu5_amd64.deb && \
    apt install -y irods-icommands && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Go
RUN wget -q -c https://dl.google.com/go/go1.17.6.linux-amd64.tar.gz -O - | tar -xz -C /usr/local
ENV PATH=$PATH:/usr/local/go/bin 

# Install Rust
RUN apt-get update && \
    apt-get install -y cargo rustc

# Install CyberDuck CLI
RUN echo "deb https://s3.amazonaws.com/repo.deb.cyberduck.io stable main" | tee /etc/apt/sources.list.d/cyberduck.list > /dev/null && \
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys FE7097963FEFBE72 && \
    apt-get update && \
    apt-get install duck

# Install MiniConda
ENV TZ America/Phoenix
ENV LANG=C.UTF-8 
ENV LC_ALL C.UTF-8
ENV PATH /opt/conda/bin:$PATH
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo $TZ > /etc/timezone

RUN apt-get update && \
    apt-get install -y wget bzip2 ca-certificates \
    libglib2.0-0 libxext6 libsm6 libxrender1 \
    gettext-base git mercurial subversion \
    tmux && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN wget --quiet \
    https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh \
    -O ~/miniforge.sh && \
    /bin/bash ~/miniforge.sh -b -p /opt/conda && \
    rm ~/miniforge.sh && \
    ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh && \
    echo ". /opt/conda/etc/profile.d/conda.sh" >> /home/workspace/.bashrc && \
    echo ". /opt/conda/etc/profile.d/mamba.sh" >> /home/workspace/.bashrc && \
    echo ". /opt/conda/etc/profile.d/conda.sh" >> /home/workspace/.zshrc && \
    echo ". /opt/conda/etc/profile.d/mamba.sh" >> /home/workspace/.zshrc && \
    chown -R 1000:1000 /opt/conda

# Install GitHub CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/etc/apt/trusted.gpg.d/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/trusted.gpg.d/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" > /etc/apt/sources.list.d/github-cli.list && \
    apt update && \
    apt install gh

COPY entry.sh /bin
RUN mkdir -p /home/workspace/.irods
RUN chown -R 1000:1000 /home/workspace/

#===============================================================================
# Download and install R and shiny server, adapted from rocker/shiny
#===============================================================================
# Add more up to date R repository and repository of cran packages
RUN apt-get update && apt-get install -y \ 
    software-properties-common \
    dirmngr && \
    wget -qO- https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc | sudo tee -a /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc && \
    add-apt-repository "deb https://cloud.r-project.org/bin/linux/ubuntu $(lsb_release -cs)-cran40/" && \
    add-apt-repository "ppa:c2d4u.team/c2d4u4.0+"

# Install R and R shiny package
RUN apt-get update && apt-get install -y \ 
    r-base \
    r-cran-shiny

# Installing shiny server
RUN apt-get update && apt-get install -y \
    gdebi-core \
    pandoc \
    pandoc-citeproc \
    libcurl4-gnutls-dev \
    libcairo2-dev \
    libxt-dev \
    xtail

RUN wget --no-verbose https://download3.rstudio.org/ubuntu-18.04/x86_64/VERSION -O "version.txt" && \
    VERSION=$(cat version.txt)  && \
    wget --no-verbose "https://download3.rstudio.org/ubuntu-18.04/x86_64/shiny-server-$VERSION-amd64.deb" -O ss-latest.deb && \
    gdebi -n ss-latest.deb && \
    rm -f version.txt ss-latest.deb && \
    . /etc/environment && \
    chown shiny:shiny /var/lib/shiny-server

EXPOSE 3838

COPY shiny-server.sh /usr/bin/shiny-server.sh

CMD ["/usr/bin/shiny-server.sh"]

#===============================================================================
# Build Geospatial, list taken from js2-jupyterhub
#===============================================================================
RUN apt-get update && \
    apt install -y \
    gdal-bin \
    lbzip2 \
    libfftw3-dev \
    libgdal-dev \
    libgeos-dev \
    libgsl0-dev \
    libgl1-mesa-dev \
    libglu1-mesa-dev \
    libhdf4-alt-dev \
    libhdf5-dev \
    libjq-dev \
    libpq-dev \
    libproj-dev \
    libprotobuf-dev \
    libnetcdf-dev \
    libsqlite3-dev \
    libssl-dev \
    libudunits2-dev \
    lsb-release \
    netcdf-bin \
    postgis \
    protobuf-compiler \
    sqlite3 \
    tk-dev \
    unixodbc \
    unixodbc-dev && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

#===============================================================================
# Additional R packages (not from conda/mamba)
#===============================================================================
# Install some useful cran packages
RUN apt-get update && apt-get install -y \
    r-cran-devtools \
    r-cran-caret \
    r-cran-crayon \
    r-cran-irkernel \
    r-cran-curl \
    r-cran-rodbc \
    r-cran-rsqlite \
    r-cran-duckdb \
    r-cran-tidyverse \
    r-cran-rmarkdown \
    r-cran-cairo

# Some dependancies for R vscode extension that are not in the repos
RUN R -e "install.packages(c('languageserver', 'httpgd', 'lintr'))"

#===============================================================================
# Dotnet Install
#===============================================================================
# Install dotnet 8 from ubuntu repos
RUN sudo apt-get update && \
    sudo apt-get install -y dotnet-sdk-8.0

#===============================================================================
# Installing Jupyter (not from conda/mamba)
#===============================================================================
RUN apt-get update && apt-get install -y \
    jupyter

#===============================================================================
# to restore permissions for the web interface
#===============================================================================
USER openvscode-server

#===============================================================================
# install R packages via conda
#===============================================================================
RUN mamba install --quiet --yes \
    'r-base' \
    'r-shiny' \
    'gcc_linux-64' \
    'gxx_linux-64' \
    'gfortran_linux-64' \
    'r-rcpp' \
    'r-devtools' \
    'r-caret' \
    'r-crayon' \
    'r-irkernel' \
    'r-rcurl' \
    'r-rodbc' \
    'r-rsqlite' \
    'r-duckdb' \
    'r-tidyverse' \
    'r-rmarkdown' \
    'r-cairo' \
    'r-languageserver' \
    'r-httpgd' \
    'r-lintr' \
    'unixodbc' && \
    conda clean --all -f -y

#===============================================================================
# Setup Dotnet to work with jupyter notebooks
#===============================================================================
# Install dotnet interactive
RUN dotnet tool install -g Microsoft.dotnet-interactive
ENV PATH $PATH:/home/workspace/.dotnet/tools

# Install jupyter and Python in conda
RUN mamba install --quiet --yes \
    'jupyter' \
    'ipykernel' && \
    conda clean --all -f -y

# Register dotnet kernals with jupyterlab
RUN dotnet interactive jupyter install

RUN python -m ipykernel install --user --name=python3

#===============================================================================
# Install vscode extensions by default
#===============================================================================
ENV OPENVSCODE_SERVER_ROOT="/home/.openvscode-server"
ENV OPENVSCODE="${OPENVSCODE_SERVER_ROOT}/bin/openvscode-server"

SHELL ["/bin/bash", "-c"]
RUN \
    exts=(\
        GitHub.vscode-pull-request-github \
        ms-toolsai.jupyter \
        REditorSupport.r \
        ms-python.python \
        rust-lang.rust-analyzer \
        golang.Go \
        # not on open-vsx
        # ms-dotnettools.csharp \
        muhammad-sammy.csharp \
        # not on open-vsx
        # ms-dotnettools.dotnet-interactive-vscode \
        Ionide.Ionide-fsharp \
    )\
    # Install the $exts
    && for ext in "${exts[@]}"; do ${OPENVSCODE} --install-extension "${ext}"; done
