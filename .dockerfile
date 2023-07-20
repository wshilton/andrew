FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    python2.7.6 \
    make

RUN python -m pip install requirements.txt
RUN python -m pip install notebook

RUN git clone https://github.com/wshilton/andrew.git

RUN cd ./andrew/vaes && make all && cd src

#In conjunction with the following, execute docker run -it -p 8888:8888 ubuntu:22.04
#in order to connect outside continer at http://localhost:8888/
CMD jupyter notbook --ip 0.0.0.0 --no-browser --allow-root
