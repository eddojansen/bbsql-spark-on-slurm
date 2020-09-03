##setenv.sh##
export SPARK_HOME=/quobyte/config/spark/spark-3.0.0-bin-hadoop3.2
export PATH=$PATH:$SPARK_HOME/sbin:$SPARK_HOME/bin
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
module load JAVA/1.8.0_265 spark

export SPARK_CONF_DIR=~/SparkConf
mkdir -p $SPARK_CONF_DIR

env=$SPARK_CONF_DIR/spark-env.sh
echo "export SPARK_LOG_DIR=~/SparkLog" > $env
echo "export SPARK_WORKER_DIR=~/SparkWorker" >> $env
echo "export SLURM_MEM_PER_CPU=$SLURM_MEM_PER_CPU" >> $env
echo 'export SPARK_WORKER_CORES=`nproc`' >> $env
echo 'export SPARK_WORKER_MEMORY=$(( $SPARK_WORKER_CORES*$SLURM_MEM_PER_CPU ))M' >> $env

echo "export SPARK_HOME=$SPARK_HOME" > ~/.bashrc
echo "export JAVA_HOME=$JAVA_HOME" >> ~/.bashrc
echo "export SPARK_CONF_DIR=$SPARK_CONF_DIR" >> ~/.bashrc

scontrol show hostname $SLURM_JOB_NODELIST > $SPARK_CONF_DIR/slaves

conf=$SPARK_CONF_DIR/spark-defaults.conf
echo "spark.default.parallelism" $(( $SLURM_CPUS_PER_TASK * $SLURM_NTASKS ))> $conf
echo "spark.submit.deployMode" client >> $conf
echo "spark.master" spark://`hostname`:7077 >> $conf
echo "spark.executor.cores" $SLURM_CPUS_PER_TASK >> $conf
echo "spark.executor.memory" $(( $SLURM_CPUS_PER_TASK*$SLURM_MEM_PER_CPU ))M >> $conf

#bbsql
#export echo "SPARK_RAPIDS_DIR=/quobyte/config/sparkRapidsPlugin" >> $env
#export echo "SPARK_CUDF_JAR=${SPARK_RAPIDS_DIR}/cudf-0.14-cuda10-1.jari" >> $env
#export echo "SPARK_RAPIDS_PLUGIN_JAR=${SPARK_RAPIDS_DIR}/rapids-4-spark_2.12-0.1.0.jar" >> $env
JARS=/quobyte/config/spark/rapids-4-spark-integration-tests_2.12-0.1-SNAPSHOT.jar


# This is the IP address of the master node for your spark cluster
#MASTER="spark://172.16.78.111:7077"
MASTER="spark://`hostname`:7077"


HISTORYPARAMS="--conf spark.eventLog.enabled=true \
        --conf spark.eventLog.dir=file:/opt/spark/history"

S3PARAMS="--conf spark.hadoop.fs.s3a.access.key=$S3A_CREDS_USR \
        --conf spark.hadoop.fs.s3a.secret.key=$S3A_CREDS_PSW \
        --conf spark.hadoop.fs.s3a.impl=org.apache.hadoop.fs.s3a.S3AFileSystem \
        --conf spark.hadoop.fs.s3a.endpoint=$S3_ENDPOINT \
        --conf spark.hadoop.fs.s3a.path.style.access=true \
        --conf spark.hadoop.fs.s3a.experimental.input.fadvise=sequential \
        --conf spark.hadoop.fs.s3a.connection.maximum=1000\
        --conf spark.hadoop.fs.s3a.threads.core=1000\
        --conf spark.hadoop.parquet.enable.summary-metadata=false \
        --conf spark.sql.parquet.mergeSchema=false \
        --conf spark.sql.parquet.filterPushdown=true \
        --conf spark.sql.hive.metastorePartitionPruning=true \
        --conf spark.hadoop.fs.s3a.connection.ssl.enabled=true"

CMDPARAMS="--master $MASTER \
        --deploy-mode client \
        --jars $JARS \
        --num-executors ${NUM_EXECUTORS} \
        --conf spark.cores.max=$TOTAL_CORES \
        --conf spark.sql.warehouse.dir=$WAREHOUSE_PATH \
        --conf spark.task.cpus=1 \
        --driver-memory ${DRIVER_MEMORY}G \
        --executor-memory ${EXECUTOR_MEMORY}G \
        --executor-cores $NUM_EXECUTOR_CORES \
        --conf spark.sql.files.maxPartitionBytes=$PARTITIONBYTES \
        --conf spark.sql.autoBroadcastJoinThreshold=$BROADCASTTHRESHOLD \
        --conf spark.sql.shuffle.partitions=$PARTITIONS \
        --conf spark.locality.wait=0s \
        --conf spark.executor.heartbeatInterval=100s \
        --conf spark.network.timeout=3600s \
        --conf spark.storage.blockManagerSlaveTimeoutMs=3600s \
        --conf spark.sql.broadcastTimeout=2000 \
        --conf spark.executor.extraClassPath=${SPARK_CUDF_JAR}:${SPARK_RAPIDS_PLUGIN_JAR} \
        --conf spark.driver.extraClassPath=${SPARK_CUDF_JAR}:${SPARK_RAPIDS_PLUGIN_JAR} \
        $S3PARAMS"
