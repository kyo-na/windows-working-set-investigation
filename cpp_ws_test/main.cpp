#include <windows.h>
#include <psapi.h>
#include <cstdio>
#include <cstdint>

int main() {

    constexpr size_t SIZE = 512ull * 1024 * 1024; // 512MB
    constexpr bool USE_SLEEP = true;

    // --- VirtualAlloc
    uint8_t* buf = (uint8_t*)VirtualAlloc(
        nullptr,
        SIZE,
        MEM_RESERVE | MEM_COMMIT,
        PAGE_READWRITE
    );

    if (!buf) {
        printf("VirtualAlloc failed\n");
        return 1;
    }

    PROCESS_MEMORY_COUNTERS_EX pmc{};
    pmc.cb = sizeof(pmc);

    HANDLE hProcess = GetCurrentProcess();

    size_t touchedMB = 0;

    // ---- 4KB stride（ページ単位）
    for (size_t i = 0; i < SIZE; i += 4096) {

        volatile uint8_t x = buf[i];
        (void)x;

        if ((i & 0xFFFFF) == 0) { // 約1MBごと

            if (!GetProcessMemoryInfo(
                hProcess,
                (PROCESS_MEMORY_COUNTERS*)&pmc,
                sizeof(pmc)
            )) {
                printf("GetProcessMemoryInfo failed\n");
                break;
            }

            size_t wsMB = pmc.WorkingSetSize >> 20;
            DWORD pf = pmc.PageFaultCount;

            printf(
                "Touched %4zu MB | WS %4zu MB | PF %lu\n",
                touchedMB,
                wsMB,
                pf
            );

            touchedMB++;

            if (USE_SLEEP) {
                Sleep(1);
            }
        }
    }

    VirtualFree(buf, 0, MEM_RELEASE);
    return 0;
}
