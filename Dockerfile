# Version JDK8

FROM centos:7
MAINTAINER Flaviu Tusa, ftusa@shift7digital.com

RUN yum install -y java-1.8.0-openjdk-devel wget git maven

# Create users and groups
RUN mkdir -p /opt/cms
RUN mkdir -p /opt/cms/tomcat
RUN useradd -m -d /opt/cms cms

# Download and install tomcat
RUN cd /opt/cms/
RUN wget https://apache.mirrors.nublue.co.uk/tomcat/tomcat-8/v8.5.69/bin/apache-tomcat-8.5.69.tar.gz
RUN tar -zxvf apache-tomcat-8.5.69.tar.gz -C /opt/cms/tomcat --strip-components=1
RUN chgrp -R cms /opt/cms/tomcat/conf
RUN chmod g+rwx /opt/cms/tomcat/conf
RUN chmod g+r /opt/cms/tomcat/conf/*
RUN chown -R cms /opt/cms/tomcat/logs/ /opt/cms/tomcat/temp/ /opt/cms/tomcat/webapps/ /opt/cms/tomcat/work/
RUN chgrp -R cms /opt/cms/tomcat/bin
RUN chgrp -R cms /opt/cms/tomcat/lib
RUN chmod g+rwx /opt/cms/tomcat/bin
RUN chmod g+r /opt/cms/tomcat/bin/*

RUN rm -rf /opt/cms/tomcat/webapps/*
RUN rm -rf /opt/cms/tomcat/shared/lib/*
RUN cd /opt/cms/tomcat/ && wget https://storage.cloud.google.com/sandbox-bucket-test/cms-upgrade_beaconhippo-14.5.0.1-SNAPSHOT-distribution.tar.gz
RUN tar -xzf cms-upgrade_beaconhippo-14.5.0.1-SNAPSHOT-distribution.tar.gz webapps shared

VOLUME /opt/cms/tomcat/webapps
EXPOSE 8080
CMD ["/opt/cms/tomcat/bin/catalina.sh", "run"]
#
