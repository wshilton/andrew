RUN apt-get update && apt-get install -y \
    python2.7.6 \
    make
RUN python -m pip install requirements.txt
RUN python -m pip install notebook
RUN git clone https://github.com/wshilton/andrew.git
RUN cd ./andrew/vaes && make all
