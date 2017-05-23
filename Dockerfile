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

# Default password is conquest, you should probably change it
RUN echo 'dominions:conquest' |chpasswd

USER dominions
WORKDIR /home/dominions
ADD dom2v20b.zip dom2v20b.zip
ADD DOM500.ZIP DOM500.ZIP
ADD dosemurc dosemurc
ADD dominions.py dominions.py
ADD profile .profile
ADD CP437.TXT CP437.TXT
ADD ansi2unicode ansi2unicode

# Uncomment one of the following lines to install 
# the original Dominions or Dominions ][ (--dom2)
RUN ./dominions.py install gamedir
#RUN ./dominions.py install --dom2 gamedir

USER root
CMD    ["/usr/sbin/sshd", "-D"]
