FROM       ubuntu:16.04
MAINTAINER Braddock Gaskill "https://github.com/braddockcg"
ARG VERSION

RUN apt-get update
RUN apt-get install -y dosemu dos2unix sudo zip unzip file telnet 
RUN apt-get install -y screen openssh-client vim less python3-pip
RUN apt-get install -y openssh-server
RUN pip3 install filelock
RUN mkdir /var/run/sshd

# RUN echo 'root:root' |chpasswd
# RUN sed -ri 's/^PermitRootLogin\s+.*/PermitRootLogin yes/' /etc/ssh/sshd_config
# RUN sed -ri 's/UsePAM yes/#UsePAM yes/g' /etc/ssh/sshd_config
RUN sed -ri 's/X11Forwarding yes/X11Forwarding no/g' /etc/ssh/sshd_config
RUN sed -ri 's/Subsystem sftp/#Subsystem sftp/g' /etc/ssh/sshd_config

RUN echo >>/etc/ssh/sshd_config
RUN echo 'AllowTcpForwarding no' >>/etc/ssh/sshd_config
RUN echo 'PermitTunnel no' >>/etc/ssh/sshd_config
RUN echo 'ForceCommand /home/dominions/dominions.py --gamedir /home/dominions/gamedir run' >>/etc/ssh/sshd_config

EXPOSE 22

RUN useradd -ms /bin/bash dominions

# Default password is conquest, you should probably change it
RUN echo 'dominions:conquest' |chpasswd

USER dominions
WORKDIR /home/dominions
ADD archive/dom2v20b.zip archive/dom2v20b.zip
ADD archive/DOM500.ZIP archive/DOM500.ZIP
ADD src src
ADD dosemurc dosemurc
ADD dominions.py dominions.py
#ADD profile .profile
ADD CP437.TXT CP437.TXT
ADD ansi2unicode ansi2unicode

RUN ./dominions.py install --version ${VERSION} gamedir

USER root
CMD    ["/usr/sbin/sshd", "-D"]
