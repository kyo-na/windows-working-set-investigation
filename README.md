# Windows Working Set 実測プロジェクト

このリポジトリは、Windows 11（特に 25H2）における
**Working Set / Page Fault の挙動**を
複数言語・複数ランタイムで比較検証するための実験コード集です。

---

## 🧠 検証目的

- OS のメモリ管理挙動を **定量的に観測する**
- 言語・実装差ではなく **OS ポリシーとしての挙動を理解する**
- 再現可能なコードを世界に公開する

---

## 🔍 検証条件

- OS: Windows 11 x64（23H2 / 24H2 / 25H2 など）
- メモリ確保量: 512MB〜1GB
- 観測指標: Working Set（WS） / Page Fault（PF）
- 言語: C / C++ / Delphi / Rust / Go / Java / C# / LuaJIT / JS / PyPy / etc.

---

## 関連記事
Windows 11 25H2 の Working Set 挙動を実測して分かったこと｜キョウスケ
https://note.com/kyona_blog/n/nd9eb4d2f671a

## 📁 ディレクトリ一覧
cpp_ws_test
cs_ws_test
Delphi_ws_test
go_ws_test
java_ws_test
lua_ws_test
nim_ws_test
py_ws_test
wasm_ws_test
zig_ws_test
mem_js
mem_pypy
