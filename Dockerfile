FROM python:2.7 AS image

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
    make && \
    yes | DEBIAN_FRONTEND=noninteractive apt install -yqq \
    intel-mkl && \
    apt update && \
    apt install -y \
    python2.7

#Get the requirements file from the repository
RUN wget --content-disposition https://raw.githubusercontent.com/wshilton/andrew/main/vaes/requirements.txt

#Install requirements along with jupyter
RUN python -m pip install --user -r ./requirements.txt
RUN python -m pip install --user notebook

#TODO: The dependency on Kaldi is ideally more suited for handling while compiling the image,
#unlike the remainder of the repository, which is the subject of active work. So some re-arch
#is in order.
#TODO: Wget cannot seem to resolve certs from within the container. Currently
#implementing a reverse proxy on the host using Caddy.
RUN git clone https://github.com/wshilton/andrew.git &&\
    cd ./andrew/vaes &&\
    make all

#Various attempts at resolving certificate issue
#Solution 1. Implement a reverse proxy with Caddy
#RUN apt install -y debian-keyring debian-archive-keyring apt-transport-https
#RUN curl -1sLfk 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
#RUN curl -1sLfk 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | tee /etc/apt/sources.list.d/caddy-stable.list
#RUN apt update
#RUN apt install -y caddy sudo libnss3-tools
#RUN sudo setcap cap_net_bind_service=+ep $(which caddy)
#RUN printf "localhost:80 {\n        reverse_proxy localhost:8080\n}" > ./Caddyfile
#RUN caddy fmt --overwrite ./Caddyfile
#RUN caddy start
#Solution 2. Reroute connects with iptables or nftables.
#RUN apt install -y iptables sudo
#RUN echo "/lib/x86_64-linux-gnu/xtables" >> /etc/ld.so.conf.d/x86_64-linux-gnu.conf
#RUN ldconfig
#RUN sudo iptables-nft -t nat -A PREROUTING -p tcp ! -s 172.18.0.0/24 -m tcp --dport 80 -j REDIRECT --to-port 8000
#RUN sudo iptables-nft -t nat -A PREROUTING -p tcp ! -s 172.18.0.0/24 -m tcp --dport 443 -j REDIRECT --to-port 8080
#RUN apt install -y nftables sudo
#RUN sudo nft add rule ip nat PREROUTING ip saddr != 172.18.0.0/24 tcp dport 80 counter redirect to :8000
#RUN sudo nft add rule ip nat PREROUTING ip saddr != 172.18.0.0/24 tcp dport 443 counter redirect to :8080
#RUN ls /usr/share/ca-certificates
#RUN update-ca-certificates
#Solution 3. Override wget with forced no-cert in the make system through a dash alias.
#RUN echo 'alias wget="wget --invalid-option"' > ./.bashrc && /usr/bin/bash source ./.bashrc
#RUN cat ./.bashrc
#RUN echo 'wget' > ./testscript.sh && chmod +x ./testscript.sh && ./testscript.sh
#RUN ln -sf /bin/bash /bin/sh
#TODO: Integrate Solution 4 into this build.
#Solution 4. A simpler reverse proxy using node.js. This seems to work.
#openssl req -newkey rsa:2048 -nodes -keyout key -x509 -sha256 -days 3650 -subj /CN=localhost -out crt
#FROM node:lts-alpine
#RUN  echo "let rf=require('fs').readFileSync; require('https').createServer({key:rf('/app/key'),cert:rf('/app/crt')},(req,res)=>{res.end('yay! \n')}).listen(443); console.log('ready \n')" > ./server.js
#CMD node server.js& \
#    wget -nv -T 10 -t 1 http://www.openfst.org/twiki/pub/FST/FstDownload/openfst-1.7.2.tar.gz && fg
#run container with -ip 443:443 -v $PWD:/app
    
ENV PATH=/root/.local/bin:$PATH

#In conjunction with the following jupyter CMD, execute 
#docker run -it -p 8888:8888 imagename:version
#in order to connect outside container at http://localhost:8888/
#Might synchronize container and host directories by executing
#docker run -it --mount src="$(pwd)",target=/tmp,type=bind k3_s3
#TODO: Consider file permissions

CMD apt update && apt install -y ca-certificates && update-ca-certificates &&\
    git clone https://github.com/wshilton/andrew.git &&\
    cd ./andrew/vaes &&\
    make all &&\
    cd ./andrew/vaes/src &&\
    jupyter notbook --ip 0.0.0.0 --no-browser --allow-root

CMD apt update &&\
    apt install -y \
    ca-certificates && \
    update-ca-certificates && \
    #printf "localhost:80 {\n        reverse_proxy localhost:8000\n}\n\n localhost:443 {\n        reverse_proxy localhost:8080\n}" > ./Caddyfile &&\
    #caddy fmt --overwrite ./Caddyfile &&\
    #caddy start &&\
    caddy reverse-proxy --from :443 --to https://localhost:8080 && \
    wget -nv -T 10 -t 1 http://www.openfst.org/twiki/pub/FST/FstDownload/openfst-1.7.2.tar.gz 
