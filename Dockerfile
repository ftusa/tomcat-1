# Version JDK8

FROM centos:7
MAINTAINER Flaviu Tusa, ftusa@shift7digital.com

COPY createBR14server.sh /
RUN chmod +x /createBR14server.sh && /createBR14server.sh
USER cms
RUN cd /opt/cms/tomcat/webapps/my-project/ && mvn -Pcargo.run -Drepo.path=./storage

VOLUME /opt/cms/tomcat/webapps
EXPOSE 8080
#
