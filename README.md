# Fibonacci in a ton of languages.
**Please note** that the benchmark scores you see are on a highly optimized setup with the following:
- 1TB Gen 4 NVME SSD with DRAM cache
- (Kind of) Fast CPU (Ryzen 7 3800x)
- Linux 7

**BEFORE TRYING TO MODIFY**: Half this code is nearly unreadable so I'd be careful if I were you.

Your results may vary.

## Currently supported languages (more will be added):
| **Language** | **Speed (~GB/s)** | **Build Command**                                   |
|--------------|-------------------|-----------------------------------------------------|
| Python       | 1                 | python3 fib.py                                      |
| Rust         | 1.7               | cargo run --release                                 |
| C++          | 1.7               | g++ -O3 main.cpp -o fib -lgmpxx -lgmp -pthread      |
| C#           | 1.4               | dotnet build                                        |
| C            | 2.3               | gcc -O3 -march=native main.c -o fib -lgmp -lpthread |
| Assembly     | 3.2               | make                                                |
| BrainF       | 0.5 **\***        | make                                                |
| Lua          | 2                 | luajit fib.lua                                      |
| Ruby         | 0.4               | ruby --yjit fib.rb                                  |
| Zig          | 3.65 **\*\***     | zig build-exe main.zig -O ReleaseFast --name fib    |
| Fortran      | 3.2               | make                                                |
| Java         | 0.4               | javac Fib.java                                      |

\*  This is repeating values from 0-255 and does not reflect real-world results.  
\*\* This only supports a very specific version of Zig. Possible optimizations in newer versions will not be added.

## Languages in progress:
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
