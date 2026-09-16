package com.woznes

import java.net.URI
import java.net.URLEncoder
import java.net.http.HttpClient
import java.net.http.HttpRequest
import java.net.http.HttpResponse
import java.time.Duration
import java.util.stream.Collectors

object Status {

    const val DEFAULT_CONTROLLER = "http://127.0.0.1:9091"
    const val DEFAULT_TEST_URL = "http://www.gstatic.com/generate_204"

    // 节点名 -> 供浏览器直接探测的服务器域名
    private val nodeServers = linkedMapOf(
        "EFH Node1" to "node1.vpn.woznes.com",
        // Node2 与主域名是同一台服务器，直接探测主域名以复用其有效证书
        "EFH Node2" to "vpn.woznes.com",
        "EFH Node3" to "node3.vpn.woznes.com",
        "EFH Node4" to "node4.vpn.woznes.com"
    )

    val nodes: List<String> = nodeServers.keys.toList()

    fun serverOf(node: String): String? = nodeServers[node]

    data class NodeResult(
        val name: String,
        val address: String?,
        val delayMs: Int?,
        val message: String?
    ) {
        val reachable: Boolean get() = delayMs != null && delayMs > 0
    }

    private val client: HttpClient = HttpClient.newBuilder()
        .connectTimeout(Duration.ofSeconds(3))
        .build()

    private val delayRegex = Regex("\"delay\"\\s*:\\s*(-?\\d+)")
    private val messageRegex = Regex("\"message\"\\s*:\\s*\"([^\"]*)\"")

    fun controller(): String =
        System.getenv("MIHOMO_CONTROLLER")
            ?: System.getProperty("mihomo.controller")
            ?: DEFAULT_CONTROLLER

    fun testUrl(): String =
        System.getenv("MIHOMO_TEST_URL")
            ?: System.getProperty("mihomo.testUrl")
            ?: DEFAULT_TEST_URL

    fun delay(
        node: String,
        baseUrl: String = controller(),
        timeoutMs: Int = 5000,
        probeUrl: String = testUrl()
    ): NodeResult {
        val encodedNode = URLEncoder.encode(node, "UTF-8").replace("+", "%20")
        val encodedUrl = URLEncoder.encode(probeUrl, "UTF-8")
        val uri = URI.create("$baseUrl/proxies/$encodedNode/delay?timeout=$timeoutMs&url=$encodedUrl")
        val request = HttpRequest.newBuilder(uri)
            .timeout(Duration.ofMillis(timeoutMs + 3000L))
            .GET()
            .build()
        return try {
            val response = client.send(request, HttpResponse.BodyHandlers.ofString())
            parse(node, response.body())
        } catch (e: Exception) {
            NodeResult(node, serverOf(node), null, e.message ?: e.javaClass.simpleName)
        }
    }

    fun nodeDelays(
        baseUrl: String = controller(),
        timeoutMs: Int = 5000
    ): List<NodeResult> = nodes.parallelStream()
        .map { delay(it, baseUrl, timeoutMs) }
        .collect(Collectors.toList())

    fun pending(): List<NodeResult> = nodes.map { NodeResult(it, serverOf(it), null, null) }

    fun toJson(results: List<NodeResult>): String {
        val array = results.joinToString(",") { r ->
            val address = r.address?.let { "\"${escapeJson(it)}\"" } ?: "null"
            val delay = r.delayMs?.toString() ?: "null"
            val message = r.message?.let { "\"${escapeJson(it)}\"" } ?: "null"
            """{"name":"${escapeJson(r.name)}","address":$address,"delay":$delay,"reachable":${r.reachable},"message":$message}"""
        }
        return """{"updatedAt":${System.currentTimeMillis()},"nodes":[$array]}"""
    }

    private fun escapeJson(value: String): String = buildString {
        for (c in value) {
            when (c) {
                '\\' -> append("\\\\")
                '"' -> append("\\\"")
                '\n' -> append("\\n")
                '\r' -> append("\\r")
                '\t' -> append("\\t")
                else -> if (c < ' ') append("\\u%04x".format(c.code)) else append(c)
            }
        }
    }

    private fun parse(node: String, body: String): NodeResult {
        val delay = delayRegex.find(body)?.groupValues?.get(1)?.toIntOrNull()
        val message = messageRegex.find(body)?.groupValues?.get(1)
        return if (delay != null && delay > 0) {
            NodeResult(node, serverOf(node), delay, null)
        } else {
            NodeResult(node, serverOf(node), null, message ?: body.trim())
        }
    }
}
