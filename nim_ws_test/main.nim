{.passL: "kernel32.lib".}
{.passL: "psapi.lib".}

type
  LPVOID = pointer
  SIZE_T = uint64
  DWORD = uint32
  HANDLE = pointer

const
  MEM_COMMIT     = 0x1000'u32
  MEM_RELEASE    = 0x8000'u32
  PAGE_READWRITE = 0x04'u32
  MB = 1024 * 1024

type
  PROCESS_MEMORY_COUNTERS_EX {.bycopy.} = object
    cb: DWORD
    PageFaultCount: DWORD
    PeakWorkingSetSize: SIZE_T
    WorkingSetSize: SIZE_T
    QuotaPeakPagedPoolUsage: SIZE_T
    QuotaPagedPoolUsage: SIZE_T
    QuotaPeakNonPagedPoolUsage: SIZE_T
    QuotaNonPagedPoolUsage: SIZE_T
    PagefileUsage: SIZE_T
    PeakPagefileUsage: SIZE_T
    PrivateUsage: SIZE_T

proc VirtualAlloc(
  lpAddress: LPVOID,
  dwSize: SIZE_T,
  flAllocationType: DWORD,
  flProtect: DWORD
): LPVOID {.stdcall, importc, dynlib: "kernel32.dll".}

proc VirtualFree(
  lpAddress: LPVOID,
  dwSize: SIZE_T,
  dwFreeType: DWORD
): bool {.stdcall, importc, dynlib: "kernel32.dll".}

proc GetCurrentProcess(): HANDLE
  {.stdcall, importc, dynlib: "kernel32.dll".}

proc GetProcessMemoryInfo(
  hProcess: HANDLE,
  counters: ptr PROCESS_MEMORY_COUNTERS_EX,
  cb: DWORD
): bool {.stdcall, importc, dynlib: "psapi.dll".}

proc capture(): PROCESS_MEMORY_COUNTERS_EX =
  var pmc: PROCESS_MEMORY_COUNTERS_EX
  pmc.cb = sizeof(PROCESS_MEMORY_COUNTERS_EX).DWORD
  discard GetProcessMemoryInfo(GetCurrentProcess(), addr pmc, pmc.cb)
  pmc

# ---- 読み＋書き / Sleepなし ----
proc touchReadWrite(buf: ptr UncheckedArray[uint8], size: int) =
  var lastMb = 0

  for i in 0 ..< size:
    # 読み
    let v = buf[i]
    # 書き（副作用あり）
    buf[i] = v xor 0xFF'u8

    let curMb = i div MB
    if curMb != lastMb:
      lastMb = curMb
      let m = capture()
      echo "Touched ", curMb, " MB | WS ",
           m.WorkingSetSize div MB, " MB | PF ",
           m.PageFaultCount

when isMainModule:
  let size = 512 * MB

  let raw = VirtualAlloc(
    nil,
    size.SIZE_T,
    MEM_COMMIT,
    PAGE_READWRITE
  )

  if raw == nil:
    echo "VirtualAlloc failed"
    quit(1)

  let buf = cast[ptr UncheckedArray[uint8]](raw)

  let start = capture()
  echo "Start WS ", start.WorkingSetSize div MB,
       " MB | PF ", start.PageFaultCount

  touchReadWrite(buf, size)

  discard VirtualFree(raw, 0, MEM_RELEASE)

  let finish = capture()
  echo "After Free WS ", finish.WorkingSetSize div MB, " MB"
