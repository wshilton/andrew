#Docker installation
#sudo apt-get update && sudo apt-get install -y ca-certificates curl gnupg && sudo install -m 0755 -d /etc/apt/keyrings
#curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg && sudo chmod a+r /etc/apt/keyrings/docker.gpg
#echo \
#  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
#  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
#  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
#sudo apt-get update && sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

#Image building
#sudo docker build --progress=plain -t andrew:1.0 . > build.log 2>&1

#Running container
#sudo docker run -i -p 8888:8888 andrew:1.0

FROM nvidia/cuda:12.2.0-devel-ubuntu22.04
#Kaldi has docker images, but not in support of ubuntu22.04. Consider pulling appropriate components into Kaldi.
#This would subsume Hsu's custom make of Kaldi, resulting in slight rearch.

#First authorize non-free material from apt repository,
#followed by an install of some prereqs. Then install MKL 
#in which we must be particularly forceful about the default
#config and then we install python. 
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
    find /opt/kaldi  -type f \( -name "*.o" -o -name "*.la" -o -name "*.a" \) -exec rm {} \; && \
    rm -rf /opt/kaldi/.git

RUN wget https://bootstrap.pypa.io/pip/2.7/get-pip.py && \
    wget https://raw.githubusercontent.com/wshilton/andrew/main/vaes/requirements.txt && \
    python get-pip.py && \
    python -m pip install --user -r ./requirements.txt && \
    python -m pip install --user notebook boost

RUN apt update && \
    apt install -y \
    libboost-all-dev \
    python2-dev \
    python3-dev

#TODO: Investigate binding issues in kaldi-python wrappers.
#Kaldi-python has seen no activity for about 6 years. An active alternative
#is https://github.com/pykaldi/pykaldi#.
#A type change, among other things, in Kaldi is responsible for a failed binding.
#Forking kaldi-python.

RUN git clone https://github.com/wshilton/kaldi-python.git /opt/kaldi-python && \
    cd /opt/kaldi-python && \
    KALDI_ROOT=/opt/kaldi make all -j $(nproc) && \
    find /opt/kaldi-python  -type f \( -name "*.o" -o -name "*.la" -o -name "*.a" \) -exec rm {} \; && \
    rm -rf /opt/kaldi-python/.git
    
#ENV PATH=/root/.local/bin:$PATH

#In conjunction with the following jupyter CMD, execute 
#docker run -it -p 8888:8888 imagename:version
#in order to connect outside container at http://localhost:8888/
#Might synchronize container and host directories by executing
#docker run -it --mount src="$(pwd)",target=/tmp,type=bind k3_s3
#TODO: Consider file permissions

#CMD node /app/server.js& \
#    cd ./andrew/vaes/src &&\
#    jupyter notebook --ip 0.0.0.0 --no-browser --allow-root
