#include <napi.h>
#include <windows.h>
#include <psapi.h>
#include <cstdio>

static void PrintMemInfo(const char* label, size_t touchedPages)
{
    PROCESS_MEMORY_COUNTERS pmc{};
    GetProcessMemoryInfo(
        GetCurrentProcess(),
        &pmc,
        sizeof(pmc)
    );

    printf(
        "[%s] TouchedPages=%zu  WS=%zu KB  PF=%zu\n",
        label,
        touchedPages,
        pmc.WorkingSetSize / 1024,
        pmc.PageFaultCount
    );
    fflush(stdout);
}

Napi::Value Touch(const Napi::CallbackInfo& info)
{
    Napi::Env env = info.Env();

    const size_t totalSize = 1024ULL * 1024 * 1024; // 1GB
    const size_t pageSize  = 4096;

    void* p = VirtualAlloc(
        nullptr,
        totalSize,
        MEM_RESERVE | MEM_COMMIT,
        PAGE_READWRITE
    );

    if (!p) {
        Napi::Error::New(env, "VirtualAlloc failed")
            .ThrowAsJavaScriptException();
        return env.Null();
    }

    size_t touched = 0;

    // before touch
    PrintMemInfo("BEFORE", touched);

    // touch memory
    for (size_t offset = 0; offset < totalSize; offset += pageSize) {
        ((volatile char*)p)[offset] = 1;
        touched++;

        // 64MB ごとにログ
        if ((offset & ((64ULL * 1024 * 1024) - 1)) == 0 && offset != 0) {
            PrintMemInfo("TOUCHING", touched);
        }
    }

    // after touch
    PrintMemInfo("AFTER", touched);

    return env.Undefined();
}

Napi::Object Init(Napi::Env env, Napi::Object exports)
{
    exports.Set(
        "touch",
        Napi::Function::New(env, Touch)
    );
    return exports;
}

NODE_API_MODULE(addon, Init)
