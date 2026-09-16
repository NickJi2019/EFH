package com.woznes

import io.ktor.http.*
import io.ktor.server.application.*
import io.ktor.server.http.content.*
import io.ktor.server.plugins.statuspages.*
import io.ktor.server.response.*
import io.ktor.server.routing.*

fun loadFile(file: String): String {
    return Thread.currentThread().contextClassLoader.getResourceAsStream(file).readBytes().toString(Charsets.UTF_8)
}

fun loadReplace(file: String, replaceWith: Map<String, String>): String {
    var content = loadFile(file)
    replaceWith.forEach { (key, value) -> content = content.replace(key, value) }
    return content
}

fun loadConfig(config: String, passwd: String, url: String = ""): String {
    return loadReplace(config, mapOf($$$"$$passwd$$" to passwd, $$$"$$url$$" to url))
}

fun Application.configureRouting() {

    routing {
        staticResources("/", "static")
        install(StatusPages) {
            status(HttpStatusCode.NotFound) { call, status ->
                call.respondText(text = loadFile("404.html"), status = status)
            }
            exception<Throwable> { call, cause ->
                call.respondText(
                    text = loadReplace(
                        "50x.html", mapOf(
                            $$$$"$$$title$$$" to "HTTP: 500", $$$$"$$$subtitle$$$" to "Internal Server Error",
                            $$$$"$$$issue$$$" to "500", $$$$"$$$description$$$" to cause.toString()
                        )
                    ), status = HttpStatusCode.InternalServerError
                )
            }
        }
        get("/clash/{passwd}") {
            call.pathParameters["passwd"]?.let {
                call.respondText(loadConfig("clash.yaml", it))
            }
        }
        get("/surge/{passwd}") {
            call.pathParameters["passwd"]?.let {
                call.respondText(loadConfig("shadowrocket.conf", it, "https://vpn.woznes.com/surge/$it"))
            }
        }

        // v2 get configuration
        get("/get-config/{passwd}/Woznes-EFH-Clash") {
            call.pathParameters["passwd"]?.let {
                call.respondText(loadConfig("clash.yaml", it))
            }
        }
        get("/get-config/{passwd}/Woznes-EFH-Surge") {
            call.pathParameters["passwd"]?.let {
                call.respondText(loadConfig("shadowrocket.conf", it, "https://vpn.woznes.com/get-config/$it/Woznes-EFH-Surge"))
            }
        }

        // 通过 mihomo 外部控制器对四个节点做可达性测速；test=false 仅返回节点名（待检测）
        get("/status/nodes") {
            val test = call.request.queryParameters["test"]?.toBooleanStrictOrNull() ?: true
            try {
                val results = if (test) Status.nodeDelays() else Status.pending()
                call.respondText(Status.toJson(results), ContentType.Application.Json)
            } catch (e: Exception) {
                call.respondText(
                    text = """{"error":"${e.message ?: "failed"}"}""",
                    status = HttpStatusCode.BadGateway
                )
            }
        }

        // 下发 Cloudflare Radar Top 网站列表，每行一个域名
        get("/top-domains/{top}") {
            val top = call.pathParameters["top"]?.toIntOrNull()
            if (top == null || !TopDomains.isValid(top)) {
                call.respondText(
                    text = "invalid top; supported: ${TopDomains.buckets.joinToString(",")}",
                    status = HttpStatusCode.BadRequest
                )
                return@get
            }
            try {
                call.respondText(TopDomains.download(top).joinToString("\n"), ContentType.Text.Plain)
            } catch (e: Exception) {
                call.respondText(
                    text = "failed to fetch top $top: ${e.message}",
                    status = HttpStatusCode.BadGateway
                )
            }
        }
    }
}
