// buffer.js
const sizeMB = 800; // 800MB
const buf = Buffer.alloc(sizeMB * 1024 * 1024);

console.log("buffer allocated");

for (let i = 0; i < buf.length; i += 4096) {
  buf[i] = 1;
}

console.log("buffer touched");
setTimeout(() => {}, 10 * 60 * 1000);
