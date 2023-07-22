FROM python:2.7 AS compile-image

#TODO: Address intel-mkl not found when building image.
#TODO: Address certificate issues during kaldi install.
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    gcc \
    sox \
    gfortran \
    intel-mkl \
    python2.7 \
    make \
    ca-certificates
    
#TODO: Instead of cloning the entire repo during image build,
#might simply wget the requirements file.
RUN git clone https://github.com/wshilton/andrew.git
RUN python -m pip install --user -r ./andrew/vaes/requirements.txt
RUN python -m pip install --user notebook

FROM python:2.7 AS build-image
COPY --from=compile-image /root/.local /root/.local

ENV PATH=/root/.local/bin:$PATH
#In conjunction with the following jupyter command, execute 
#docker run -it -p 8888:8888 ubuntu:22.04
#in order to connect outside container at http://localhost:8888/

#TODO: Address certificate issue in kaldi build. Note linking of ssl files.

CMD git clone https://github.com/wshilton/andrew.git &&\
    cd ./andrew/vaes &&\
    ln -sT /usr/ssl /etc/ssl &&\
    make all &&\
    cd src &&\
    jupyter notbook --ip 0.0.0.0 --no-browser --allow-root

#User might synchronize container and host directories by executing
#docker run -it --mount src="$(pwd)",target=/tmp,type=bind k3_s3
#TODO: Consider file permissions
