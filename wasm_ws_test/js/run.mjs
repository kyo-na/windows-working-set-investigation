import fs from "fs";

const wasm = new WebAssembly.Module(
  fs.readFileSync("wasm/mem.wasm")
);
const instance = new WebAssembly.Instance(wasm, {});
const { memory, grow, touch } = instance.exports;

const MB = 1024 * 1024;
const PAGES_PER_MB = 16;
const TOTAL_MB = 512;

console.log("Start");

for (let mb = 1; mb <= TOTAL_MB; mb++) {
  const ret = grow(PAGES_PER_MB);

  if (ret === -1) {
    console.log(`GROW FAILED at ${mb} MB`);
    break;
  }

  touch((mb - 1) * MB);
  console.log(`Touched ${mb} MB`);
}

console.log("Done");
