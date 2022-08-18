// scalastyle:off
package com.bigdata.compare.ml

import org.apache.hadoop.fs.{FileSystem, Path}
import org.apache.spark.sql.{DataFrame, SparkSession}
import org.apache.spark.{SparkConf, SparkContext}

object SimRankVerify {
  val EPS = 1e-7

  def main(args: Array[String]): Unit = {
    val userSimPathHw = args(0)
    val itemSimPathHw = args(1)
    val userSimPathOpen = args(2)
    val itemSimPathOpen = args(3)

    val conf = new SparkConf().setAppName("SimRankVerify")
    val spark = SparkSession.builder().config(conf).getOrCreate()

    val userSimHw = spark.read.option("header", value = true).option("inferSchema", value = true).csv(userSimPathHw)
    val itemSimHw = spark.read.option("header", value = true).option("inferSchema", value = true).csv(itemSimPathHw)
    val userSimOpen = spark.read.option("header", value = true).option("inferSchema", value = true).csv(userSimPathOpen)
    val itemSimOpen = spark.read.option("header", value = true).option("inferSchema", value = true).csv(itemSimPathOpen)

    val userSim = userSimHw.join(userSimOpen, Seq("user1", "user2"), "full")
    val itemSim = itemSimHw.join(itemSimOpen, Seq("item1", "item2"), "full")

    userSim.foreach(row => assert(math.abs(row.getDouble(2) - row.getDouble(3)) <= EPS))
    itemSim.foreach(row => assert(math.abs(row.getDouble(2) - row.getDouble(3)) <= EPS))

    println("result verified!")

    spark.stop()
  }

  def saveRes(res1: DataFrame, res2: DataFrame, savePath: String, sc: SparkContext): Unit = {
    val fs = FileSystem.get(sc.hadoopConfiguration)
    val saveFile = new Path(savePath)
    if (fs.exists(saveFile)) {
      fs.delete(saveFile, true)
    }
    res1.foreach(_ => {})
    res2.foreach(_ => {})
    res1.write.mode("overwrite").option("header", value = true).csv(savePath)
    res2.write.mode("overwrite").option("header", value = true).csv(savePath)
  }
}
