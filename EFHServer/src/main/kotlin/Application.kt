package com.woznes

import io.ktor.http.*
import io.ktor.server.application.*
import io.ktor.server.plugins.cachingheaders.*
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

    // 静态资源缓存：图片/字体长缓存（含 bkg.jpg），CSS/JS 一周；HTML 不设，走条件请求
    install(CachingHeaders) {
        options { outgoingContent ->
            val type = outgoingContent.contentType?.withoutParameters()
            val maxAge = when {
                type == null -> null
                type.contentType == "image" || type.contentType == "font" -> 60 * 60 * 24 * 365
                type.match(ContentType.Text.CSS) -> 60 * 60 * 24 * 7
                type.match(ContentType.Application.JavaScript) -> 60 * 60 * 24 * 7
                else -> null
            }
            maxAge?.let { CachingOptions(CacheControl.MaxAge(maxAgeSeconds = it)) }
        }
    }

    configureRouting()
}
