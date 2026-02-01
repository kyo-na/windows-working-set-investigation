using System;
using System.Runtime.InteropServices;
using System.Threading;

class Program
{
    [DllImport("kernel32.dll")]
    static extern IntPtr GetCurrentProcess();

    [DllImport("psapi.dll", SetLastError = true)]
    static extern bool GetProcessMemoryInfo(
        IntPtr hProcess,
        out PROCESS_MEMORY_COUNTERS_EX counters,
        int size
    );

    [DllImport("kernel32.dll", SetLastError = true)]
    static extern IntPtr VirtualAlloc(
        IntPtr lpAddress,
        UIntPtr dwSize,
        uint flAllocationType,
        uint flProtect
    );

    const uint MEM_COMMIT  = 0x1000;
    const uint MEM_RESERVE = 0x2000;
    const uint PAGE_READWRITE = 0x04;

    [StructLayout(LayoutKind.Sequential)]
    struct PROCESS_MEMORY_COUNTERS_EX
    {
        public uint cb;
        public uint PageFaultCount;
        public ulong PeakWorkingSetSize;
        public ulong WorkingSetSize;
        public ulong QuotaPeakPagedPoolUsage;
        public ulong QuotaPagedPoolUsage;
        public ulong QuotaPeakNonPagedPoolUsage;
        public ulong QuotaNonPagedPoolUsage;
        public ulong PagefileUsage;
        public ulong PeakPagefileUsage;
        public ulong PrivateUsage;
    }

    unsafe static void Main()
    {
        const long SIZE = 512L * 1024 * 1024; // 512MB
        const bool USE_SLEEP = true;

        IntPtr buf = VirtualAlloc(
            IntPtr.Zero,
            (UIntPtr)SIZE,
            MEM_COMMIT | MEM_RESERVE,
            PAGE_READWRITE
        );

        if (buf == IntPtr.Zero)
        {
            Console.WriteLine("VirtualAlloc failed");
            return;
        }

        byte* p = (byte*)buf.ToPointer();
        IntPtr hProcess = GetCurrentProcess();

        PROCESS_MEMORY_COUNTERS_EX pmc = new();
        pmc.cb = (uint)Marshal.SizeOf<PROCESS_MEMORY_COUNTERS_EX>();

        long touchedMB = 0;

        for (long i = 0; i < SIZE; i++)
        {
            byte tmp = p[i]; // 実メモリアクセス

            if ((i & 0xFFFFF) == 0) // 1MBごと
            {
                GetProcessMemoryInfo(
                    hProcess,
                    out pmc,
                    (int)pmc.cb   // ★ 修正点
                );

                Console.WriteLine(
                    $"Touched {touchedMB,4} MB | WS {(pmc.WorkingSetSize >> 20),4} MB | PF {pmc.PageFaultCount}"
                );

                touchedMB++;

                if (USE_SLEEP)
                    Thread.Sleep(1);
            }
        }
    }
}
