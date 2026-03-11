# Fibonacci in a ton of languages.
**Please note** that the benchmark scores you see are on a highly optimized setup with the following:
- 1TB Gen 4 NVME SSD with DRAM cache
- (Kind of) Fast CPU (Ryzen 7 3800x)
- The Linux Kernel (Includes dirty write paging)
- A short 5 second test to prevent cache exhaustion

**BEFORE TRYING TO MODIFY**: Half this code is nearly unreadable so I'd be careful if I were you. (The assembly only has humorous comments, so good luck reading that one.)

Your results may vary.

## Currently supported languages (more will be added):
- Python (~1GB/s) COMMAND: python3 fib.py
- Rust (~1.7GB/s) COMMAND: cargo run --release
- C++ (~1.7GB/s) COMMAND: g++ -O3 main.cpp -o fib -lgmpxx -lgmp -pthread
- C# (~1.4GB/s) COMMAND: dotnet build
- C (2.3GB/s) COMMAND: gcc -O3 -march=native main.c -o fib -lgmp -lpthread
- Assembly (3.2GB/s) COMMAND: make
- BrainF (0.5GB/s) COMMAND: make
- Lua (2GB/s) COMMAND: luajit fib.lua
- Ruby (0.4GB/s) COMMAND: ruby --yjit fib.rb
- Zig (3.5GB/s) COMMAND: zig build-exe main.zig -O ReleaseFast --name fib
- Fortran (3.2GB/s) COMMAND: make

## Languages in progress:
- Java
- Kotlin
- Haskell
- Go
- Swift
- Perl
- Javascript

## Languages for future implementation:
- Clojure
- Erlang
- Ada
- D
- Pascal
- OCaml
- Prolog
- F#
- Typescript
- PHP
- Tcl
- Verilog
- Nim
- Befunge
- Shakespeare Programming Language
- INTERCAL
- Chef
- CSS
- Regex

## Licensing:
This code is licensed under the MIT License.
