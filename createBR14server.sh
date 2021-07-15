#!/bin/bash
#  This is an environment setup script for the Bloomreach application with Tomcat Application server.
#
#  Assumptions prior to running the script
#  Java and Maven must be preinstalled
#  Apache-Tomcat must be downloaded to /usr/local
#  Once the script ends, if using systemd , issue command sudo systemctl enable cms
#  if using CentOS without systemd, issue command chkcommand --add cms
#  if using Debian/Ubuntu issue command update-rc.d cms defaults


####################################################################################################
#  Variable area
####################################################################################################


DBUSER=newhippouser
DBPASS=mypassword
JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
MAVEN_PLUGIN=org.apache.maven.plugins:maven-archetype-plugin:2.4
ARCHETYPE_REPOSITORY=https://maven.onehippo.com/maven2
ARCHETYPE_GROUPID=org.onehippo.cms7
ARCHETYPE_ARTIFACTID=hippo-project-archetype
ARCHETYPE_VERSION=14.4.0


###################################################################################################
#
# create cms user and home directory
#
###################################################################################################
useradd -m -d /opt/cms cms


###################################################################################################
#
#  untar apache-tomcat and change permissions on Files and Folders
###################################################################################################
cd /usr/local
wget https://downloads.apache.org/tomcat/tomcat-8/v8.5.65/bin/apache-tomcat-8.5.65.tar.gz
tar -xzvf apache-tomcat-8.5.65.tar.gz

ln -s apache-tomcat-8.5.65  tomcat

find /usr/local/tomcat/ -type d -print0 | xargs -0 chmod 755
find /usr/local/tomcat/ -type f -print0 | xargs -0 chmod 644
find /usr/local/tomcat/ -type f -name \*\.sh -print0 | xargs -0 chmod 755
mkdir -p /usr/local/share/tomcat-common/lib
cd /usr/local/share/tomcat-common/lib
wget http://search.maven.org/remotecontent?filepath=org/apache/geronimo/specs/geronimo-jta_1.1_spec/1.1.1/geronimo-jta_1.1_spec-1.1.1.jar -O geronimo-jta_1.1_spec-1.1.1.jar
wget http://search.maven.org/remotecontent?filepath=javax/mail/mail/1.4.7/mail-1.4.7.jar -O mail-1.4.7.jar
wget http://search.maven.org/remotecontent?filepath=javax/jcr/jcr/2.0/jcr-2.0.jar -O jcr-2.0.jar
wget http://search.maven.org/remotecontent?filepath=mysql/mysql-connector-java/8.0.19/mysql-connector-java-8.0.19.jar -O mysql-connector-java-8.0.19.jar





###################################################################################################
#
#  copy tomcat base files into /opt/cms , change log location, and add CATALINA_BASE location to catalina.sh
#
###################################################################################################

cd /opt/cms
mkdir -p tomcat/bin tomcat/conf tomcat/logs tomcat/shared/lib heapdumps tomcat/temp tomcat/webapps tomcat/work
ln -sf /usr/local/tomcat/bin/startup.sh tomcat/bin/startup.sh
ln -sf /usr/local/tomcat/bin/shutdown.sh tomcat/bin/shutdown.sh
cd /usr/local/tomcat/conf
cp catalina.policy catalina.properties server.xml web.xml tomcat-users.xml /opt/cms/tomcat/conf
rm -r /usr/local/tomcat/logs
ln -s /opt/cms/tomcat/logs /usr/local/tomcat/logs
sed -i '125s:^:CATALINA_BASE=/opt/cms/tomcat:' /usr/local/tomcat/bin/catalina.sh

cd /opt/cms/tomcat/conf

###################################################################################################
#
# update catalina.policy with permission to port 1099
#
###################################################################################################

echo 'grant codeBase "jar:file:${catalina.home}/webapps/" {
  permission java.net.SocketPermission "*:1099", "connect, accept, listen";
};' >> /opt/cms/tomcat/conf/catalina.policy

###################################################################################################
#
# add shared loader and common loader entries into catalina.properties
#
###################################################################################################

sed -i 's:shared.loader=:shared.loader="${catalina.base}/shared/lib","${catalina.base}/shared/lib/*.jar":' catalina.properties

