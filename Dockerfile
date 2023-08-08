#Docker installation
#sudo apt-get update && sudo apt-get install -y ca-certificates curl gnupg && sudo install -m 0755 -d /etc/apt/keyrings
#curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg && sudo chmod a+r /etc/apt/keyrings/docker.gpg
#echo \
#  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
#  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
#  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
#sudo apt-get update && sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

#Image building
#sudo docker build -t andrew1.0 . > build.log 2>&1

#Running container
#sudo docker run -i -p 8888:8888 andrew:1.0

FROM buildpack-deps:bookworm

#First authorize non-free material from apt repository,
#followed by an install of some prereqs. Then install MKL 
#in which we must be particularly forceful about the default
#config and then we install python. 
RUN apt update && \
    apt install -y \
        software-properties-common && \
    apt-add-repository non-free && \
    apt update && \
    apt install -y \
        build-essential \
        gcc \
        sox \
        gfortran \
        make \
        zlib1g-dev \
        automake \
        autoconf \
        unzip \
        libtool \
        subversion \
        python-dev && \
    apt update && \
    yes | DEBIAN_FRONTEND=noninteractive apt install -yqq \
        intel-mkl && \
    apt update && \
    apt install -y \
        python2.7 \
        python-is-python2

#TODO: Install graphics drivers

#Get the requirements file from the repository
RUN wget --content-disposition https://raw.githubusercontent.com/wshilton/andrew/main/vaes/requirements.txt
#Get pip
RUN wget --content-disposition https://bootstrap.pypa.io/pip/2.7/get-pip.py

#Install pip and the requirements along with jupyter
RUN python get-pip.py
RUN python -m pip install --user -r ./requirements.txt
RUN python -m pip install --user notebook

#TODO: The dependency on Kaldi is ideally more suited for handling while compiling the image,
#unlike the remainder of the repository, which is the subject of active work. So some re-arch
#is in order.
RUN git clone https://github.com/wshilton/andrew.git &&\
    cd ./andrew/vaes &&\
    make all
    
ENV PATH=/root/.local/bin:$PATH

#In conjunction with the following jupyter CMD, execute 
#docker run -it -p 8888:8888 imagename:version
#in order to connect outside container at http://localhost:8888/
#Might synchronize container and host directories by executing
#docker run -it --mount src="$(pwd)",target=/tmp,type=bind k3_s3
#TODO: Consider file permissions

CMD node /app/server.js& \
    cd ./andrew/vaes/src &&\
    jupyter notebook --ip 0.0.0.0 --no-browser --allow-root
