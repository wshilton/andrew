#Docker installation
#sudo apt-get update
#sudo apt-get install ca-certificates curl gnupg
#sudo install -m 0755 -d /etc/apt/keyrings
#curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
#sudo chmod a+r /etc/apt/keyrings/docker.gpg
#echo \
#  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
#  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
#  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
#sudo apt-get update
#sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
#sudo docker run hello-world
#Create ssl key for container's reverse proxy
#openssl req -newkey rsa:2048 -nodes -keyout key -x509 -sha256 -days 3650 -subj /CN=localhost -out crt
#Write instructions for reverse proxy to file
#echo "let rf=require('fs').readFileSync; require('https').createServer({key:rf('/app/key'),cert:rf('/app/crt')},(req,res)=>{res.end('yay! \n')}).listen(443); console.log('ready \n')" > ./server.js

#Image building
#sudo docker build -t andrew1.0 . > build.log 2>&1

#Running container
#sudo docker run -i -p 443:443 -p 8888:8888 -v $PWD:/app andrew:1.0

FROM node:bullseye

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
#Get pip
RUN wget --content-disposition https://bootstrap.pypa.io/pip/2.7/get-pip.py

#Install pip and the requirements along with jupyter
RUN /usr/bin/python2.7 get-pip.py
RUN /usr/bin/python2.7 -m pip install --user -r ./requirements.txt
RUN /usr/bin/python2.7 -m pip install --user notebook

#TODO: The dependency on Kaldi is ideally more suited for handling while compiling the image,
#unlike the remainder of the repository, which is the subject of active work. So some re-arch
#is in order.
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

CMD node /app/server.js& \
    cd ./andrew/vaes/src &&\
    jupyter notebook --ip 0.0.0.0 --no-browser --allow-root
