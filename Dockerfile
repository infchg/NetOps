FROM ubuntu:14.04
MAINTAINER M Jua Carlos email: unjuca () gmail . com.
#  docker build https://github.com/docker/rootfs.git#container:docker

# Update the image with the latest packages 
RUN apt-get  update -y; apt-get  clean all

# Install Quagga Router (and iproute) 
RUN apt-get install -y quagga; apt-get  clean all


# VOLUME ["/usr/local/sdnbgp:/usr/local/sdnbgp:rw"]
# Add the templates file of the GW  Docker   files to config
# must be in context in oreder to docker build -t ubu,quag.bgp
#ADD  hosts  	/etc/hosts    
ADD  quagga/*  	/etc/quagga/

#RUN chmod a+x   /etc/quagga/pingtest.sh

#these do not really overwrite /etc/hosts on time
#COPY  hosts  	/etc/hosts    
#RUN head /etc/hosts   

#make sure the routers con be managed and they talk bgp/tcp
#EXPOSE 179 2601 2605

ENTRYPOINT [ "/bin/bash" ]


#sudo docker commit 55bb7a386063c213c9  ubu-qua
#docker build - < Dockerfile
