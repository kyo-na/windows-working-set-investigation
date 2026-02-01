package main

import (
	"fmt"
	"unsafe"

	"golang.org/x/sys/windows"
)

const (
	MEM_COMMIT     = 0x1000
	MEM_RESERVE    = 0x2000
	PAGE_READWRITE = 0x04
)

type PROCESS_MEMORY_COUNTERS_EX struct {
	Cb                         uint32
	PageFaultCount             uint32
	PeakWorkingSetSize         uintptr
	WorkingSetSize             uintptr
	QuotaPeakPagedPoolUsage    uintptr
	QuotaPagedPoolUsage        uintptr
	QuotaPeakNonPagedPoolUsage uintptr
	QuotaNonPagedPoolUsage     uintptr
	PagefileUsage              uintptr
	PeakPagefileUsage          uintptr
	PrivateUsage               uintptr
}

var (
	kernel32 = windows.NewLazySystemDLL("kernel32.dll")
	psapi    = windows.NewLazySystemDLL("psapi.dll")

	procVirtualAlloc         = kernel32.NewProc("VirtualAlloc")
	procSleep                = kernel32.NewProc("Sleep")
	procGetProcessMemoryInfo = psapi.NewProc("GetProcessMemoryInfo")
)

func main() {

	const SIZE = 512 * 1024 * 1024 // 512MB
	const PAGE = 4096

	// --- VirtualAlloc
	addr, _, err := procVirtualAlloc.Call(
		0,
		uintptr(SIZE),
		MEM_COMMIT|MEM_RESERVE,
		PAGE_READWRITE,
	)
	if addr == 0 {
		panic(err)
	}

	buf := unsafe.Slice((*byte)(unsafe.Pointer(addr)), SIZE)

	var pmc PROCESS_MEMORY_COUNTERS_EX
	pmc.Cb = uint32(unsafe.Sizeof(pmc))

	hProcess := windows.CurrentProcess()

	// =========================
	// 1st pass: 一気に触る
	// =========================
	for i := 0; i < SIZE; i += PAGE {
		_ = buf[i]
	}

	fmt.Println("---- 1st pass done ----")

	// =========================
	// 2nd pass: 時間をかけて再タッチ
	// =========================
	touchedMB := 0

	for i := 0; i < SIZE; i += PAGE {

		buf[i]++ // ★ 読み + 書き（最重要）

		if (i & 0xFFFFF) == 0 {

			r, _, _ := procGetProcessMemoryInfo.Call(
				uintptr(hProcess),
				uintptr(unsafe.Pointer(&pmc)),
				uintptr(pmc.Cb),
			)
			if r == 0 {
				panic("GetProcessMemoryInfo failed")
			}

			ws := pmc.WorkingSetSize >> 20
			pf := pmc.PageFaultCount

			fmt.Printf(
				"Touched %4d MB | WS %4d MB | PF %d\n",
				touchedMB, ws, pf,
			)

			touchedMB++
			procSleep.Call(1)
		}
	}

	// 最適化・GC抑止
	runtimeKeepAlive(buf)
}

// ★ GC / 最適化抑止（Delphi / C / Rust と条件を揃える）
func runtimeKeepAlive(v any) {
	_ = v
}
