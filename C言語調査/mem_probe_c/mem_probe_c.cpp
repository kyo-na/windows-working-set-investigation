#define _CRT_SECURE_NO_WARNINGS
#include <windows.h>
#include <psapi.h>
#include <stdio.h>
#include <stdint.h>
#include <intrin.h>

#pragma comment(lib, "psapi.lib")

typedef struct {
    SIZE_T WorkingSet;
    ULONGLONG PageFaults;
} MemSnapshot;

MemSnapshot CaptureMemory(void) {
    PROCESS_MEMORY_COUNTERS_EX pmc;
    MemSnapshot m = { 0 };

    if (GetProcessMemoryInfo(
        GetCurrentProcess(),
        (PROCESS_MEMORY_COUNTERS*)&pmc,
        sizeof(pmc))) {
        m.WorkingSet = pmc.WorkingSetSize;
        m.PageFaults = pmc.PageFaultCount;
    }
    return m;
}

void DrawWSBar(SIZE_T wsMB) {
    int bars = (int)(wsMB / 16);
    printf("WS %4llu MB |", (unsigned long long)wsMB);
    for (int i = 0; i < bars; i++) putchar('#');
    putchar('\n');
}

// ===============================
// x64対応 Touch（Sleepあり）
// ===============================
void TouchSequentialSleep(uint8_t* buf, size_t size) {
    volatile uint8_t tmp;

    for (size_t i = 0; i < size; i++) {
        tmp = buf[i];              // ★ 実メモリアクセス
        _ReadWriteBarrier();       // ★ コンパイラ最適化防止

        if ((i & 0xFFFF) == 0) {   // 64KBごと
            MemSnapshot m = CaptureMemory();
            DrawWSBar(m.WorkingSet / (1024 * 1024));
            Sleep(1);
        }

        if ((i & 0xFFFFF) == 0) {  // 1MBごと進捗
            printf(".");
            fflush(stdout);
        }
    }
    printf("\n");
}

int main(void) {
    const size_t SIZE = 512ULL * 1024 * 1024;

    printf("Allocating 512MB...\n");
    uint8_t* buf = (uint8_t*)VirtualAlloc(
        NULL, SIZE, MEM_COMMIT, PAGE_READWRITE);

    if (!buf) {
        printf("VirtualAlloc failed\n");
        return 1;
    }

    MemSnapshot start = CaptureMemory();
    printf("Start WS: %llu MB\n",
        (unsigned long long)(start.WorkingSet / (1024 * 1024)));

    printf("\nTouching memory (x64 + Sleep)...\n");
    TouchSequentialSleep(buf, SIZE);

    MemSnapshot afterTouch = CaptureMemory();
    printf("\nAfter Touch WS: %llu MB\n",
        (unsigned long long)(afterTouch.WorkingSet / (1024 * 1024)));

    printf("PageFaults delta: %llu\n",
        afterTouch.PageFaults - start.PageFaults);

    printf("\nVirtualFree...\n");
    VirtualFree(buf, 0, MEM_RELEASE);

    Sleep(1000);

    MemSnapshot afterFree = CaptureMemory();
    printf("After Free WS: %llu MB\n",
        (unsigned long long)(afterFree.WorkingSet / (1024 * 1024)));

    printf("Done.\n");
    return 0;
}
