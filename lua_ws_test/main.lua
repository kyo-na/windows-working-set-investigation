local ffi = require("ffi")

-- ================================
-- WinAPI 定義
-- ================================
ffi.cdef[[
typedef void* HANDLE;
typedef unsigned long DWORD;
typedef size_t SIZE_T;
typedef int BOOL;

void* VirtualAlloc(
    void* lpAddress,
    SIZE_T dwSize,
    DWORD flAllocationType,
    DWORD flProtect
);

BOOL VirtualFree(
    void* lpAddress,
    SIZE_T dwSize,
    DWORD dwFreeType
);

HANDLE GetCurrentProcess(void);

typedef struct {
    DWORD cb;
    DWORD PageFaultCount;
    SIZE_T PeakWorkingSetSize;
    SIZE_T WorkingSetSize;
    SIZE_T QuotaPeakPagedPoolUsage;
    SIZE_T QuotaPagedPoolUsage;
    SIZE_T QuotaPeakNonPagedPoolUsage;
    SIZE_T QuotaNonPagedPoolUsage;
    SIZE_T PagefileUsage;
    SIZE_T PeakPagefileUsage;
    SIZE_T PrivateUsage;
} PROCESS_MEMORY_COUNTERS_EX;

BOOL GetProcessMemoryInfo(
    HANDLE hProcess,
    PROCESS_MEMORY_COUNTERS_EX* counters,
    DWORD cb
);
]]

-- DLL ハンドル
local kernel32 = ffi.C
local psapi = ffi.load("psapi")

-- ================================
-- 定数
-- ================================
local MEM_COMMIT     = 0x1000
local MEM_RELEASE    = 0x8000
local PAGE_READWRITE = 0x04

local MB   = 1024 * 1024
local SIZE = 512 * MB

-- ================================
-- Memory capture
-- ================================
local function capture()
    local pmc = ffi.new("PROCESS_MEMORY_COUNTERS_EX")
    pmc.cb = ffi.sizeof(pmc)
    psapi.GetProcessMemoryInfo(
        kernel32.GetCurrentProcess(),
        pmc,
        pmc.cb
    )
    return pmc
end

-- ================================
-- main
-- ================================
local raw = kernel32.VirtualAlloc(
    nil,
    SIZE,
    MEM_COMMIT,
    PAGE_READWRITE
)
assert(raw ~= nil, "VirtualAlloc failed")

local buf = ffi.cast("uint8_t*", raw)

local s = capture()
print(string.format(
    "Start WS %d MB | PF %d",
    tonumber(s.WorkingSetSize / MB),
    tonumber(s.PageFaultCount)
))

local last_mb = 0

for i = 0, SIZE - 1 do
    -- write
    buf[i] = i % 256
    -- read
    local _ = buf[i]

    local cur_mb = math.floor(i / MB)
    if cur_mb ~= last_mb then
        last_mb = cur_mb
        local m = capture()
        print(string.format(
            "Touched %d MB | WS %d MB | PF %d",
            cur_mb,
            tonumber(m.WorkingSetSize / MB),
            tonumber(m.PageFaultCount)
        ))
    end
end

kernel32.VirtualFree(raw, 0, MEM_RELEASE)

local f = capture()
print(string.format(
    "After Free WS %d MB",
    tonumber(f.WorkingSetSize / MB)
))
