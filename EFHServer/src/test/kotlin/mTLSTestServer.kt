import com.github.p4gefau1t.trojan.api.*
import io.grpc.Server
import io.grpc.netty.GrpcSslContexts
import io.grpc.netty.NettyServerBuilder
import io.netty.handler.ssl.SslContext
import java.io.File
import java.net.InetSocketAddress
import java.util.concurrent.TimeUnit

class GreeterService : TrojanServerServiceGrpc.TrojanServerServiceImplBase() {

}

private fun buildServerSslContext(
    certChain: File,
    privateKey: File,
    trustCa: File
): SslContext? {
    // 使用 PEM 文件直接构建（更符合 ACME/openssl 产物）
    return GrpcSslContexts.forServer(certChain, privateKey)
        .trustManager(trustCa)
        .build()
}

fun main() {
    val port = 50051
    val certDir = File("/Users/nickji/Documents/CA/")
    val serverCert = File(certDir, "EFHServer.pem")
    val serverKey  = File(certDir, "EFHServer.private.key")
    val caPem      = File(certDir, "WoznesCA.pem.cer")

    require(serverCert.exists() && serverKey.exists() && caPem.exists()) {
        "Missing TLS files in ./certs (need server.crt, server.key, ca.pem)"
    }

    val sslContext = buildServerSslContext(serverCert, serverKey, caPem)

    val server: Server = NettyServerBuilder
        .forAddress(InetSocketAddress("0.0.0.0", port))
        .sslContext(sslContext)
        .addService(GreeterService())
        .permitKeepAliveTime(30, TimeUnit.SECONDS)
        .permitKeepAliveWithoutCalls(true)
        .build()
        .start()

    println("mTLS gRPC server started on port $port")
    Runtime.getRuntime().addShutdownHook(Thread {
        println("Shutting down gRPC server...")
        server.shutdown().awaitTermination(5, TimeUnit.SECONDS)
        println("Server stopped.")
    })
    server.awaitTermination()
}
