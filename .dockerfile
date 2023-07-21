FROM python:2.7 AS compile-image

RUN apt-get update && apt-get install -y --no-install-recommends\
    build-essential \
    gcc \
    sox \
    gfortran \
    intel-mkl \
    python2.7 \
    make \
    ca-certificates
    

RUN git clone https://github.com/wshilton/andrew.git
RUN python -m pip install --user -r ./andrew/vaes/requirements.txt
RUN python -m pip install --user notebook

FROM python:2.7 AS build-image
COPY --from=compile-image /root/.local /root/.local
#TODO: Consider copying over repo somehow
#COPY --from=compile-image ./andrew ./

ENV PATH=/root/.local/bin:$PATH
#In conjunction with the following, execute 
#docker run -it -p 8888:8888 ubuntu:22.04
#in order to connect outside container at http://localhost:8888/

CMD git clone https://github.com/wshilton/andrew.git &&\
    cd ./andrew/vaes &&\
    ln -sT /usr/ssl /etc/ssl &&\
    make all &&\
    cd src &&\
    jupyter notbook --ip 0.0.0.0 --no-browser --allow-root

#Synchronize container and host directories by executing
#docker run -it --mount src="$(pwd)",target=/tmp,type=bind k3_s3
#TODO: Consider file permissions
