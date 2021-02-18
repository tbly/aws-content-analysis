FROM registry.access.redhat.com/ubi8/python-36

USER root

# RUN rm -rf /etc/localtime
# RUN ln -s /usr/share/zoneinfo/Asia/Singapore /etc/localtime # Asia/Bangkok

# USER 1001

WORKDIR /opt/

# List the content of the development tools group to reveal all included packages:
# RUN dnf groupinfo "Development Tools"

# To install package group development tools on RHEL 8 / CentOS 8 execute the following dnf command:
# RUN dnf group install "Development Tools"

# In case you wish to remove the development tools group execute:
# RUN dnf group remove "Development Tools"

RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
RUN unzip awscliv2.zip
RUN ./aws/install

RUN dnf install npm

RUN python3 -m pip install --upgrade pip
RUN python3 -m pip install setuptools --upgrade

ADD requirements.txt /opt/
RUN python3 -m pip install -r requirements.txt

# Keep container running.
# CMD ["/usr/sbin/init"]

ENTRYPOINT ["/bin/sh"]