sed -i 's:common.loader="${catalina.base}/lib","${catalina.base}/lib/\*\.jar","${catalina.home}/lib","${catalina.home}/lib/\*\.jar":common.loader="${catalina.base}/lib","${catalina.base}/lib/*.jar","${catalina.home}/lib","${catalina.home}/lib/*.jar","/usr/local/share/tomcat-common/lib","/usr/local/share/tomcat-common/lib/*.jar":' catalina.properties

###################################################################################################
#
#  create setenv.sh , replace JAVA_HOME with JAVA_HOME variable set in variables area
#
###################################################################################################
echo '
JAVA_HOME=/usr/java/jre1.8.0

CATALINA_HOME="/usr/local/tomcat"
CATALINA_BASE="/opt/cms/tomcat"
CATALINA_PID="${CATALINA_BASE}/work/catalina.pid"

CLUSTER_ID="$(whoami)-$(hostname -f)"

MAX_HEAP=512
MIN_HEAP=256

REP_OPTS="-Drepo.bootstrap=false -Drepo.config=file:${CATALINA_BASE}/conf/repository.xml"
JVM_OPTS="-server -Xmx${MAX_HEAP}m -Xms${MIN_HEAP}m -XX:+UseG1GC -Djava.util.Arrays.useLegacyMergeSort=true"
DMP_OPTS="-XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/opt/cms/heapdumps"
RMI_OPTS="-Djava.rmi.server.hostname=127.0.0.1"
JRC_OPTS="-Dorg.apache.jackrabbit.core.cluster.node_id=${CLUSTER_ID}"
L4J_OPTS="-Dlog4j.configurationFile=file://${CATALINA_BASE}/conf/log4j2.xml -DLog4jContextSelector=org.apache.logging.log4j.core.selector.BasicContextSelector"
VGC_OPTS="-verbosegc -XX:+PrintGCDetails -XX:+PrintGCDateStamps -Xloggc:${CATALINA_BASE}/logs/gc.log -XX:+UseGCLogFileRotation -XX:NumberOfGCLogFiles=5 -XX:GCLogFileSize=2048k"

CATALINA_OPTS="${JVM_OPTS} ${VGC_OPTS} ${REP_OPTS} ${DMP_OPTS} ${RMI_OPTS} ${L4J_OPTS} ${JRC_OPTS}"

export JAVA_HOME CATALINA_HOME CATALINA_BASE ' > /opt/cms/tomcat/bin/setenv.sh

sed -i "s:JAVA_HOME=/usr/java/jre1.8.0:JAVA_HOME=$JAVA_HOME:" /opt/cms/tomcat/bin/setenv.sh

chmod +x /opt/cms/tomcat/bin/setenv.sh

###################################################################################################
#
#   add log4j2.xml
#
###################################################################################################

cd /opt/cms/tomcat/conf
wget https://documentation.bloomreach.com/binaries/content/assets/connect/library/enterprise/jee-application-server-support/13.2/log4j2-dist.xml

mv log4j2-dist.xml log4j2.xml

##################################################################################################
#
#  create startup script for cms
#
##################################################################################################

echo '
#!/bin/bash
### BEGIN INIT INFO
# Provides:          tomcat
# Required-Start:    $remote_fs $syslog
# Required-Stop:     $remote_fs $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Start Tomcat at boot time
# Description:       Start Tomcat instance located at the user with the same name
#                    as the script. Tomcat is started with the privileges of the user.
### END INIT INFO

#
# Copyright BloomReach 2017
#

