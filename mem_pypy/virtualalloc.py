import ctypes
import ctypes.wintypes as wt

kernel32 = ctypes.WinDLL("kernel32", use_last_error=True)

# --- PyPy 対応：SIZE_T を自前定義 ---
SIZE_T = ctypes.c_size_t

VirtualAlloc = kernel32.VirtualAlloc
VirtualAlloc.restype = wt.LPVOID
VirtualAlloc.argtypes = [wt.LPVOID, SIZE_T, wt.DWORD, wt.DWORD]

MEM_RESERVE = 0x2000
MEM_COMMIT  = 0x1000
PAGE_READWRITE = 0x04

size = 1024 * 1024 * 1024  # 1GB

ptr = VirtualAlloc(None, size, MEM_RESERVE | MEM_COMMIT, PAGE_READWRITE)
if not ptr:
    raise ctypes.WinError(ctypes.get_last_error())

print("alloc", hex(ptr))

buf = (ctypes.c_ubyte * size).from_address(ptr)

pages = 0
for i in range(0, size, 4096):
    buf[i] = 1
    pages += 1
    if pages % 16384 == 0:
        print("touched pages", pages)

input("press enter to exit")
