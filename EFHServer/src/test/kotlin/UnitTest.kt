import org.junit.Test
import com.github.p4gefau1t.trojan.api.*
import com.woznes.UserManager
import kotlinx.coroutines.runBlocking
import java.io.File


class UnitTest {
    @Test
    fun t1(){
        val cert= File("/Users/nickji/Documents/CA/EFHServer.fullchain.crt")
        val key= File("/Users/nickji/Documents/CA/EFHServer.private.key")
        val ca=File("/Users/nickji/Documents/CA/WoznesCA.pem.cer")

        val u=UserManager(listOf("node2.vpn.woznes.com" to 444),ca,cert,key)

        runBlocking {
            u.listUsers().collect { value -> println(value) }
        }
    }
}