# Get basename and clean up start/stop symlink cruft (aka S20cms)
appname=$(basename $0)
appname=${appname##[KS][0-9][0-9]}
appuser=${appname}
apphome=/opt/${appuser}/tomcat

config=${apphome}/bin/setenv.sh
start_tomcat=${apphome}/bin/startup.sh
stop_tomcat=${apphome}/bin/shutdown.sh

CATALINA_PID="${apphome}/work/catalina.pid"

if [[ -r ${config} ]]; then
   . ${config}
else
   echo "Environment config missing: ${config}"
   exit 1
fi

if [[ -n "${JAVA_HOME+x}" && -z ${JAVA_HOME} ]]; then
  echo "Please point JAVA_HOME in $(basename) to your SUN JRE of JDK"
  exit 1
fi

export JAVA_HOME CATALINA_OPTS CATALINA_PID CATALINA_HOME CATALINA_BASE

if [[ $(id -u) == 0 ]]; then
  SU="su - ${appuser} -c"
elif [[ ${appuser} != $(/usr/bin/id -un) ]]; then
  echo "Access denied: You are neither a superuser nor the ${appuser} user"
  exit 1
fi

test -r ${CATALINA_PID} && PID=$(cat ${CATALINA_PID})

cleanup() {
  /usr/bin/find ${apphome}/work/ ${apphome}/temp/ -maxdepth 1 -mindepth 1 -print0 | xargs -0 rm -rf
}

start() {
  echo -n "Starting ${appname}: "
  cd ${apphome}
  if [[ -n ${PID} ]]; then
    if ps -eo pid | grep -wq ${PID}; then
      echo "${appname} (${PID}) still running.."
      exit 1
    else
      echo "(removed stale pid file ${CATALINA_PID}) "
      rm -f ${CATALINA_PID}
    fi
  fi
  cleanup
  ${SU} ${start_tomcat} > /dev/null
  if [[ $? ]]; then
    echo "${appname} started."
  else
    echo "${appname} failed to start."
  fi
}

stop() {
  echo -n "Shutting down ${appname}: "
  cd ${apphome}
  ${SU} ${stop_tomcat} > /dev/null
  if [[ -n ${PID} ]]; then
    echo "waiting for ${appname} to stop"
    for ((i=0;i<25;i++)); do
      RUNNING=$(ps -eo pid | grep -w ${PID})
      if [[ ${i} == 24 ]]; then
        kill ${PID} > /dev/null 2>&1 && sleep 5s && \
         kill -3 ${PID} > /dev/null 2>&1 && \
         kill -9 ${PID} > /dev/null 2>&1
      elif [[ ${RUNNING// /} == ${PID} ]]; then
        echo -n "."
        sleep 1s
      else
        break
      fi
    done
  fi
  test -e ${CATALINA_PID} && rm -f ${CATALINA_PID}
  echo "${appname} stopped."
}

case "${1}" in
  start)
    start
    ;;
  stop)
    stop
    ;;
  restart)
    if [[ -n ${PID} ]] && ps -eo pid | grep -wq ${PID}; then
      kill -3 ${PID}
    fi
    stop
    sleep 2s
    start
    ;;
  *)
    echo "Usage: ${0} {start|stop|restart}"
    ;;
esac

exit 0
' > /etc/init.d/cms

chmod +x /etc/init.d/cms

###################################################################################################
#
# create context.xml and replace DBUSER and DBPASS with variables 
#
###################################################################################################

echo '<?xml version='1.0' encoding='utf-8'?>
<Context>
    <!-- Disable session persistence across Tomcat restarts -->
    <Manager pathname="" />

    <Parameter name="repository-address" value="rmi://127.0.0.1:1099/hipporepository" override="false"/>
    <Parameter name="repository-directory" value="${catalina.base}/../repository" override="false"/>
    <Parameter name="start-remote-server" value="false" override="false"/>

    <Parameter name="check-username" value="liveuser" override="false"/>

    <Resource name="mail/Session" auth="Container"
        type="javax.mail.Session" mail.smtp.host="localhost"/>

    <!-- JNDI resource exposing database connection goes here -->

        <Resource
                name="jdbc/repositoryDS" auth="Container" type="javax.sql.DataSource"
                maxTotal="20" maxIdle="10" initialSize="2" maxWaitMillis="10000"
                testWhileIdle="true" testOnBorrow="false" validationQuery="SELECT 1"
                timeBetweenEvictionRunsMillis="10000"
                minEvictableIdleTimeMillis="60000"
                username="DBUSER" password="DBPASS"
                driverClassName="com.mysql.cj.jdbc.Driver"
                url="jdbc:mysql://localhost:3306/mytest?characterEncoding=utf8"/>

</Context> ' > /opt/cms/tomcat/conf/context.xml

sed -i "s:version=1.0:version='1.0':"  /opt/cms/tomcat/conf/context.xml
sed -i "s:utf-8:'utf-8':" /opt/cms/tomcat/conf/context.xml

