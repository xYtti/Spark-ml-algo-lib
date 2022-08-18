echo "====start===="
date

spark-submit \
--driver-java-options "-Dlog4j.configuration=file:./log4j.properties" \
--class com.huawei.bigdata.ml.spark.SimRankCheckResult \
--master yarn \
--deploy-mode client \
--driver-cores 36 \
--driver-memory 50g \
--num-executors 71 \
--executor-memory 12g \
--executor-cores 4 \
./sophon-ml-test_2.11-1.3.0.jar \
/tmp/wc_test/simrank/HibenchRating5wx5wuserSimHw \
/tmp/wc_test/simrank/HibenchRating5wx5witemSimHw \
/tmp/wc_test/simrank/HibenchRating5wx5wuserSimOpen \
/tmp/wc_test/simrank/HibenchRating5wx5witemSimOpen


echo "====end===="
date