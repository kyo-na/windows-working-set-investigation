import WinSDK

let sizeMB = 512
let size = sizeMB * 1024 * 1024
let page = 4096

let ptr = UnsafeMutableRawPointer.allocate(
    byteCount: size,
    alignment: page
)

let hProcess = GetCurrentProcess()

var pmc = PROCESS_MEMORY_COUNTERS_EX()
pmc.cb = DWORD(MemoryLayout<PROCESS_MEMORY_COUNTERS_EX>.size)

var touchedBytes = 0

for offset in stride(from: 0, to: size, by: page) {
    ptr.storeBytes(of: UInt8(1), toByteOffset: offset, as: UInt8.self)
    touchedBytes += page

    if touchedBytes % (10 * 1024 * 1024) == 0 {

        withUnsafeMutablePointer(to: &pmc) {
            $0.withMemoryRebound(
                to: PROCESS_MEMORY_COUNTERS.self,
                capacity: 1
            ) {
                _ = K32GetProcessMemoryInfo(
                    hProcess,
                    $0,
                    DWORD(MemoryLayout<PROCESS_MEMORY_COUNTERS_EX>.size)
                )
            }
        }

        let touchedMB = touchedBytes / 1024 / 1024
        let wsMB = Int(pmc.WorkingSetSize) / 1024 / 1024
        let pf = pmc.PageFaultCount

        print("Touched \(touchedMB) MB | WS \(wsMB) MB | PF \(pf)")
    }
}

// プロセス維持
while true {}