sed -i "s:DBUSER:$DBUSER:" /opt/cms/tomcat/conf/context.xml
sed -i "s:DBPASS:$DBPASS:" /opt/cms/tomcat/conf/context.xml


###################################################################################################
#
# create repository.xml, and populate it with userid and creds for local database
#
###################################################################################################

echo '
<?xml version="1.0" encoding="UTF-8"?>

<!DOCTYPE Repository
          PUBLIC "-//The Apache Software Foundation//DTD Jackrabbit 2.6//EN"
          "http://jackrabbit.apache.org/dtd/repository-2.6.dtd">

<Repository>

  <DataSources>
      <DataSource name="ds1">
      <param name="driver" value="com.mysql.cj.jdbc.Driver"/>
      <param name="url" value="jdbc:mysql://localhost:3306/mytest"/>
      <param name="user" value="DBUSER"/>
      <param name="password" value="DBPASS"/>
      <param name="databaseType" value="mysql"/>
      <param name="validationQuery" value="select 1"/>
      <param name="maxPoolSize" value="10"/>
    </DataSource></DataSources>

  <FileSystem class="org.apache.jackrabbit.core.fs.db.DbFileSystem">
    <param name="dataSourceName" value="ds1"/>
    <param name="schemaObjectPrefix" value="repository_"/>
  </FileSystem>

  <Security appName="Jackrabbit">
    <SecurityManager class="org.apache.jackrabbit.core.security.simple.SimpleSecurityManager"/>
    <AccessManager class="org.apache.jackrabbit.core.security.simple.SimpleAccessManager"/>
    <LoginModule class="org.apache.jackrabbit.core.security.simple.SimpleLoginModule"/>
  </Security>

 <DataStore class="org.apache.jackrabbit.core.data.db.DbDataStore">
    <param name="dataSourceName" value="ds1"/>
    <param name="minRecordLength" value="1024" />
    <param name="copyWhenReading" value="true" />
    <param name="tablePrefix" value="" />
    <param name="schemaObjectPrefix" value="" />
  </DataStore>

  <Workspaces rootPath="${rep.home}/workspaces" defaultWorkspace="default" maxIdleTime="2"/>

  <Workspace name="${wsp.name}">

    <FileSystem class="org.apache.jackrabbit.core.fs.db.DbFileSystem">
      <param name="dataSourceName" value="ds1"/>
      <param name="schemaObjectPrefix" value="${wsp.name}_"/>
    </FileSystem>

    <PersistenceManager class="org.apache.jackrabbit.core.persistence.pool.MySqlPersistenceManager">
      <param name="dataSourceName" value="ds1"/>
      <param name="schemaObjectPrefix" value="${wsp.name}_" />
    </PersistenceManager>

    <SearchIndex class="org.hippoecm.repository.FacetedNavigationEngineImpl">
      <param name="indexingConfiguration" value="indexing_configuration.xml"/>
      <param name="indexingConfigurationClass" value="org.hippoecm.repository.query.lucene.ServicingIndexingConfigurationImpl"/>
      <param name="path" value="${wsp.home}/index"/>
      <param name="useSimpleFSDirectory" value="true"/>
      <param name="useCompoundFile" value="true"/>
      <param name="minMergeDocs" value="100"/>
      <param name="volatileIdleTime" value="10"/>
      <param name="maxMergeDocs" value="100000"/>
      <param name="mergeFactor" value="5"/>
      <param name="maxFieldLength" value="10000"/>
      <param name="bufferSize" value="1000"/>
      <param name="cacheSize" value="1000"/>
      <param name="onWorkspaceInconsistency" value="log"/>
      <param name="forceConsistencyCheck" value="false"/>
      <param name="enableConsistencyCheck" value="false"/>
      <param name="autoRepair" value="true"/>
      <param name="analyzer" value="org.hippoecm.repository.query.lucene.StandardHippoAnalyzer"/>
      <param name="queryClass" value="org.apache.jackrabbit.core.query.QueryImpl"/>
      <param name="respectDocumentOrder" value="false"/>
      <param name="resultFetchSize" value="1000"/>
      <param name="extractorTimeout" value="100"/>
      <param name="extractorBackLogSize" value="100"/>
      <param name="excerptProviderClass" value="org.apache.jackrabbit.core.query.lucene.DefaultHTMLExcerpt"/>
      <param name="supportSimilarityOnStrings" value="true"/>
      <param name="supportSimilarityOnBinaries" value="false"/>
    </SearchIndex>

    <ISMLocking class="org.apache.jackrabbit.core.state.FineGrainedISMLocking"/>
  </Workspace>

  <Versioning rootPath="${rep.home}/version">
    <FileSystem class="org.apache.jackrabbit.core.fs.db.DbFileSystem">
      <param name="dataSourceName" value="ds1"/>
      <param name="schemaObjectPrefix" value="version_"/>
    </FileSystem>

    <PersistenceManager class="org.apache.jackrabbit.core.persistence.pool.MySqlPersistenceManager">
      <param name="dataSourceName" value="ds1"/>
      <param name="schemaObjectPrefix" value="version_"/>
      <param name="externalBLOBs" value="true"/>
      <param name="consistencyCheck" value="false"/>
      <param name="consistencyFix" value="false"/>
      <param name="bundleCacheSize" value="64"/>
    </PersistenceManager>

    <ISMLocking class="org.apache.jackrabbit.core.state.FineGrainedISMLocking"/>
  </Versioning>

    <Cluster>
    <Journal class="org.apache.jackrabbit.core.journal.CleanOnCloseDatabaseJournal">
      <param name="dataSourceName" value="ds1"/>
      <param name="schemaObjectPrefix" value="repository_"/>
    </Journal>
  </Cluster>

