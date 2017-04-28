FROM       ubuntu:16.04
MAINTAINER Braddock Gaskill "https://github.com/braddockcg"
# MAINTAINER Aleksandar Diklic "https://github.com/rastasheep"

RUN apt-get update

RUN apt-get install -y dosemu dos2unix sudo zip unzip file telnet 
RUN apt-get install -y screen openssh-client vim less python3-pip
RUN apt-get install -y openssh-server
RUN pip3 install filelock
RUN mkdir /var/run/sshd

# RUN echo 'root:root' |chpasswd

# RUN sed -ri 's/^PermitRootLogin\s+.*/PermitRootLogin yes/' /etc/ssh/sshd_config
# RUN sed -ri 's/UsePAM yes/#UsePAM yes/g' /etc/ssh/sshd_config

EXPOSE 22

RUN useradd -ms /bin/bash dominions
RUN echo 'dominions:conquest' |chpasswd
USER dominions
WORKDIR /home/dominions
ADD dom2v20b.zip dom2v20b.zip
ADD dosemurc dosemurc
ADD dominions.py dominions.py
#RUN chmod a+x dominions.py
RUN ./dominions.py install gamedir

USER root
CMD    ["/usr/sbin/sshd", "-D"]
