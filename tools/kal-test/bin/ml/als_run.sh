#!/bin/bash
set -e

function usage() {
  echo "Usage: <data structure> <dataset name> <api name> <isRaw> <isCheck>"
  echo "1st argument: type of data structure: [dataframe/rdd]"
  echo "2nd argument: name of dataset: e.g. als/alsbs/alsh"
  echo "3rd argument: name of API: e.g. fit/fit1/fit2/fit3; for rdd: train"
  echo "4th argument: optimization algorithm or raw: [no/yes]"
  echo "5th argument: Whether to Compare Results [no/yes]"
}

case "$1" in
-h | --help | ?)
  usage
  exit 0
  ;;
esac

if [ $# -ne 5 ]; then
  usage
  exit 0
fi

source conf/ml/als/als_spark.properties
data_structure=$1
dataset_name=$2
api_name=$3
is_raw=$4
if_check=$5
cpu_name=$(lscpu | grep Architecture | awk '{print $2}')
model_conf=${data_structure}-${dataset_name}-${api_name}-${is_raw}-${if_check}

# concatnate strings as a new variable
num_executors="numExectuors_"${cpu_name}
executor_cores="executorCores_"${cpu_name}
executor_memory="executorMemory_"${cpu_name}
driver_cores="driverCores_"${cpu_name}
driver_memory="driverMemory_"${cpu_name}
master_="master"
deploy_mode="deployMode"

num_executors_val=${!num_executors}
executor_cores_val=${!executor_cores}
executor_memory_val=${!executor_memory}
driver_cores_val=${!driver_cores}
driver_memory_val=${!driver_memory}
master_val=${!master_}
deploy_mode_val=${!deploy_mode}


echo "${master_} : ${master_val}"
echo "${deploy_mode} : ${deploy_mode_val}"
echo "${driver_cores} : ${driver_cores_val}"
echo "${driver_memory} : ${driver_memory_val}"
echo "${num_executors} : ${num_executors_val}"
echo "${executor_cores}: ${executor_cores_val}"
echo "${executor_memory} : ${executor_memory_val}"
echo "cpu_name : ${cpu_name}"

if [ ! ${num_executors_val} ] \
    || [ ! ${executor_cores_val} ] \
    || [ ! ${executor_memory_val} ] \
    || [ ! ${driver_cores_val} ] \
    || [ ! ${driver_memory_val} ] \
    || [ ! ${master_val} ] \
    || [ ! ${cpu_name} ]; then
  echo "Some values are NULL, please confirm with the property files"
  exit 0
fi


source conf/ml/ml_datasets.properties
spark_version=sparkVersion
spark_version_val=${!spark_version}
kal_version=kalVersion
kal_version_val=${!kal_version}
scala_version=scalaVersion
scala_version_val=${!scala_version}
save_resultPath=saveResultPath
save_resultPath_val=${!save_resultPath}
data_path_val=${!dataset_name}
echo "${dataset_name} : ${data_path_val}"


spark_conf=${master_val}_${deploy_mode_val}_${num_executors_val}_${executor_cores_val}_${executor_memory_val}

mkdir -p log

echo "start to clean cache and sleep 30s"
ssh server1 "echo 3 > /proc/sys/vm/drop_caches"
ssh agent1 "echo 3 > /proc/sys/vm/drop_caches"
ssh agent2 "echo 3 > /proc/sys/vm/drop_caches"
ssh agent3 "echo 3 > /proc/sys/vm/drop_caches"
sleep 30

echo "start to submit spark jobs --- als-${model_conf}"
if [ ${is_raw} == "no" ]; then
  scp lib/fastutil-8.3.1.jar lib/boostkit-ml-acc_${scala_version_val}-${kal_version_val}-${spark_version_val}.jar lib/boostkit-ml-core_${scala_version_val}-${kal_version_val}-${spark_version_val}.jar lib/boostkit-ml-kernel-${scala_version_val}-${kal_version_val}-${spark_version_val}-${cpu_name}.jar root@agent1:/opt/ml_classpath/
  scp lib/fastutil-8.3.1.jar lib/boostkit-ml-acc_${scala_version_val}-${kal_version_val}-${spark_version_val}.jar lib/boostkit-ml-core_${scala_version_val}-${kal_version_val}-${spark_version_val}.jar lib/boostkit-ml-kernel-${scala_version_val}-${kal_version_val}-${spark_version_val}-${cpu_name}.jar root@agent2:/opt/ml_classpath/
  scp lib/fastutil-8.3.1.jar lib/boostkit-ml-acc_${scala_version_val}-${kal_version_val}-${spark_version_val}.jar lib/boostkit-ml-core_${scala_version_val}-${kal_version_val}-${spark_version_val}.jar lib/boostkit-ml-kernel-${scala_version_val}-${kal_version_val}-${spark_version_val}-${cpu_name}.jar root@agent3:/opt/ml_classpath/

  spark-submit \
  --class com.bigdata.ml.ALSRunner \
  --deploy-mode ${deploy_mode_val} \
  --driver-cores ${driver_cores_val} \
  --driver-memory ${driver_memory_val} \
  --driver-java-options "-Xms20g -Xss5g" \
  --num-executors ${num_executors_val} \
  --executor-cores ${executor_cores_val} \
  --executor-memory ${executor_memory_val} \
  --master ${master_val} \
  --conf "spark.executor.extraJavaOptions=-Xms20g -Xss5g" \
  --conf "spark.executor.instances=${num_executors_val}" \
  --conf "spark.driver.maxResultSize=256G" \
  --jars "lib/fastutil-8.3.1.jar,lib/boostkit-ml-acc_${scala_version_val}-${kal_version_val}-${spark_version_val}.jar,lib/boostkit-ml-core_${scala_version_val}-${kal_version_val}-${spark_version_val}.jar,lib/boostkit-ml-kernel-${scala_version_val}-${kal_version_val}-${spark_version_val}-${cpu_name}.jar" \
  --driver-class-path "lib/kal-test_${scala_version_val}-0.1.jar:lib/fastutil-8.3.1.jar:lib/snakeyaml-1.19.jar:lib/boostkit-ml-acc_${scala_version_val}-${kal_version_val}-${spark_version_val}.jar:lib/boostkit-ml-core_${scala_version_val}-${kal_version_val}-${spark_version_val}.jar:lib/boostkit-ml-kernel-${scala_version_val}-${kal_version_val}-${spark_version_val}-${cpu_name}.jar" \
  --conf "spark.executor.extraClassPath=/opt/ml_classpath/fastutil-8.3.1.jar:/opt/ml_classpath/boostkit-ml-acc_${scala_version_val}-${kal_version_val}-${spark_version_val}.jar:/opt/ml_classpath/boostkit-ml-core_${scala_version_val}-${kal_version_val}-${spark_version_val}.jar:/opt/ml_classpath/boostkit-ml-kernel-${scala_version_val}-${kal_version_val}-${spark_version_val}-${cpu_name}.jar" \
  ./lib/kal-test_${scala_version_val}-0.1.jar ${model_conf} ${data_path_val} ${cpu_name} ${spark_conf} ${save_resultPath_val} | tee ./log/log
else
  spark-submit \
  --driver-class-path "lib/snakeyaml-1.19.jar:lib/fastutil-8.3.1.jar" \
  --class com.bigdata.ml.ALSRunner \
  --driver-java-options "-Xms15g -Xss5g" \
  --deploy-mode ${deploy_mode_val} \
  --driver-cores ${driver_cores_val} \
  --driver-memory ${driver_memory_val} \
  --num-executors ${num_executors_val} \
  --executor-cores ${executor_cores_val} \
  --executor-memory ${executor_memory_val} \
  --master ${master_val} \
  --conf "spark.executor.extraJavaOptions=-Xms20g -Xss5g" \
  --conf "spark.executor.instances=${num_executors_val}" \
  --conf "spark.driver.maxResultSize=256G" \
  ./lib/kal-test_${scala_version_val}-0.1.jar ${model_conf} ${data_path_val} ${cpu_name}  ${spark_conf} ${save_resultPath_val} | tee ./log/log
fi