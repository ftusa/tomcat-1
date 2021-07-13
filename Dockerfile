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
RUN cd /tmp && git clone https://github.com/daniel-rhoades/hippo-gogreen.git
RUN cd /tmp/hippo-gogreen && mvn clean install
RUN cp /tmp/hippo-gogreen/cms/target/cms.war /opt/cms/tomcat/webapps/cms.war
RUN chmod 777 /opt/cms/tomcat/webapps/cms.war
RUN cp /tmp/hippo-gogreen/site/target/site.war /opt/cms/tomcat/webapps/site.war
RUN chmod 777 /opt/cms/tomcat/webapps/site.war
RUN cp /tmp/hippo-gogreen/essentials/target/essentials.war /opt/cms/tomcat/webapps/essentials.war
RUN chmod 777 /opt/cms/tomcat/webapps/essentials.war
RUN cp /tmp/hippo-gogreen/repository/target/repository.war /opt/cms/tomcat/webapps/repository.war
RUN chmod 777 /opt/cms/tomcat/webapps/repository.war

VOLUME /opt/cms/tomcat/webapps
EXPOSE 8080
CMD ["/opt/cms/tomcat/bin/catalina.sh", "run"]
#
