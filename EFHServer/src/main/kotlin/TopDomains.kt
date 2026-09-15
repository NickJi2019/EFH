package com.woznes

import java.net.URI
import java.net.URL
import java.net.http.HttpClient
import java.net.http.HttpRequest
import java.net.http.HttpResponse
import java.time.Duration

object TopDomains {

    val buckets = listOf(
        200, 500, 1000, 2000, 5000, 10000, 20000, 50000,
        100000, 200000, 500000, 1000000
    )

    private const val radarAttachmentURL = "https://radar.cloudflare.com/charts/LargerTopDomainsTable/attachment?top="
    private const val radarAPIStreamURL = "https://api.cloudflare.com/client/v4/radar/datasets/ranking_top_"
    private const val radarTokenEnv = "CF_Token"

    private val client: HttpClient = HttpClient.newBuilder()
        .connectTimeout(Duration.ofSeconds(30))
        .followRedirects(HttpClient.Redirect.NORMAL)
        .build()

    fun isValid(top: Int): Boolean = buckets.contains(top)

    fun download(top: Int): List<String> {
        if (!isValid(top)) {
            throw IllegalArgumentException("unsupported top list: $top")
        }
        val attachment = request(radarAttachmentURL + top, null)
        if (attachment.statusCode() == 200) {
            return parseCsv(attachment.body())
        }
        if (attachment.statusCode() != 403) {
            throw IllegalStateException("download Top $top: HTTP ${attachment.statusCode()}")
        }
        val token = System.getenv(radarTokenEnv)?.trim().orEmpty()
        if (token.isEmpty()) {
            throw IllegalStateException("download Top $top: HTTP 403; set $radarTokenEnv to use the Radar API")
        }
        val api = request(radarAPIStreamURL + top, token)
        if (api.statusCode() != 200) {
            throw IllegalStateException("Radar API Top $top: HTTP ${api.statusCode()}; check $radarTokenEnv permission")
        }
        return parseCsv(api.body())
    }

    private fun request(url: String, bearerToken: String?): HttpResponse<String> {
        val builder = HttpRequest.newBuilder(URI.create(url))
            .timeout(Duration.ofSeconds(90))
            .header("Accept", "text/csv,text/plain;q=0.9,*/*;q=0.1")
            .header("User-Agent", "EFHServer/1.0")
            .GET()
        if (bearerToken != null) {
            builder.header("Authorization", "Bearer $bearerToken")
        }
        return client.send(builder.build(), HttpResponse.BodyHandlers.ofString())
    }

    private fun parseCsv(body: String): List<String> {
        val lines = body.lineSequence().filter { it.isNotBlank() }.toList()
        if (lines.isEmpty()) {
            return emptyList()
        }
        val header = splitCsvLine(lines.first())
        val domainCol = findDomainColumn(header)
        if (domainCol < 0) {
            throw IllegalStateException("expected a domain CSV")
        }
        val domains = LinkedHashSet<String>()
        for (i in 1 until lines.size) {
            val record = splitCsvLine(lines[i])
            if (domainCol < record.size) {
                val host = normalizeHost(record[domainCol])
                if (host.isNotEmpty()) {
                    domains.add(host)
                }
            }
        }
        return domains.toList()
    }

    private fun splitCsvLine(line: String): List<String> {
        val fields = mutableListOf<String>()
        val current = StringBuilder()
        var quoted = false
        var i = 0
        while (i < line.length) {
            val c = line[i]
            when {
                quoted && c == '"' && i + 1 < line.length && line[i + 1] == '"' -> {
                    current.append('"')
                    i++
                }
                c == '"' -> quoted = !quoted
                c == ',' && !quoted -> {
                    fields.add(current.toString())
                    current.setLength(0)
                }
                else -> current.append(c)
            }
            i++
        }
        fields.add(current.toString())
        return fields
    }

    private fun findDomainColumn(header: List<String>): Int {
        header.forEachIndexed { index, name ->
            when (name.trim().lowercase()) {
                "domain", "host", "hostname", "url", "website" -> return index
            }
        }
        return -1
    }

    private fun normalizeHost(value: String): String {
        var v = value.trim()
        if (v.isEmpty()) {
            return ""
        }
        if (!v.contains("://")) {
            v = "https://$v"
        }
        return try {
            URL(v).host?.trimEnd('.')?.lowercase().orEmpty()
        } catch (e: Exception) {
            ""
        }
    }
}
