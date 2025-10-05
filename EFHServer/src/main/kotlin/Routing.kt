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
    }
}
