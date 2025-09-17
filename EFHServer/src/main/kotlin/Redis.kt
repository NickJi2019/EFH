package com.woznes
import org.redisson.Redisson
import org.redisson.api.*
import org.redisson.config.Config
import java.util.concurrent.TimeUnit

object Redis {
    val redisson: RedissonClient

    init {
        val config = Config()
        config.useSingleServer().address = "redis://127.0.0.1:6379"
        redisson = Redisson.create(config)
    }

    /** ------------------ String 类型 ------------------ */
    fun <T : Any> set(key: String, value: T, expireSeconds: Long? = null) {
        val bucket: RBucket<T> = redisson.getBucket(key)
        if (expireSeconds != null) {
            bucket.set(value, expireSeconds, TimeUnit.SECONDS)
        } else {
            bucket.set(value)
        }
    }

    fun <T : Any> get(key: String): T? {
        val bucket: RBucket<T> = redisson.getBucket(key)
        return bucket.get()
    }

    fun del(key: String): Boolean = redisson.getBucket<Any>(key).delete()

    /** ------------------ Hash 类型 ------------------ */
    fun <K : Any, V : Any> hset(mapName: String, key: K, value: V) {
        val map: RMap<K, V> = redisson.getMap(mapName)
        map[key] = value
    }

    fun <K : Any, V : Any> hget(mapName: String, key: K): V? {
        val map: RMap<K, V> = redisson.getMap(mapName)
        return map[key]
    }

    /** ------------------ List 类型 ------------------ */
    fun <T : Any> lpush(listName: String, value: T) {
        val list: RList<T> = redisson.getList(listName)
        list.add(0, value)
    }

    fun <T : Any> rpush(listName: String, value: T) {
        val list: RList<T> = redisson.getList(listName)
        list.add(value)
    }

    fun <T : Any> lpop(listName: String): T? {
        val list: RList<T> = redisson.getList(listName)
        return if (list.isEmpty()) null else list.removeAt(0)
    }

    /** ------------------ Set 类型 ------------------ */
    fun <T : Any> sadd(setName: String, value: T) {
        val set: RSet<T> = redisson.getSet(setName)
        set.add(value)
    }

    fun <T : Any> sismember(setName: String, value: T): Boolean {
        val set: RSet<T> = redisson.getSet(setName)
        return set.contains(value)
    }

    /** ------------------ ZSet 类型 ------------------ */
    fun <T : Any> zadd(zsetName: String, score: Double, value: T) {
        val zset: RScoredSortedSet<T> = redisson.getScoredSortedSet(zsetName)
        zset.add(score, value)
    }

    fun <T : Any> zrange(zsetName: String, start: Int, end: Int): Collection<T> {
        val zset: RScoredSortedSet<T> = redisson.getScoredSortedSet(zsetName)
        return zset.valueRange(start, end)
    }

    /** ------------------ Lock 类型 ------------------ */
    fun getLock(lockName: String): RLock = redisson.getLock(lockName)

    fun shutdown() {
        redisson.shutdown()
    }
}
