# Generic Hippo Docker image
FROM ubuntu:latest
MAINTAINER Flaviu Tusa ftusa@shift7digital.com

# Set environment variables
ENV PATH /srv/hippo/bin:$PATH
ENV HIPPO_FILE cms-upgrade_beaconhippo-14.5.0.1-SNAPSHOT-distribution.tar.gz
ENV HIPPO_FOLDER cms-upgrade_beaconhippo-14.5.0.1-SNAPSHOT-distribution
ENV HIPPO_URL https://storage.googleapis.com/sandbox-bucket-test/cms-upgrade_beaconhippo-14.5.0.1-SNAPSHOT-distribution.tar.gz

RUN apt-get update -y 

# Install packages required to install Hippo CMS
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y java-1.8.0-openjdk-devel
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y curl
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y dos2unix
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y unzip
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y wget 
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y git 
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y maven

# Install Hippo CMS, retrieving the GoGreen demonstration from the $HIPPO_URL and putting it under $HIPPO_FOLDER
RUN curl -L $HIPPO_URL -o $HIPPO_FILE
RUN tar -xvf ENV HIPPO_FILE
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