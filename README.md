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

## 📁 ディレクトリ一覧

