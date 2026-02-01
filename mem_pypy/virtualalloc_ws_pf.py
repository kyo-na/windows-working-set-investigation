import ctypes
import ctypes.wintypes as wt

kernel32 = ctypes.WinDLL("kernel32", use_last_error=True)
psapi    = ctypes.WinDLL("psapi", use_last_error=True)

# --- 型定義（PyPy対応） ---
SIZE_T = ctypes.c_size_t

class PROCESS_MEMORY_COUNTERS(ctypes.Structure):
    _fields_ = [
        ("cb", wt.DWORD),
        ("PageFaultCount", wt.DWORD),
        ("PeakWorkingSetSize", SIZE_T),
        ("WorkingSetSize", SIZE_T),
        ("QuotaPeakPagedPoolUsage", SIZE_T),
        ("QuotaPagedPoolUsage", SIZE_T),
        ("QuotaPeakNonPagedPoolUsage", SIZE_T),
        ("QuotaNonPagedPoolUsage", SIZE_T),
        ("PagefileUsage", SIZE_T),
        ("PeakPagefileUsage", SIZE_T),
    ]

GetCurrentProcess = kernel32.GetCurrentProcess
GetCurrentProcess.restype = wt.HANDLE

GetProcessMemoryInfo = psapi.GetProcessMemoryInfo
GetProcessMemoryInfo.argtypes = [
    wt.HANDLE,
    ctypes.POINTER(PROCESS_MEMORY_COUNTERS),
    wt.DWORD,
]
GetProcessMemoryInfo.restype = wt.BOOL

VirtualAlloc = kernel32.VirtualAlloc
VirtualAlloc.restype = wt.LPVOID
VirtualAlloc.argtypes = [wt.LPVOID, SIZE_T, wt.DWORD, wt.DWORD]

MEM_RESERVE = 0x2000
MEM_COMMIT  = 0x1000
PAGE_READWRITE = 0x04

def print_mem(tag, touched_pages):
    pmc = PROCESS_MEMORY_COUNTERS()
    pmc.cb = ctypes.sizeof(pmc)
    GetProcessMemoryInfo(GetCurrentProcess(), ctypes.byref(pmc), pmc.cb)
    print(
        f"[{tag}] "
        f"TouchedPages={touched_pages} "
        f"WS={pmc.WorkingSetSize // 1024} KB "
        f"PF={pmc.PageFaultCount}"
    )

# --- 実験開始 ---
size = 1024 * 1024 * 1024  # 1GB

ptr = VirtualAlloc(None, size, MEM_RESERVE | MEM_COMMIT, PAGE_READWRITE)
if not ptr:
    raise ctypes.WinError(ctypes.get_last_error())

print("native touch start")
print_mem("BEFORE", 0)

buf = (ctypes.c_ubyte * size).from_address(ptr)

pages = 0
for i in range(0, size, 4096):
    buf[i] = 1
    pages += 1
    if pages % 16384 == 0:
        print_mem("TOUCHING", pages)

print_mem("AFTER", pages)
print("native touch done")

input("press enter to exit")
