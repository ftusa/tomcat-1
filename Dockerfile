FROM tomcat:9-jdk8-openjdk-slim

LABEL PROJECT=myproject

# Default JVM heap size variables
ENV JAVA_MINHEAP 256m
ENV JAVA_MAXHEAP 512m

# Default tomcat http max threads variable
ENV TOMCAT_MAXTHREADS 200

# Default repository settings 
ENV REPO_PATH /brxm/project/target/storage
ENV REPO_CONFIG ""
ENV REPO_BOOTSTRAP false
ENV REPO_AUTOEXPORT_ALLOWED false
ENV REPO_WORKSPACE_BUNDLE_CACHE 256
ENV REPO_VERSIONING_BUNDLE_CACHE 64

# Default database profile
ENV profile h2

# Default mysql variables
ENV MYSQL_DB_HOST mysql
ENV MYSQL_DB_PORT 3306
ENV MYSQL_DB_USER admin
ENV MYSQL_DB_PASSWORD admin
ENV MYSQL_DB_NAME myproject
ENV MYSQL_DB_DRIVER com.mysql.cj.jdbc.Driver

# Default postgres variables
ENV POSTGRES_DB_HOST postgres
ENV POSTGRES_DB_PORT 5432
ENV POSTGRES_DB_USER admin
ENV POSTGRES_DB_PASSWORD admin
ENV POSTGRES_DB_NAME myproject
ENV POSTGRES_DB_DRIVER org.postgresql.Driver

# Provide LUCENE_INDEX_FILE_PATH to initialize the local lucene index with a stored copy

# Prepare dirs
# Delete default & unused war files
# Define a non-root user with limited permissions
# Non-root user should own tomcat & /brxm dirs
# Install unzip for the lucene index export
RUN mkdir -p \
        /brxm/bin \
        /usr/local/tomcat/common/classes \
        /usr/local/tomcat/shared/classes \
    && rm -rf \
        /usr/local/tomcat/webapps/docs \
        /usr/local/tomcat/webapps/examples \
        /usr/local/tomcat/webapps/host-manager \
        /usr/local/tomcat/webapps/manager \
        /usr/local/tomcat/webapps/ROOT \
    && addgroup --gid 1001 brxmuser \
    && adduser --gid 1001 --uid 1001 brxmuser \
    && chown -R brxmuser /usr/local/tomcat /brxm \
    && apt-get update && apt-get install -y unzip

USER brxmuser

# In maven/ the files as specified in the <assembly> section are stored and need to be added manually
# COPY in reverse order of expected change frequency, for optimal docker build caching
COPY --chown=1001:1001 maven/common /usr/local/tomcat/common/
COPY --chown=1001:1001 maven/db-drivers /brxm/db-drivers
COPY --chown=1001:1001 maven/scripts /brxm/bin
RUN chmod +x /brxm/bin/docker-entrypoint.sh

# Entrypoint script applies env-vars to config, then runs tomcat
ENTRYPOINT ["/brxm/bin/docker-entrypoint.sh"]

COPY --chown=1001:1001 maven/conf /usr/local/tomcat/conf/
COPY --chown=1001:1001 maven/shared /usr/local/tomcat/shared/
COPY --chown=1001:1001 maven/webapps /usr/local/tomcat/webapps/
