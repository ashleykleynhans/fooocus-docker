# Stage 1: Base
FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu22.04 as base

ARG INDEX_URL
ARG TORCH_VERSION
ARG XFORMERS_VERSION

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=on \
    SHELL=/bin/bash

# Install Ubuntu packages
RUN apt update && \
    apt -y upgrade && \
    apt install -y --no-install-recommends \
        software-properties-common \
        build-essential \
        python3.10-venv \
        python3-pip \
        python3-tk \
        python3-dev \
        nginx \
        bash \
        dos2unix \
        git \
        ncdu \
        net-tools \
        openssh-server \
        libglib2.0-0 \
        libsm6 \
        libgl1 \
        libxrender1 \
        libxext6 \
        ffmpeg \
        wget \
        curl \
        psmisc \
        rsync \
        vim \
        zip \
        unzip \
        htop \
        screen \
        tmux \
        pkg-config \
        libcairo2-dev \
        libgoogle-perftools4 \
        libtcmalloc-minimal4 \
        apt-transport-https \
        ca-certificates && \
    update-ca-certificates && \
    apt clean && \
    rm -rf /var/lib/apt/lists/* && \
    echo "en_US.UTF-8 UTF-8" > /etc/locale.gen

# Set Python
RUN ln -s /usr/bin/python3.10 /usr/bin/python

# Stage 2: Install Fooocus and python modules
FROM base as setup

# Create and use the Python venv
WORKDIR /
RUN python3 -m venv /venv

# Clone the git repo of Fooocus and set version
ARG FOOOCUS_VERSION
RUN git clone https://github.com/lllyasviel/Fooocus.git && \
    cd /Fooocus && \
    git checkout ${FOOOCUS_VERSION}

# Install the dependencies for Fooocus
WORKDIR /Fooocus
ENV TORCH_INDEX_URL=${INDEX_URL}
ENV TORCH_COMMAND="pip install torch==${TORCH_VERSION} torchvision --index-url ${TORCH_INDEX_URL}"
ENV XFORMERS_PACKAGE="xformers==${XFORMERS_VERSION}"
RUN source /venv/bin/activate && \
    ${TORCH_COMMAND} && \
    pip3 install -r requirements_versions.txt --extra-index-url ${TORCH_INDEX_URL} && \
    pip3 install ${XFORMERS_PACKAGE} --index-url ${TORCH_INDEX_URL} &&  \
    sed '$d' launch.py > setup.py && \
    python3 -m setup && \
    deactivate

# Install Jupyter, gdown and OhMyRunPod
RUN pip3 install -U --no-cache-dir jupyterlab \
        jupyterlab_widgets \
        ipykernel \
        ipywidgets \
        gdown \
        OhMyRunPod

# Install RunPod File Uploader
RUN curl -sSL https://github.com/kodxana/RunPod-FilleUploader/raw/main/scripts/installer.sh -o installer.sh && \
    chmod +x installer.sh && \
    ./installer.sh

# Install rclone
RUN curl https://rclone.org/install.sh | bash

# Install runpodctl
ARG RUNPODCTL_VERSION
RUN wget "https://github.com/runpod/runpodctl/releases/download/${RUNPODCTL_VERSION}/runpodctl-linux-amd64" -O runpodctl && \
    chmod a+x runpodctl && \
    mv runpodctl /usr/local/bin

# Install croc
RUN curl https://getcroc.schollz.com | bash

# Install speedtest CLI
RUN curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | bash && \
    apt install speedtest

# Install CivitAI Model Downloader
ARG CIVITAI_DOWNLOADER_VERSION
RUN git clone https://github.com/ashleykleynhans/civitai-downloader.git && \
    cd civitai-downloader && \
    git checkout tags/${CIVITAI_DOWNLOADER_VERSION} && \
    cp download.py /usr/local/bin/download-model && \
    chmod +x /usr/local/bin/download-model && \
    cd .. && \
    rm -rf civitai-downloader

# Remove existing SSH host keys
RUN rm -f /etc/ssh/ssh_host_*

# NGINX Proxy
COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY nginx/502.html /usr/share/nginx/html/502.html

# Copy Fooocus config
COPY fooocus/config.txt /Fooocus/config.txt

# Set template version
ARG RELEASE
ENV TEMPLATE_VERSION=${RELEASE}

# Set the venv path
ARG VENV_PATH
ENV VENV_PATH=${VENV_PATH}

# Copy the scripts
WORKDIR /
COPY --chmod=755 scripts/* ./

# Start the container
SHELL ["/bin/bash", "--login", "-c"]
CMD [ "/start.sh" ]
