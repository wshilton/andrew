RUN apt-get update && apt-get upgrade -y && apt-get install -y \
    python2.7.6 \
    make
RUN python -m pip install requirements.txt
RUN git clone https://github.com/wshilton/andrew.git
RUN cd ./andrew/vaes && make all
