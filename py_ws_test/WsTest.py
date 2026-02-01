import ctypes
import time
import psutil
import os

SIZE = 512 * 1024 * 1024  # 512MB
PAGE = 4096
USE_SLEEP = True

# プロセス情報
proc = psutil.Process(os.getpid())

print("PID:", proc.pid)

# バッファ確保（Python流）
buf = bytearray(SIZE)

touched_mb = 0

for i in range(0, SIZE, PAGE):
    buf[i] = 1  # touch

    if (i & 0xFFFFF) == 0:  # 1MB
        mem = proc.memory_info()
        ws_mb = mem.rss >> 20
        pf = proc.num_page_faults() if hasattr(proc, "num_page_faults") else -1

        print(
            f"Touched {touched_mb:4d} MB | WS {ws_mb:4d} MB | PF {pf}"
        )

        touched_mb += 1

        if USE_SLEEP:
            time.sleep(0.001)