</Repository> ' > /opt/cms/tomcat/conf/repository.xml

sed -i "s:user:$DBUSER:" /opt/cms/tomcat/conf/repository.xml
sed -i "s:password:$DBPASS:" /opt/cms/tomcat/conf/repository.xml

###################################################################################################
#
#  Recursively change ownership to cms user for /opt/cms directory
#
###################################################################################################
cd /opt/cms/
chown -R cms:cms *

###################################################################################################
#
# Build out the application, using Maven variables that were set in variable area at the top
#
###################################################################################################


cd /opt/cms/tomcat/webapps

sudo -u cms mvn $MAVEN_PLUGIN:generate \
-DarchetypeRepository=$ARCHETYPE_REPOSITORY \
-DarchetypeGroupId=$ARCHETYPE_GROUPID \
-DarchetypeArtifactId=$ARCHETYPE_ARTIFACTID \
-DarchetypeVersion=$ARCHETYPE_VERSION



cd myproject
sudo -u cms mvn clean verify

###################################################################################################
#
# Adjust yaml files so that cms.example.com channel manager shows Myproject 
#
###################################################################################################
sudo -u cms mkdir -p /opt/cms/tomcat/webapps/myproject/repository-data/site/src/main/resources/hcm-config/hst/hosts/
sudo -u cms mkdir -p /opt/cms/tomcat/webapps/myproject/repository-data/site/src/main/resources/hcm-config/hst/hosts/example/

sudo -u cms mkdir -p /opt/cms/tomcat/webapps/myproject/repository-data/application/src/main/resources/hcm-config/hst/hosts/
sudo -u cms mkdir -p /opt/cms/tomcat/webapps/myproject/repository-data/application/src/main/resources/hcm-config/hst/hosts/example/


echo "definitions:
  config:
    /hst:platform/hst:hosts/example:
      jcr:primaryType: hst:virtualhostgroup" > /opt/cms/tomcat/webapps/myproject/repository-data/application/src/main/resources/hcm-config/hst/hosts/example.yaml


echo "definitions:
  config:
    /hst:platform/hst:hosts/example/com:
      jcr:primaryType: hst:virtualhost
      hst:showcontextpath: true
      hst:showport: false
      /example:
        jcr:primaryType: hst:virtualhost
        /cms:
          jcr:primaryType: hst:virtualhost
          /hst:root:
            jcr:primaryType: hst:mount
            hst:ismapped: false
            hst:namedpipeline: WebApplicationInvokingPipeline
            hst:homepage: root" > /opt/cms/tomcat/webapps/myproject/repository-data/application/src/main/resources/hcm-config/hst/hosts/example/com.yaml


