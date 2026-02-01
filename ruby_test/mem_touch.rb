size_mb = 512
page = 4096

buf = "\x00" * (size_mb * 1024 * 1024)

touched = 0
(0...buf.bytesize).step(page) do |i|
  buf.setbyte(i, 1)
  touched += page

  if touched % (10 * 1024 * 1024) == 0
    puts "Touched #{touched / 1024 / 1024} MB"
  end
end

sleep
