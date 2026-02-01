import java.lang.management.ManagementFactory
import com.sun.management.OperatingSystemMXBean

fun main() {
    val os = ManagementFactory.getOperatingSystemMXBean()
            as OperatingSystemMXBean

    val sizeMB = 512
    val page = 4096
    val buf = ByteArray(sizeMB * 1024 * 1024)

    var touched = 0

    println("PID: ${ProcessHandle.current().pid()}")

    for (i in buf.indices step page) {
        buf[i] = 1
        touched += page

        if (touched % (10 * 1024 * 1024) == 0) {
            val wsApprox = os.processCpuTime // JVMでは直接WS不可（比較用）
            val commit = os.committedVirtualMemorySize / (1024 * 1024)

            println(
                "Touched ${touched / 1024 / 1024} MB | " +
                "CommittedVM ${commit} MB"
            )
        }
    }

    // 解放しない（Swift / Delphi と条件合わせ）
    Thread.sleep(Long.MAX_VALUE)
}