###################################################################################################
#
#  Add Host configurations  for com.example.cms and configure CORS
#
###################################################################################################

echo "definitions:
  config:
    /hst:hst/hst:hosts/dev-localhost:
      .meta:residual-child-node-category: content
      jcr:primaryType: hst:virtualhostgroup
      hst:defaultport: 8080
      /localhost:
        .meta:residual-child-node-category: content
        jcr:primaryType: hst:virtualhost
        hst:allowedorigins: ['http://localhost', 'http://cms.example.com']
        /hst:root:
          .meta:residual-child-node-category: content
          jcr:primaryType: hst:mount
          hst:homepage: root
          hst:mountpoint: /hst:myproject/hst:sites/myproject
          hst:pagemodelapi: resourceapi
          hst:responseheaders: ['Access-Control-Allow-Origin: cms.example.com:4000']
          /api:
            .meta:residual-child-node-category: content
            jcr:primaryType: hst:mount
            hst:alias: api
            hst:ismapped: false
            hst:namedpipeline: RestApiPipeline
            hst:types: [rest]" > /opt/cms/tomcat/webapps/myproject/repository-data/site/src/main/resources/hcm-config/hst/hosts.yaml


echo "definitions:
  config:
    /hst:hst/hst:hosts/example:
      .meta:residual-child-node-category: content
      jcr:primaryType: hst:virtualhostgroup" > /opt/cms/tomcat/webapps/myproject/repository-data/site/src/main/resources/hcm-config/hst/hosts/example.yaml



echo "definitions:
  config:
    /hst:hst/hst:hosts/example/com:
      .meta:residual-child-node-category: content
      jcr:primaryType: hst:virtualhost
      /example:
        .meta:residual-child-node-category: content
        jcr:primaryType: hst:virtualhost
        /cms:
          .meta:residual-child-node-category: content
          jcr:primaryType: hst:virtualhost
          hst:allowedorigins: ['http://cms.example.com:8080/site']
          /hst:root:
            .meta:residual-child-node-category: content
            jcr:primaryType: hst:mount
            hst:homepage: root
            hst:mountpoint: /hst:myproject/hst:sites/myproject
            hst:pagemodelapi: resourceapi
            hst:responseheaders: ['Access-Control-Allow-Origin: *', 'Access-Control-Allow-Credentials:
                true', 'Access-Control-Allow-Headers: content-type']
            hst:showcontextpath: false
            /api:
              .meta:residual-child-node-category: content
              jcr:primaryType: hst:mount
              hst:alias: api
              hst:ismapped: false
              hst:namedpipeline: RestApiPipeline
              hst:types: [rest]" > /opt/cms/tomcat/webapps/myproject/repository-data/site/src/main/resources/hcm-config/hst/hosts/example/com.yaml

chown cms:cms /opt/cms/tomcat/webapps/myproject/repository-data/site/src/main/resources/hcm-config/hst/hosts/example.yaml
chown cms:cms /opt/cms/tomcat/webapps/myproject/repository-data/site/src/main/resources/hcm-config/hst/hosts/example/com.yaml
chown cms:cms /opt/cms/tomcat/webapps/myproject/repository-data/application/src/main/resources/hcm-config/hst/hosts/example/com.yaml
chown cms:cms /opt/cms/tomcat/webapps/myproject/repository-data/application/src/main/resources/hcm-config/hst/hosts/example.yaml


###################################################################################################
#
# Configure SPA listener
#
#
###################################################################################################

echo "/hst:hst/hst:configurations/myproject/hst:workspace/hst:channel/hst:channelinfo:
  jcr:primaryType: hst:channelinfo
  org.hippoecm.hst.configuration.channel.PreviewURLChannelInfo_url: http://cms.example.com:4000" > /opt/cms/tomcat/webapps/myproject/repository-data/site/src/main/resources/hcm-content/hst/configurations/myproject/channelinfo.yaml

chown cms:cms /opt/cms/tomcat/webapps/myproject/repository-data/site/src/main/resources/hcm-content/hst/configurations/myproject/channelinfo.yaml

sudo -u cms mvn -Pcargo.run -Drepo.path=./storage

