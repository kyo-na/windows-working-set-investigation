use std::ptr::null_mut;
use std::thread::sleep;
use std::time::Duration;

use windows::Win32::System::Memory::*;
use windows::Win32::System::ProcessStatus::*;
use windows::Win32::System::Threading::*;

/// Working Set / PageFault のスナップショット
#[derive(Clone, Copy)]
struct MemSnapshot {
    ws_mb: u64,
    pf: u64,
}

/// 現在の Working Set / PageFault を取得
fn capture_memory() -> MemSnapshot {
    unsafe {
        let mut pmc = PROCESS_MEMORY_COUNTERS_EX::default();

        let _ = GetProcessMemoryInfo(
            GetCurrentProcess(),
            &mut pmc as *mut _ as *mut PROCESS_MEMORY_COUNTERS,
            std::mem::size_of::<PROCESS_MEMORY_COUNTERS_EX>() as u32,
        );

        MemSnapshot {
            ws_mb: (pmc.WorkingSetSize / (1024 * 1024)) as u64,
            pf: pmc.PageFaultCount as u64,
        }
    }
}

/// Sequential アクセス（1 byte ずつ）
/// Delphi の ASM / C の for(i++) と同じ
fn touch_sequential(buf: *mut u8, size: usize, use_sleep: bool) {
    unsafe {
        let mut i = 0usize;
        while i < size {
            // volatile read（最適化回避）
            std::ptr::read_volatile(buf.add(i));

            // 1MB ごとに WS / PF を観測（Delphi の Timer 相当）
            if (i & 0xFFFFF) == 0 {
                let m = capture_memory();
                println!(
                    "Touched {:>4} MB | WS {:>4} MB | PF {}",
                    i / (1024 * 1024),
                    m.ws_mb,
                    m.pf
                );
            }

            // 4KB (=1ページ) ごとに Sleep
            if use_sleep && (i & 0xFFF) == 0 {
                sleep(Duration::from_millis(1));
            }

            i += 1;
        }
    }
}

/// Page Stride アクセス（4KB ごと）
fn touch_stride(buf: *mut u8, size: usize, use_sleep: bool) {
    unsafe {
        let mut offset = 0usize;
        while offset < size {
            std::ptr::read_volatile(buf.add(offset));

            if (offset & 0xFFFFF) == 0 {
                let m = capture_memory();
                println!(
                    "Stride {:>4} MB | WS {:>4} MB | PF {}",
                    offset / (1024 * 1024),
                    m.ws_mb,
                    m.pf
                );
            }

            if use_sleep {
                sleep(Duration::from_millis(1));
            }

            offset += 4096;
        }
    }
}

fn main() {
    const SIZE: usize = 512 * 1024 * 1024; // 512MB（重ければ 128MB にしてOK）

    unsafe {
        // === VirtualAlloc（Delphi / C と同じ）===
        let buf = VirtualAlloc(
            None,
            SIZE,
            MEM_COMMIT,
            PAGE_READWRITE,
        ) as *mut u8;

        if buf.is_null() {
            panic!("VirtualAlloc failed");
        }

        // 開始時の WS
        let start = capture_memory();
        println!("Start WS: {} MB | PF {}", start.ws_mb, start.pf);

        println!("--- Touch Start ---");

        // ===== ここを切り替える =====

        // ① 一気に触る（WS 昇格しにくい）
        // touch_sequential(buf, SIZE, false);

        // ② 時間を与える（WS 昇格）
        touch_sequential(buf, SIZE, true);

        // ③ Prefetch を潰す
        // touch_stride(buf, SIZE, true);

        // ============================

        println!("--- Touch End ---");

        let after = capture_memory();
        println!(
            "After Touch WS: {} MB | PF delta {}",
            after.ws_mb,
            after.pf - start.pf
        );

        // 解放
        let _ = VirtualFree(buf as _, 0, MEM_RELEASE);

        sleep(Duration::from_secs(1));

        let final_m = capture_memory();
        println!("After Free WS: {} MB", final_m.ws_mb);
    }
}
