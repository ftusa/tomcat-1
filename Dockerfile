# Version JDK8

FROM centos:7
MAINTAINER Flaviu Tusa, ftusa@shift7digital.com

COPY createBR14server.sh /
RUN chmod +x /createBR14server.sh && /createBR14server.sh

VOLUME /opt/cms/tomcat/webapps
EXPOSE 8080
#
