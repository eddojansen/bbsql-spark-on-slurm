# Set this to the location of your Spark installation
export SPARK_HOME=/opt/spark/
export PATH=$PATH:$SPARK_HOME/sbin:$SPARK_HOME/bin

# Set this to the directory that you copied the cudf and rapids jar files
export SPARK_RAPIDS_DIR=/opt/sparkRapidsPlugin
#
# Make sure that the following two environment variables have the correct
# name of the jars that you downloaded when setting up your spark
# environment. These jar files need to match the version of CUDA that you
# installed. For version 10.1 the following jars are correct:
#  
export SPARK_CUDF_JAR=${SPARK_RAPIDS_DIR}/cudf-0.14-cuda10-1.jar 
export SPARK_RAPIDS_PLUGIN_JAR=${SPARK_RAPIDS_DIR}/rapids-4-spark_2.12-0.1.0.jar

# If you are going to use storage that supports S3, set your credential
# here for use during the run
# NOTE: You will need to download additonal jar files and place them in
# $SPARK_HOME/jars. The following link has instructions
# https://github.com/NVIDIA/spark-xgboost-examples/blob/spark-3/getting-started-guides/csp/aws/ec2.md#step-3-download-jars-for-s3a-optional
#
# export S3A_CREDS_USR=s3username
# export S3A_CREDS_PSW=s3password
# S3_ENDPOINT="url.to.your.storage.com" 

# This points to the jar file that is in your current directory
JARS=rapids-4-spark-integration-tests_2.12-0.1-SNAPSHOT.jar

# These paths need to be set based on what storage mediume you are using
#
# For local disk use file:/// - Note that every node in your cluster must have 
# a copy of the local data on it. You can use shared storage as well, but the
# path must be consistent on all nodes
#
# For S3 storageuse s3a://
#
# Input path designates where the data to be processed is located
# INPUT_PATH="s3a://path_to_data/data/parquet"
INPUT_PATH="file:///path_to_data/data/parquet"
#
# Output path is where results from the queries are stored
# OUTPUT_PATH="s3a://path_to_output/output"
# OUTPUT_PATH="file:///path_to_output/output"
#
# Warehouse path is where temporary data is written during queries
# WAREHOUSE_PATH="s3a://path_to_warehouse/warehouse"
# WAREHOUSE_PATH="file:///path_to_warehouse/warehouse"

# This is the IP address of the master node for your spark cluster
MASTER="spark://172.16.78.111:7077"


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
