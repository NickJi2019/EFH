import org.junit.Test
import com.github.p4gefau1t.trojan.api.*
import com.woznes.UserManager
import kotlinx.coroutines.runBlocking
import java.io.File


class UnitTest {
    @Test
    fun t1(){
        val cert= File("/Users/nickji/Documents/CA/EFHServer.crt")
        val key= File("/Users/nickji/Documents/CA/EFHServer.private.key")
        println(cert.absolutePath)
        println(key.absolutePath)
        println(cert.bufferedReader().readText())
        println(key.bufferedReader().readText())
        val u=UserManager(listOf("vpn.woznes.com" to 444), cert , key)
        runBlocking {
            u.listUsers().collect { value -> println(value) }
        }
    }
}