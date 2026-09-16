import com.woznes.Status
import org.junit.Test

class StatusTest {

    @Test
    fun fetchNodeDelays() {
        val base = System.getenv("MIHOMO_CONTROLLER") ?: Status.DEFAULT_CONTROLLER
        println("controller=$base")
        val results = Status.nodeDelays(base)
        results.forEach {
            println("${it.name}: delay=${it.delayMs}ms message=${it.message} reachable=${it.reachable}")
        }
        check(results.size == Status.nodes.size)
    }
}
