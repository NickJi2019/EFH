package com.woznes

import io.ktor.server.application.*
import io.ktor.server.response.*
import io.ktor.server.routing.*

fun loadFile(file: String):String{
    return Thread.currentThread().contextClassLoader.getResourceAsStream(file).readBytes().toString(Charsets.UTF_8)
}

fun loadConfig(config: String, passwd: String, url: String = ""):String{
    val conf = loadFile(config)
    return conf
        .replace($$$"$$passwd$$", passwd)
        .replace($$$"$$url$$", url)
}

fun Application.configureRouting() {

    routing {
        get("/") {
            call.respondText(loadFile("index.html"))
        }

        get("/clash/{passwd}"){
            call.pathParameters["passwd"]?.let {
                call.respondText(loadConfig("clash.yaml", it))
            }
        }
        get("/surge/{passwd}"){
            call.pathParameters["passwd"]?.let {
                call.respondText(loadConfig("surge.conf", it, "https://vpn.woznes.com/surge/$it"))
            }
        }
    }
}
