import java.lang.foreign.*;
import static java.lang.foreign.ValueLayout.*;

public class WsTest {

    static final Linker linker = Linker.nativeLinker();

    static final SymbolLookup KERNEL32 =
            SymbolLookup.libraryLookup("kernel32.dll", Arena.global());
    static final SymbolLookup PSAPI =
            SymbolLookup.libraryLookup("psapi.dll", Arena.global());

    static final FunctionDescriptor GET_CURRENT_PROCESS =
            FunctionDescriptor.of(ADDRESS);

    static final FunctionDescriptor GET_PROCESS_MEMORY_INFO =
            FunctionDescriptor.of(JAVA_INT, ADDRESS, ADDRESS, JAVA_INT);

    static final FunctionDescriptor VIRTUAL_ALLOC =
            FunctionDescriptor.of(ADDRESS, ADDRESS, JAVA_LONG, JAVA_INT, JAVA_INT);

    static final FunctionDescriptor SLEEP =
            FunctionDescriptor.ofVoid(JAVA_INT);

    static final MemoryLayout PMC_LAYOUT =
            MemoryLayout.structLayout(
                    JAVA_INT.withName("cb"),
                    JAVA_INT.withName("PageFaultCount"),
                    JAVA_LONG.withName("PeakWorkingSetSize"),
                    JAVA_LONG.withName("WorkingSetSize"),
                    JAVA_LONG.withName("QuotaPeakPagedPoolUsage"),
                    JAVA_LONG.withName("QuotaPagedPoolUsage"),
                    JAVA_LONG.withName("QuotaPeakNonPagedPoolUsage"),
                    JAVA_LONG.withName("QuotaNonPagedPoolUsage"),
                    JAVA_LONG.withName("PagefileUsage"),
                    JAVA_LONG.withName("PeakPagefileUsage"),
                    JAVA_LONG.withName("PrivateUsage")
            );

    static final long PF_OFFSET =
            PMC_LAYOUT.byteOffset(MemoryLayout.PathElement.groupElement("PageFaultCount"));
    static final long WS_OFFSET =
            PMC_LAYOUT.byteOffset(MemoryLayout.PathElement.groupElement("WorkingSetSize"));

    public static void main(String[] args) throws Throwable {

        final long SIZE = 512L * 1024 * 1024; // 512MB
        final boolean USE_SLEEP = true;

        try (Arena arena = Arena.ofConfined()) {

            var getCurrentProcess = linker.downcallHandle(
                    KERNEL32.find("GetCurrentProcess").orElseThrow(),
                    GET_CURRENT_PROCESS
            );

            var getProcessMemoryInfo = linker.downcallHandle(
                    PSAPI.find("GetProcessMemoryInfo").orElseThrow(),
                    GET_PROCESS_MEMORY_INFO
            );

            var virtualAlloc = linker.downcallHandle(
                    KERNEL32.find("VirtualAlloc").orElseThrow(),
                    VIRTUAL_ALLOC
            );

            var sleep = linker.downcallHandle(
                    KERNEL32.find("Sleep").orElseThrow(),
                    SLEEP
            );

            // ---- VirtualAlloc（1回だけ）
            MemorySegment addr = (MemorySegment) virtualAlloc.invoke(
                    MemorySegment.NULL,
                    SIZE,
                    0x1000 | 0x2000,   // MEM_COMMIT | MEM_RESERVE
                    0x04              // PAGE_READWRITE
            );

            if (addr.address() == 0) {
                throw new OutOfMemoryError("VirtualAlloc failed");
            }

            // ★ Java 25 正解：サイズ付き MemorySegment
            MemorySegment buf =
                    MemorySegment.ofAddress(addr.address())
                                 .reinterpret(SIZE, arena, null);

            MemorySegment pmc = arena.allocate(PMC_LAYOUT);
            pmc.set(JAVA_INT, 0, (int) PMC_LAYOUT.byteSize());

            MemorySegment hProcess =
                    (MemorySegment) getCurrentProcess.invoke();

            long touchedMB = 0;

            for (long i = 0; i < SIZE; i++) {

                // volatile 相当アクセス
                buf.get(JAVA_BYTE, i);

                if ((i & 0xFFFFF) == 0) { // 1MBごと

                    int ok = (int) getProcessMemoryInfo.invoke(
                            hProcess,
                            pmc,
                            (int) PMC_LAYOUT.byteSize()
                    );

                    if (ok == 0) {
                        throw new IllegalStateException("GetProcessMemoryInfo failed");
                    }

                    long pf = pmc.get(JAVA_INT, PF_OFFSET) & 0xFFFFFFFFL;
                    long ws = pmc.get(JAVA_LONG, WS_OFFSET) >> 20;

                    System.out.printf(
                            "Touched %4d MB | WS %4d MB | PF %d%n",
                            touchedMB, ws, pf
                    );

                    touchedMB++;

                    if (USE_SLEEP) {
                        sleep.invoke(1);
                    }
                }
            }
        }
    }
}
