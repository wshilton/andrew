FROM nvidia/cuda:12.2.0-devel-ubuntu22.04

RUN apt update && \
    apt install -y \
        software-properties-common && \
    apt-add-repository multiverse && \
    apt update && \
    apt install -y \
        build-essential \
        g++ \
        make \
        automake \
        bzip2 \
        unzip \
        wget \
        sox \
        libtool \
        git \
        subversion \
        python2.7 \
        python3 \
        zlib1g-dev \
        ca-certificates \
        gfortran \
        patch \
        ffmpeg \
        vim && \
    apt update && \
    yes | DEBIAN_FRONTEND=noninteractive apt install -yqq \
        intel-mkl && \
    rm -rf /var/lib/apt/lists/*

RUN ln -s /usr/bin/python2.7 /usr/bin/python

RUN git clone --depth 1 https://github.com/kaldi-asr/kaldi.git /opt/kaldi && \
    cd /opt/kaldi/tools && \
    make -j $(nproc) && \
    cd /opt/kaldi/src && \
    ./configure --shared --use-cuda && \
    make depend -j $(nproc) && \
    make -j $(nproc) && \
    rm -rf /opt/kaldi/.git

RUN wget https://bootstrap.pypa.io/pip/2.7/get-pip.py && \
    wget https://raw.githubusercontent.com/wshilton/andrew/main/vaes/requirements.txt && \
    python get-pip.py && \
    python -m pip install --user -r ./requirements.txt && \
    python -m pip install --user notebook boost

RUN apt update && \
    apt install -y \
    libboost-python-dev \
    python2-dev \
    python3-dev

RUN ln -s "/usr/lib/x86_64-linux-gnu/libboost_python310.so" /usr/lib/x86_64-linux-gnu/libboost_python.so

RUN git clone https://github.com/wshilton/kaldi-python.git /opt/kaldi-python && \
    cd /opt/kaldi-python && \
    KALDI_ROOT=/opt/kaldi make all -j $(nproc) && \
    rm -rf /opt/kaldi-python/.git

RUN git clone https://github.com/wshilton/andrew.git /opt/andrew
    
ENV PATH=/root/.local/bin:$PATH

CMD cd /opt/andrew/vaes/src &&\
    jupyter notebook --ip 0.0.0.0 --port 8888 --no-browser --allow-root
