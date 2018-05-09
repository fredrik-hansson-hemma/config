# Edit this file to set custom options
# Tomcat accepts two parameters JAVA_OPTS and CATALINA_OPTS
# JAVA_OPTS are used during START/STOP/RUN
# CATALINA_OPTS are used during START/RUN

JRE_HOME=/opt/sas/sashome/SASPrivateJavaRuntimeEnvironment/9.4/jre
JAVA_HOME=/opt/sas/sashome/SASPrivateJavaRuntimeEnvironment/9.4/jre
AGENT_PATHS=""
JAVA_AGENTS=""
JAVA_LIBRARY_PATH=""
JVM_OPTS="-Xmx12288m \
 -Xss256k \
 -Xms8192m \
 -XX:PermSize=1664m \
 -XX:MaxPermSize=1664m \
 -d64 \
 -XX:NewRatio=8 \
 -XX:+UseConcMarkSweepGC \
 -XX:+UseTLAB \
 -XX:+DisableExplicitGC \
 -XX:+CMSIncrementalMode \
 -XX:+CMSClassUnloadingEnabled \
 -XX:+UseCompressedOops \
 -XX:ReservedCodeCacheSize=96m \
 -Djava.awt.headless=true \
 -Dsun.rmi.dgc.client.gcInterval=3600000 \
 -Dsun.rmi.dgc.server.gcInterval=3600000 \
 -Duser.language=sv \
 -Duser.country=SE \
 -Dcom.sas.services.logging.disableRemoteList=true \
 -Dcom.sas.services.logging.disableRemoteLogging=true \
 -Dcom.sas.log.config.ignoreContextClassLoader=true \
 -Dwebreportstudio.file.cleanup.interval=60 \
 -Dspring.security.strategy=MODE_INHERITABLETHREADLOCAL \
 -Dcom.sas.log.config.url=file:////opt/sas/config/Lev1/Web/Common/LogConfig \
 -Dmulticast_udp_ip_ttl=1 \
 -Djava.net.preferIPv4Stack=false \
 -Djava.net.preferIPv6Addresses=false \
 -Dmulticast.address=239.168.122.1 \
 -Dmulticast.port=8561 \
 -Dsas.scs.svc.internal.url=https://rapport.lul.se \
 -Dsas.retry.internal.url=true \
 -Dsas.jms.authentication.decorator=false \
 -Dsas.scs.host=rapport.lul.se \
 -Dsas.scs.repository.dir=/opt/sas/config/Lev1/AppData/SASContentServer/Repository \
 -Dcom.sas.server.isclustered=true \
 -Dsas.scs.cas.host=rapport.lul.se \
 -Dsas.scs.cas.port=443 \
 -Dsas.scs.cas.scheme=https \
 -Dsas.scs.svc.host=rapport.lul.se \
 -Dsas.scs.svc.port=443 \
 -Dsas.scs.svc.scheme=https \
 -Dsas.scs.scheme=http \
 -Dsas.auto.publish.protocol=http \
 -Dsas.container.identifier=vfabrictcsvr \
 -Dsas.cache.locators=bs-ap-20.lul.se[41415] \
 -Dgemfire.conserve-sockets=false \
 -Dspring.profiles.active=locators \
 -Dsas.ttfontsvert.install.dir=/opt/sas/sashome/ReportFontsforClients/9.4 \
 -Dsas.bivaprint.install.dir=/opt/sas/sashome/SASVisualAnalyticsPrintingSupport/7.4 \
 -Dsas.scs.port=8080 \
 -Dnet.sf.ehcache.skipUpdateCheck=true \
 -Dorg.terracotta.quartz.skipUpdateCheck=true \
 -Dsas.auto.publish.host=bs-ap-20.lul.se \
 -Dsas.auto.publish.port=8080 \
 -Dsas.appserver.instance.id=SASServer1_1_bs-ap-20.lul.se \
 -Dconfig.lev.web.appserver.logs.dir=/opt/sas/config/Lev1/Web/Logs/SASServer1_1 \
 -Djava.security.auth.login.config=/opt/sas/config/Lev1/Web/WebAppServer/SASServer1_1/conf/jaas.config \
 -Dsas.metadata.use.cluster.properties=true \
 -Dsas.deploy.dir=/opt/sas/config/Lev1/Web/WebAppServer/SASServer1_1/sas_webapps \
 -Dorg.apache.activemq.SERIALIZABLE_PACKAGES=java.lang,java.util,java.net,java.sql,java.math,org.apache.activemq,org.fusesource.hawtbuf,org.springframework.remoting,org.springframework.security,com.thoughtworks.xstream.mapper,com.sas,org.apache.commons.logging,org.jasig.cas.client.validation,org.jasig.cas.client.authentication,org.jasig.cas.client.proxy \
 -Dsas.deployment.agent.client.config=/opt/sas/sashome/SASRemoteDeploymentAgentClient/2.1/config/deployagtclt.properties \
 -Dsas.app.repository.path=/opt/sas/sashome/SASVersionedJarRepository/eclipse \
 -Dsas.svcs.http.max.total.connections=512 \
 -Dsas.svcs.http.max.connections=512 \
 -Dsun.security.krb5.debug=true \
 -Djava.security.krb5.conf=/opt/sas/config/Lev1/Web/WebAppServer/SASServer1_1/conf/krb5.conf \
 -Dsas.internal.retry.url=true \
 -Dgemfire.conserve-sockets=false \
 -Dsas.retry.internal.url=true \
 -Dsas.web.html.cdps.use.internal.urls=true"
JAVA_OPTS="$JVM_OPTS $AGENT_PATHS $JAVA_AGENTS $JAVA_LIBRARY_PATH"
CLASSPATH="$CATALINA_BASE/lib/log4j.jar:$CATALINA_BASE/lib/sas.email.rmi.jar:$CATALINA_BASE/lib:$CATALINA_BASE/conf:$JRE_HOME/../lib/tools.jar"
CATALINA_OUT="$CATALINA_BASE/logs/catalina.out"
LOGGING_CONFIG="-Dnop"
