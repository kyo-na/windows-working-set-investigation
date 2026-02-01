const addon = require('./addon/build/Release/addon');

console.log("native touch start");
addon.touch();
console.log("native touch done");

setTimeout(() => {}, 10 * 60 * 1000);
