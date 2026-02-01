// typed_array.js
const sizeMB = 1024; // 1GB
const arr = new Uint8Array(sizeMB * 1024 * 1024);

console.log("typed array allocated");

for (let i = 0; i < arr.length; i += 4096) {
  arr[i] = 1;
}

console.log("typed array touched");
setTimeout(() => {}, 10 * 60 * 1000);
