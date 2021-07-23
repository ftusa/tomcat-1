# Generic Hippo Docker image
FROM ubuntu:latest
MAINTAINER Flaviu Tusa ftusa@shift7digital.com

# Set environment variables
ENV PATH /srv/hippo/bin:$PATH
ENV HIPPO_FILE xm-spa-example-14.5.0-distribution.tar.gz
ENV HIPPO_FOLDER xm-spa-example-14.5.0-distribution
ENV HIPPO_URL https://storage.googleapis.com/sandbox-bucket-test/xm-spa-example-14.5.0-distribution.tar.gz

RUN apt-get update -y 

# Install packages required to install Hippo CMS
RUN apt-get install -y default-jre
RUN apt-get install -y curl
RUN apt-get install -y dos2unix
RUN apt-get install -y unzip
RUN apt-get install -y wget 
RUN apt-get install -y git 
RUN apt-get install -y maven

# Install Hippo CMS, retrieving the GoGreen demonstration from the $HIPPO_URL and putting it under $HIPPO_FOLDER
RUN curl -L $HIPPO_URL -o $HIPPO_FILE
RUN tar -xzvf ENV HIPPO_FILE
RUN mv /$HIPPO_FOLDER/tomcat/* /srv/hippo
RUN chmod 700 /srv/hippo/* -R

# Replace DOS line breaks on Apache Tomcat scripts, to properly load JAVA_OPTS
RUN dos2unix /srv/hippo/bin/setenv.sh
RUN dos2unix /srv/hippo/bin/catalina.sh

# Expose ports
EXPOSE 8080

# Start Hippo
WORKDIR /srv/hippo/
CMD ["catalina.sh", "run"]