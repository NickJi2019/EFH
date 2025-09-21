package com.woznes

import io.grpc.ManagedChannel
import io.grpc.netty.NettyChannelBuilder
import io.grpc.netty.GrpcSslContexts
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.collect
import kotlinx.coroutines.flow.flow
import com.github.p4gefau1t.trojan.api.*
import java.io.File

class UserManager(
    private val nodes: List<Pair<String, Int>>, // host + port
    private val cert: File,
    private val clientCrt: File,
    private val clientKey: File
) {
    private val channels: List<ManagedChannel> = nodes.map { (host, port) ->
        val sslContext = GrpcSslContexts.forClient()
            .trustManager(cert)
            .keyManager(clientCrt, clientKey) // 客户端证书 + 私钥（双向认证）
            .build()

        NettyChannelBuilder.forAddress(host, port)
            .sslContext(sslContext)
            .build()
    }

    private val stubs = channels.map {
        TrojanServerServiceGrpcKt.TrojanServerServiceCoroutineStub(it)
    }

    /** ------------------ 查询所有节点用户 ------------------ */
    fun listUsers(): Flow<Pair<String, UserStatus>> = flow {
        for ((i, stub) in stubs.withIndex()) {
            val host = nodes[i].first
            val responseFlow = stub.listUsers(ListUsersRequest.getDefaultInstance())
            responseFlow.collect { resp ->
                emit(host to resp.status)
            }
        }
    }

    /** ------------------ 添加用户 ------------------ */
    suspend fun addUser(userStatus: UserStatus) {
        val request = SetUsersRequest.newBuilder()
            .setStatus(userStatus)
            .setOperation(SetUsersRequest.Operation.Add)
            .build()

        for (stub in stubs) {
            val requestFlow = flow { emit(request) }
            val responseFlow = stub.setUsers(requestFlow)
            responseFlow.collect { resp ->
                println("Add user -> success=${resp.success}, info=${resp.info}")
            }
        }
    }

    /** ------------------ 删除用户 ------------------ */
    suspend fun deleteUser(userStatus: UserStatus) {
        val request = SetUsersRequest.newBuilder()
            .setStatus(userStatus)
            .setOperation(SetUsersRequest.Operation.Delete)
            .build()

        for (stub in stubs) {
            val requestFlow = flow { emit(request) }
            val responseFlow = stub.setUsers(requestFlow)
            responseFlow.collect { resp ->
                println("Delete user -> success=${resp.success}, info=${resp.info}")
            }
        }
    }

    /** ------------------ 修改用户 ------------------ */
    suspend fun modifyUser(userStatus: UserStatus) {
        val request = SetUsersRequest.newBuilder()
            .setStatus(userStatus)
            .setOperation(SetUsersRequest.Operation.Modify)
            .build()

        for (stub in stubs) {
            val requestFlow = flow { emit(request) }
            val responseFlow = stub.setUsers(requestFlow)
            responseFlow.collect { resp ->
                println("Modify user -> success=${resp.success}, info=${resp.info}")
            }
        }
    }

    fun shutdown() {
        channels.forEach { it.shutdownNow() }
    }
}
