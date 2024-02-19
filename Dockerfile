# For paperspace gradient
# Based on https://github.com/gradient-ai/base-container
# Style-Bert-VITS2 are NOT included in this image, only for environment setup

# ==================================================================
# Details
# ------------------------------------------------------------------
# Ubuntu 22.04, Python 3.10
# CUDA Toolkit 12.1, CUDNN 8.9.7
# PyTorch 2.1.2 (cuda 12.1)
# Jupyter Lab
# Huggingface CLI
# Other Python packages in requirements.txt

# ==================================================================
# Initial setup
# ------------------------------------------------------------------

# Ubuntu 22.04 as base image
FROM ubuntu:22.04
# RUN yes| unminimize

RUN sed -i 's@archive.ubuntu.com@ftp.jaist.ac.jp/pub/Linux@g' /etc/apt/sources.list

# Set ENV variables
ENV LANG C.UTF-8
ENV SHELL=/bin/bash
ENV DEBIAN_FRONTEND=noninteractive

ENV APT_INSTALL="apt-get install -y --no-install-recommends"
ENV PIP_INSTALL="python3 -m pip --no-cache-dir install --upgrade"
ENV GIT_CLONE="git clone --depth 10"


# ==================================================================
# Tools
# ------------------------------------------------------------------

RUN apt-get update && \
    $APT_INSTALL \
    build-essential \
    ca-certificates \
    wget \
    git \
    curl \
    unzip \
    zip \
    nano \
    ffmpeg \
    sudo \
    software-properties-common \
    gnupg \
    python3 \
    python3-pip \
    python3-dev

# ==================================================================
# Git-lfs
# ------------------------------------------------------------------

RUN curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | sudo bash && \
    $APT_INSTALL git-lfs

# Add symlink so python and python3 commands use same python3.9 executable
RUN ln -s /usr/bin/python3 /usr/local/bin/python    


# ==================================================================
# Installing CUDA packages (CUDA Toolkit 12.1 and CUDNN 8.9.7)
# ------------------------------------------------------------------
RUN wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-ubuntu2204.pin && \
    mv cuda-ubuntu2204.pin /etc/apt/preferences.d/cuda-repository-pin-600 && \
    wget https://developer.download.nvidia.com/compute/cuda/12.1.0/local_installers/cuda-repo-ubuntu2204-12-1-local_12.1.0-530.30.02-1_amd64.deb && \
    dpkg -i cuda-repo-ubuntu2204-12-1-local_12.1.0-530.30.02-1_amd64.deb && \
    cp /var/cuda-repo-ubuntu2204-12-1-local/cuda-*-keyring.gpg /usr/share/keyrings/ && \
    apt-get update && \
    $APT_INSTALL cuda && \  
    rm cuda-repo-ubuntu2204-12-1-local_12.1.0-530.30.02-1_amd64.deb

# Installing CUDNN
RUN apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/3bf863cc.pub && \
    add-apt-repository "deb https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/ /" && \
    apt-get update && \
    $APT_INSTALL libcudnn8=8.9.7.29-1+cuda12.2  \
    libcudnn8-dev=8.9.7.29-1+cuda12.2


ENV PATH=$PATH:/usr/local/cuda/bin
ENV LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH


# ==================================================================
# PyTorch
# ------------------------------------------------------------------

# Based on https://pytorch.org/get-started/locally/

RUN $PIP_INSTALL torch==2.1.2 torchvision==0.16.2 torchaudio==2.1.2 --index-url https://download.pytorch.org/whl/cu121

# ==================================================================
# Jupyter Lab
# ------------------------------------------------------------------

RUN $PIP_INSTALL jupyterlab

# ==================================================================
# huggingface_cli
# ------------------------------------------------------------------

RUN $PIP_INSTALL "huggingface_hub[cli]"

# ==================================================================
# Other Python packages
# ------------------------------------------------------------------

COPY requirements.txt /tmp/requirements.txt

RUN $PIP_INSTALL -r /tmp/requirements.txt && \
    rm /tmp/requirements.txt

# ==================================================================
# Startup
# ------------------------------------------------------------------

EXPOSE 8888 6006

CMD jupyter lab --allow-root --ip=0.0.0.0 --no-browser --ServerApp.trust_xheaders=True --ServerApp.disable_check_xsrf=False --ServerApp.allow_remote_access=True --ServerApp.allow_origin='*' --ServerApp.allow_credentials=True