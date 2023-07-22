FROM python:2.7 AS compile-image

#TODO: Address intel-mkl prompting even after assume yes.
#TODO: Address certificate issues during kaldi install.
RUN apt-get update && \
    apt-get install -y \
    software-properties-common && \
    apt-add-repository non-free && \
    apt-get update && \
    apt-get install -qq \
    build-essential \
    gcc \
    sox \
    gfortran \
    intel-mkl \
    python2.7 \
    make \
    ca-certificates

#Get the requirements file from the repository
RUN wget --no-check-certificate --content-disposition https://raw.githubusercontent.com/wshilton/andrew/main/vaes/requirements.txt
#Install requirements along with jupyter
RUN python -m pip install --user -r ./requirements.txt
RUN python -m pip install --user notebook

FROM python:2.7 AS build-image
COPY --from=compile-image /root/.local /root/.local

ENV PATH=/root/.local/bin:$PATH
#In conjunction with the following jupyter CMD, execute 
#docker run -it -p 8888:8888 imagename:version
#in order to connect outside container at http://localhost:8888/
#Might synchronize container and host directories by executing
#docker run -it --mount src="$(pwd)",target=/tmp,type=bind k3_s3
#TODO: Consider file permissions

#TODO: Address certificate issue in kaldi build. Note linking of ssl files.

CMD git clone https://github.com/wshilton/andrew.git &&\
    cd ./andrew/vaes &&\
    ln -sT /usr/ssl /etc/ssl &&\
    make all &&\
    cd src &&\
    jupyter notbook --ip 0.0.0.0 --no-browser --allow-root
