package com.woznes

import io.ktor.server.application.*
import io.ktor.server.plugins.cors.routing.*

fun main(args: Array<String>) {
    io.ktor.server.netty.EngineMain.main(args)
}

fun Application.module() {
    install(CORS) {
        // 网站屏蔽检测等工具需要在浏览器里跨域请求，这里放开全部来源/方法/请求头
        anyHost()
        anyMethod()
        allowHeaders { true }
        allowNonSimpleContentTypes = true
        maxAgeInSeconds = 86400
    }
    configureRouting()
}
