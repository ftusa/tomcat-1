# Version JDK8

FROM centos:7
MAINTAINER Flaviu Tusa, ftusa@shift7digital.com

RUN yum install -y java-1.8.0-openjdk-devel wget git maven
RUN yum install -y unzip

# Create users and groups
RUN groupadd tomcat
RUN mkdir /opt/tomcat
RUN useradd -s /bin/nologin -g tomcat -d /opt/tomcat tomcat

# Download and install tomcat
RUN wget https://apache.mirrors.nublue.co.uk/tomcat/tomcat-8/v8.5.69/bin/apache-tomcat-8.5.69.tar.gz
RUN tar -zxvf apache-tomcat-8.5.69.tar.gz -C /opt/tomcat --strip-components=1
#Add log4j2.xml
RUN cd /opt/tomcat/conf
RUN wget https://documentation.bloomreach.com/binaries/content/assets/connect/library/enterprise/jee-application-server-support/13.2/log4j2-dist.xml
RUN mv log4j2-dist.xml log4j2.xml
RUN chgrp -R tomcat /opt/tomcat/conf
RUN chmod g+rwx /opt/tomcat/conf
RUN chmod g+r /opt/tomcat/conf/*
RUN chown -R tomcat /opt/tomcat/logs/ /opt/tomcat/temp/ /opt/tomcat/webapps/ /opt/tomcat/work/
RUN chgrp -R tomcat /opt/tomcat/bin
RUN chgrp -R tomcat /opt/tomcat/lib
RUN chmod g+rwx /opt/tomcat/bin
RUN chmod g+r /opt/tomcat/bin/*

RUN rm -rf /opt/tomcat/webapps/*
RUN cd /tmp && wget https://github.com/bloomreach/brxm/archive/refs/tags/brxm-14.5.0-1.zip
RUN unzip brxm-14.5.0-1.zip
COPY settings.xml /etc/maven/settings.xml
RUN cd /tmp/brxm-brxm-14.5.0-1/spa-sdk/examples/xm && mvn clean install
RUN cp /tmp/brxm-brxm-14.5.0-1/spa-sdk/examples/xm/cms/target/cms.war /opt/tomcat/webapps/cms.war
RUN cp /tmp/brxm-brxm-14.5.0-1/spa-sdk/examples/xm/essentials/target/essentials.war /opt/tomcat/webapps/essentials.war
RUN chmod 777 /opt/tomcat/webapps/cms.war
RUN chmod 777 /opt/tomcat/webapps/essentials.war

VOLUME /opt/tomcat/webapps
EXPOSE 8080
CMD ["/opt/tomcat/bin/catalina.sh", "run"]