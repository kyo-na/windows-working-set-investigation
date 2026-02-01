import koffi from "koffi";

// ================================
// DLL load
// ================================
const kernel32 = koffi.load("kernel32.dll");
const psapi    = koffi.load("psapi.dll");

// ================================
// WinAPI prototypes
// ================================
const VirtualAlloc = kernel32.func(
  "VirtualAlloc",
  "void*",
  ["void*", "size_t", "uint32", "uint32"]
);

const VirtualFree = kernel32.func(
  "VirtualFree",
  "int",
  ["void*", "size_t", "uint32"]
);

const GetCurrentProcess = kernel32.func(
  "GetCurrentProcess",
  "void*",
  []
);

const PROCESS_MEMORY_COUNTERS_EX = koffi.struct({
  cb: "uint32",
  PageFaultCount: "uint32",
  PeakWorkingSetSize: "size_t",
  WorkingSetSize: "size_t",
  QuotaPeakPagedPoolUsage: "size_t",
  QuotaPagedPoolUsage: "size_t",
  QuotaPeakNonPagedPoolUsage: "size_t",
  QuotaNonPagedPoolUsage: "size_t",
  PagefileUsage: "size_t",
  PeakPagefileUsage: "size_t",
  PrivateUsage: "size_t",
});

const GetProcessMemoryInfo = psapi.func(
  "GetProcessMemoryInfo",
  "int",
  ["void*", koffi.pointer(PROCESS_MEMORY_COUNTERS_EX), "uint32"]
);

// ================================
// constants
// ================================
const MEM_COMMIT = 0x1000;
const MEM_RELEASE = 0x8000;
const PAGE_READWRITE = 0x04;
const MB = 1024 * 1024;

// ================================
// capture WS / PF
// ================================
function capture() {
  const pmc = koffi.alloc(PROCESS_MEMORY_COUNTERS_EX, 1);
  pmc[0].cb = PROCESS_MEMORY_COUNTERS_EX.size;

  GetProcessMemoryInfo(
    GetCurrentProcess(),
    pmc,
    pmc[0].cb
  );

  return {
    ws: Math.floor(pmc[0].WorkingSetSize / MB),
    pf: pmc[0].PageFaultCount,
  };
}

// ================================
// main
// ================================
const SIZE = 512 * MB;

const buf = VirtualAlloc(
  null,
  SIZE,
  MEM_COMMIT,
  PAGE_READWRITE
);

if (!buf) {
  console.error("VirtualAlloc failed");
  process.exit(1);
}

let { ws, pf } = capture();
console.log(`Start WS ${ws} MB | PF ${pf}`);

let lastMB = 0;
for (let i = 0; i < SIZE; i++) {
  buf[i] = 1; // read+write

  const curMB = (i / MB) | 0;
  if (curMB !== lastMB) {
    lastMB = curMB;
    ({ ws, pf } = capture());
    console.log(`Touched ${curMB} MB | WS ${ws} MB | PF ${pf}`);
  }
}

VirtualFree(buf, 0, MEM_RELEASE);
if (global.gc) global.gc();

({ ws } = capture());
console.log(`After Free WS ${ws} MB`);
