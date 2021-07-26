# Version JDK11

FROM ubuntu:latest
MAINTAINER Flaviu Tusa, ftusa@shift7digital.com

RUN apt update
RUN apt install -y default-jre wget git maven unzip
RUN apt install -y default-jdk

# Create users and groups
RUN groupadd tomcat
RUN mkdir /opt/tomcat
RUN useradd -s /bin/nologin -g tomcat -d /opt/tomcat tomcat

# Download and install tomcat
RUN wget https://apache.mirrors.nublue.co.uk/tomcat/tomcat-8/v8.5.69/bin/apache-tomcat-8.5.69.tar.gz
RUN tar -zxvf apache-tomcat-8.5.69.tar.gz -C /opt/tomcat --strip-components=1
RUN cd /opt/tomcat/conf
RUN chgrp -R tomcat /opt/tomcat/conf
RUN chmod g+rwx /opt/tomcat/conf
RUN chmod g+r /opt/tomcat/conf/*
RUN chown -R tomcat /opt/tomcat/logs/ /opt/tomcat/temp/ /opt/tomcat/webapps/ /opt/tomcat/work/
RUN chgrp -R tomcat /opt/tomcat/bin
RUN chgrp -R tomcat /opt/tomcat/lib
RUN chmod g+rwx /opt/tomcat/bin
RUN chmod g+r /opt/tomcat/bin/*

RUN rm -rf /opt/tomcat/webapps/*
COPY wget.sh /tmp
RUN cd /tmp && chmod +x wget.sh
RUN ./wget.sh
COPY settings.xml /etc/maven/settings.xml
RUN cd /tmp/brxm-brxm-14.5.0-1/spa-sdk/examples/xm && mvn clean install
RUN cp /tmp/brxm-brxm-14.5.0-1/spa-sdk/examples/xm/cms/target/cms.war /opt/tomcat/webapps/cms.war
RUN cp /tmp/brxm-brxm-14.5.0-1/spa-sdk/examples/xm/essentials/target/essentials.war /opt/tomcat/webapps/essentials.war
RUN cp /tmp/brxm-brxm-14.5.0-1/spa-sdk/examples/xm/site/webapp/target/site.war /opt/tomcat/webapps/site.war
RUN chmod 777 /opt/tomcat/webapps/cms.war
RUN chmod 777 /opt/tomcat/webapps/essentials.war
RUN chmod 777 /opt/tomcat/webapps/site.war

VOLUME /opt/tomcat/webapps
EXPOSE 8080
CMD ["/opt/tomcat/bin/catalina.sh", "run"]