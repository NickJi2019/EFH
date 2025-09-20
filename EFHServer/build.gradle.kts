
val kotlin_version: String by project
val logback_version: String by project

plugins {
    kotlin("jvm") version "2.2.20"
    id("io.ktor.plugin") version "3.3.0"
    id("com.google.protobuf") version "0.9.2"
}

group = "com.woznes"
version = "0.0.1"

application {
    mainClass = "io.ktor.server.netty.EngineMain"
}

dependencies {
    implementation("io.ktor:ktor-server-core-jvm")
    implementation("io.ktor:ktor-server-netty")
    implementation("ch.qos.logback:logback-classic:$logback_version")
    implementation("io.ktor:ktor-server-core")
    implementation("io.ktor:ktor-server-config-yaml")
    testImplementation("io.ktor:ktor-server-test-host")
    testImplementation("org.jetbrains.kotlin:kotlin-test-junit:$kotlin_version")

    implementation("com.google.protobuf:protobuf-java:3.22.2")
    implementation("io.grpc:grpc-protobuf:1.53.0")
    implementation("com.google.protobuf:protobuf-kotlin:3.22.2")
    implementation("io.grpc:grpc-kotlin-stub:1.3.0")
    implementation("io.grpc:grpc-netty:1.56.1")
    implementation("io.grpc:grpc-all:1.56.1")

    implementation("org.redisson:redisson:3.37.0") // 建议用最新版

    implementation("org.jetbrains.kotlinx:kotlinx-cli:0.3.6")

}

protobuf {
    protoc {
        artifact = "com.google.protobuf:protoc:3.25.3"
    }
    plugins {
//        create("java") {
//            artifact = "io.grpc:protoc-gen-grpc-java:1.60.2"
//        }
        create("grpc") {
            artifact = "io.grpc:protoc-gen-grpc-java:1.60.2"
        }
        create("grpckt") {
            artifact = "io.grpc:protoc-gen-grpc-kotlin:1.4.1" + ":jdk8@jar"
        }
    }
    generateProtoTasks {
        all().forEach {
            it.plugins {
//                create("java") {
//                    option("lite")
//                }
                create("grpc") {
                    option("lite")
                }
                create("grpckt") {
                    option("lite")
                }
            }
            it.builtins {
                create("kotlin") {
                    option("lite")
                }
            }
        }
    }
}
