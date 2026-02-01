const std = @import("std");

// ================================
// WinAPI extern 宣言（x64）
// ================================
extern "kernel32" fn VirtualAlloc(
    lpAddress: ?*anyopaque,
    dwSize: usize,
    flAllocationType: u32,
    flProtect: u32,
) ?*anyopaque;

extern "kernel32" fn VirtualFree(
    lpAddress: ?*anyopaque,
    dwSize: usize,
    dwFreeType: u32,
) i32;

extern "kernel32" fn GetCurrentProcess() ?*anyopaque;

// --- psapi.dll ---
const PROCESS_MEMORY_COUNTERS_EX = extern struct {
    cb: u32,
    PageFaultCount: u32,
    PeakWorkingSetSize: usize,
    WorkingSetSize: usize,
    QuotaPeakPagedPoolUsage: usize,
    QuotaPagedPoolUsage: usize,
    QuotaPeakNonPagedPoolUsage: usize,
    QuotaNonPagedPoolUsage: usize,
    PagefileUsage: usize,
    PeakPagefileUsage: usize,
    PrivateUsage: usize,
};

extern "psapi" fn GetProcessMemoryInfo(
    hProcess: ?*anyopaque,
    counters: *PROCESS_MEMORY_COUNTERS_EX,
    cb: u32,
) i32;

// ================================
// 定数
// ================================
const MEM_COMMIT: u32 = 0x1000;
const MEM_RELEASE: u32 = 0x8000;
const PAGE_READWRITE: u32 = 0x04;

const MB: usize = 1024 * 1024;

// ================================
// WS / PageFault 取得
// ================================
fn captureMemory() PROCESS_MEMORY_COUNTERS_EX {
    var pmc: PROCESS_MEMORY_COUNTERS_EX = undefined;
    pmc.cb = @sizeOf(PROCESS_MEMORY_COUNTERS_EX);

    _ = GetProcessMemoryInfo(
        GetCurrentProcess(),
        &pmc,
        pmc.cb,
    );
    return pmc;
}

// ================================
// Sequential read + write
// ================================
fn touchSequential(
    buf: [*]u8,
    size: usize,
) void {
    var i: usize = 0;
    var last_mb: usize = 0;

    while (i < size) : (i += 1) {
        // write
        buf[i] = @intCast(i & 0xFF);
        // read
        _ = buf[i];

        const cur_mb = i / MB;
        if (cur_mb != last_mb) {
            last_mb = cur_mb;

            const m = captureMemory();
            std.debug.print(
                "Touched {d} MB | WS {d} MB | PF {d}\n",
                .{
                    cur_mb,
                    m.WorkingSetSize >> 20,
                    m.PageFaultCount,
                },
            );
        }
    }
}

// ================================
// main
// ================================
pub fn main() void {
    const SIZE: usize = 512 * MB;

    const raw = VirtualAlloc(
        null,
        SIZE,
        MEM_COMMIT,
        PAGE_READWRITE,
    ) orelse {
        std.debug.print("VirtualAlloc failed\n", .{});
        return;
    };

    const buf = @as([*]u8, @ptrCast(raw));

    const s = captureMemory();
    std.debug.print(
        "Start WS {d} MB | PF {d}\n",
        .{ s.WorkingSetSize >> 20, s.PageFaultCount },
    );

    touchSequential(buf, SIZE);

    _ = VirtualFree(raw, 0, MEM_RELEASE);

    const f = captureMemory();
    std.debug.print(
        "After Free WS {d} MB\n",
        .{ f.WorkingSetSize >> 20 },
    );
}
