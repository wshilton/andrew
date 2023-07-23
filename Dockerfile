FROM python:2.7 AS image

#First authorize non-free material from apt repository,
#followed by an install of some prereqs. Then install MKL 
#in which we must be particularly forceful about the default
#config and then we install python. 
RUN apt-get update && \
    apt-get install -y \
    software-properties-common && \
    apt-add-repository non-free && \
    apt-get update && \
    apt-get install -y \
    build-essential \
    gcc \
    sox \
    gfortran \
    make \
    ca-certificates && \
    yes | DEBIAN_FRONTEND=noninteractive apt-get install -yqq \
    intel-mkl && \
    apt-get update && \
    apt-get install -y \
    python2.7

#Get the requirements file from the repository
RUN wget --content-disposition https://raw.githubusercontent.com/wshilton/andrew/main/vaes/requirements.txt

#Install requirements along with jupyter
RUN python -m pip install --user -r ./requirements.txt

RUN python -m pip install --user notebook

#TODO: The dependency on Kaldi is ideally more suited for handling while compiling the image,
#unlike the remainder of the repository, which is the subject of active work. So some re-arch
#is in order.
#TODO: Kaldi encounters cert errors here.
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

CMD cd ./andrew/vaes/src &&\
    jupyter notbook --ip 0.0.0.0 --no-browser --allow-root
