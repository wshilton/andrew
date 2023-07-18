RUN apt-get update && apt-get upgrade -y && apt-get install -y \
    python2.7.6
RUN python -m pip install requirements.txt
RUN make all
