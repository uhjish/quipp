#!/bin/bash -x
# setup paths for install

export PATH="$HOME/miniconda/bin:$PATH"

CURDIR=`pwd`
VENV_NAME="survey_env"
UBU16_APTPKG=""
CONDA_CHAN="intel"
CONDA_PYPKGS="pandas scikit-learn cython rpy2"
CONDA_RPKGS=" r-feather libiconv r-survival r-dbi"
CONDA_PYVER="python=3.6"
CONDA_RVER="r-base=3.4.1"
CONDA_LIST="$CONDA_PYVER $CONDA_RVER"
CONDA_PKGS="$CONDA_PYPKGS $CONDA_RPKGS"
R_PKGS="c('survey','MonetDB.R')"
R_REPO="http://r-forge.r-project.org"

COND=`which conda`
COND_EXISTS=$?

setup_miniconda (){
    PLATF=`uname`
    # setup miniconda3
    # wget https://repo.continuum.io/miniconda/Miniconda3-latest-MacOSX-x86_64.sh
    sudo apt-get update && \
    sudo apt-get install -y curl gcc wget make g++ openssl libreadline-dev \
        libssl-dev libpcre3-dev zlib1g-dev gfortran lzop liblzo2-dev httpie zsh && \
    wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh \
        -O miniconda.sh && \
    chmod +x miniconda.sh && \
    yes | ./miniconda.sh -b -p $HOME/miniconda
}

setup_venv () {

    echo "update conda and add intel channel" && \
    conda update -y -q conda && \
    conda info -a && \
    echo "create conda env with intel python 3.6 and gnu r 3.4.1" && \
    conda create -n ${VENV_NAME} -c ${CONDA_CHAN} ${CONDA_PYVER} ${CONDA_RVER} && \
    source activate ${VENV_NAME} && \
    conda install -c ${CONDA_CHAN} ${CONDA_PKGS}
    echo "install required R packages" && \
    R --vanilla --slave -e "install.packages($R_PKGS, repos='$R_REPO')" && \
    echo "activate the env and install package and dev requirements with pip" && \
    conda install --file requirements-dev.txt && \
    pip install -e .

}

install (){

    if [ $COND_EXISTS -eq 0 ]; then
        echo "found conda at $COND, skipping the install..."
    else
        echo "couldn't find miniconda on the path, installing..."
        setup_miniconda
    fi

    setup_venv
}

if [ ! -f .develop.lock ]; then
    echo "setting up development environment..."
    install
    survey_stats
    if [ $? -eq 0 ]; then
        echo "environment ready!"
        touch .develop.lock
    fi
else
    echo "environment exists, getting it ready..."
    source activate ${VENV_NAME}
    echo "environment ready!"
fi
