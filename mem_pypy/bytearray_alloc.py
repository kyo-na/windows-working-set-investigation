size_mb = 1024
buf = bytearray(size_mb * 1024 * 1024)

print("allocated")

for i in range(0, len(buf), 4096):
    buf[i] = 1

print("touched")
input("press enter")
