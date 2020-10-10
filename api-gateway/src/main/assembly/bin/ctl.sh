#!/bin/bash

#默认值512M
java_min_memory=512
java_max_memory=512

script=$0
cd `dirname $0`
BIN_DIR=`pwd`
cd ..
DEPLOY_DIR=`pwd`
CONFIG_DIR=${DEPLOY_DIR}/config
RUNTIME_DIR=${DEPLOY_DIR}/runtime

if [ ! -d ${RUNTIME_DIR} ]; then
    mkdir -p ${RUNTIME_DIR}
fi

LOGS_DIR=${DEPLOY_DIR}/logs

if [ ! -d ${LOGS_DIR} ]; then
    mkdir -p ${LOGS_DIR}
fi

app_name=`basename ${DEPLOY_DIR}`
pid_file=${RUNTIME_DIR}/${app_name}.pid
# dubbo_registry_file=${RUNTIME_DIR}/dubbo-registry-${app_name}.cache
cd ${DEPLOY_DIR}/lib

app_file=`ls *.jar 2>/dev/null | tail -1`
if [ -n "${app_file}" ]; then
    echo "find jar file ${app_file}"
else
    echo "no jar file found, begin to search war file!"
    app_file=`ls *.war 2>/dev/null | tail -1`
    if [ -n "${app_file}" ]; then
      echo "find war file ${app_file}"
    else
      echo "
      *************************
      no jar or war file found!
      *************************
      "
      exit 2
    fi
fi

JAVA_VERSION=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}')
# Enable coredump
ulimit -c unlimited

## Memory Options##
MEM_OPTS="-Xms${java_min_memory}m -Xmx${java_max_memory}m"
if [[ "$JAVA_VERSION" < "1.8" ]]; then
  MEM_OPTS="$MEM_OPTS -XX:PermSize=128m -XX:MaxPermSize=512m"
else
  #jdk8 的永久代可以用光服務器所有內存 设置最大最小值保护下
  MEM_OPTS="$MEM_OPTS -XX:MetaspaceSize=128m -XX:MaxMetaspaceSize=512m"
fi

# 启动时预申请内存
MEM_OPTS="$MEM_OPTS -XX:+AlwaysPreTouch"
#MEM_OPTS="${MEM_OPTS} -Ddubbo.registry.file=${dubbo_registry_file}"

## GC Options##
GC_OPTS="-XX:+UseConcMarkSweepGC -XX:CMSInitiatingOccupancyFraction=75 -XX:+UseCMSInitiatingOccupancyOnly"

# System.gc() 使用CMS算法
GC_OPTS="$GC_OPTS -XX:+ExplicitGCInvokesConcurrent"

# CMS中的下列阶段并发执行
GC_OPTS="$GC_OPTS -XX:+ParallelRefProcEnabled -XX:+CMSParallelInitialMarkEnabled"

# 根据应用的对象生命周期设定，减少事实上的老生代对象在新生代停留时间，加快YGC速度
GC_OPTS="$GC_OPTS -XX:MaxTenuringThreshold=3"

# 如果OldGen较大，加大YGC时扫描OldGen关联的卡片，加快YGC速度，默认值256较低
GC_OPTS="$GC_OPTS -XX:+UnlockDiagnosticVMOptions -XX:ParGCCardsPerStrideChunk=1024"

#打印GC日志，包括时间戳，晋升老生代失败原因，应用实际停顿时间(含GC及其他原因)
GCLOG_OPTS="-Xloggc:${LOGS_DIR}/gc.log -XX:+PrintGCDetails -XX:+PrintGCDateStamps -XX:+PrintPromotionFailure -XX:+PrintGCApplicationStoppedTime"

#打印GC原因，JDK8默认打开
if [[ "$JAVA_VERSION" < "1.8" ]]; then
	GCLOG_OPTS="$GCLOG_OPTS -XX:+PrintGCCause"
fi

## Optimization Options## 取消偏向鎖、加大Integer Cache 、GC策略，8G以下的堆CMS比較好
OPTIMIZE_OPTS="-XX:-UseBiasedLocking -XX:AutoBoxCacheMax=20000 -Djava.security.egd=file:/dev/./urandom"

## Other Options##
OTHER_OPTS="-Djava.net.preferIPv4Stack=true -Dfile.encoding=UTF-8"
## Trouble shooting Options##
SHOOTING_OPTS="-XX:+PrintCommandLineFlags -XX:-OmitStackTraceInFastThrow -XX:ErrorFile=${LOGS_DIR}/hs_err_%p.log"

JAVA_OPTS="$MEM_OPTS $GC_OPTS $GCLOG_OPTS $OPTIMIZE_OPTS $SHOOTING_OPTS $OTHER_OPTS"

JAVA_DEBUG_OPTS=""
if [ "$2" = "debug" ]; then
    JAVA_DEBUG_OPTS=" -Xdebug -Xnoagent -Djava.compiler=NONE -Xrunjdwp:transport=dt_socket,address=8000,server=y,suspend=n "
fi

JAVA_JMX_OPTS=""
if [ "$2" = "jmx" ]; then
    JAVA_JMX_OPTS=" -Dcom.sun.management.jmxremote.port=1099 -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.authenticate=false "
fi

if [ "$1" = "start" ]; then
  java_cmd="nohup java ${JAVA_OPTS} ${JAVA_DEBUG_OPTS} ${JAVA_JMX_OPTS} -jar ${DEPLOY_DIR}/lib/${app_file}  > ${DEPLOY_DIR}/logs/stdout.log 2>&1 &"
  echo ${java_cmd}
  eval ${java_cmd}
  echo $!>${pid_file}
  echo "started the ${app_name} application"
elif [ "$1" = "stop" ]; then
  kill `cat ${pid_file}`
  #kill -9 `cat ${pid_file}`
  kill_result=$?
  if [ "${kill_result}" != "0" ]; then
   echo "stop failed, focus kill"
   #kill -9 `cat ${pid_file}`
  fi
  $!>${pid_file}
  echo "killed ${app_name} application"
elif [ "$1" = "restart" ]; then
  $0 stop
  sleep 1
  $0 start
else
 echo "Usage: `basename "$0"` {start | stop | restart}"
fi

exit $?
