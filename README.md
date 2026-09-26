# Fibonacci in a ton of languages.
**Please note** that the benchmark scores you see are on a highly optimized setup with the following:
- 1TB Gen 4 NVME SSD with DRAM cache
- (Kind of) Fast CPU (Ryzen 7 3800x)
- Linux 7

**BEFORE TRYING TO MODIFY**: Half this code is nearly unreadable so I'd be careful if I were you.

Your results may vary.

## Currently supported languages (more will be added):
| **Language** | **Speed (~GB/s)**        | **Build Command**                                   |
|--------------|--------------------------|-----------------------------------------------------|
| Zig          | 3.65 **\*\***            | zig build-exe main.zig -O ReleaseFast --name fib    |
| Assembly     | 3.2                      | make                                                |
| Fortran      | 3.2                      | make                                                |
| C            | 2.3                      | gcc -O3 -march=native main.c -o fib -lgmp -lpthread |
| Lua          | 2                        | luajit fib.lua                                      |
| Rust         | 1.7                      | cargo run --release                                 |
| C++          | 1.7                      | g++ -O3 main.cpp -o fib -lgmpxx -lgmp -pthread      |
| Haskell      | 1.4                      | make                                                |
| C#           | 1.4                      | dotnet build                                        |
| Python       | 1                        | python3 fib.py                                      |
| BrainF       | 0.5 **\***               | make                                                |
| Kotlin       | 0.4                      | kotlinc Fib.kt -include-runtime -d Fib.jar          |
| Java         | 0.4                      | javac Fib.java                                      |
| Ruby         | 0.4                      | ruby --yjit fib.rb                                  |
| JS (node)    | 0.03 (30MB/s) **\*\*\*** | node main.js                                        |
| TypeScript   | 0.03 (30MB/s) **\*\*\*** | node main.ts                                        |
| JS (web)     | 0.006 (6MB/s) **\*\*\*** | python3 -m http.server 8000                         |

\*  This is repeating values from 0-255 and does not reflect real-world results.  
\*\* This only supports a very specific version of Zig. Possible optimizations in newer versions will not be added.  
\*\*\* JS/TS is designed for thousands of asynchronous actions, not one monolithic thread running heavy math and file operations.

## Languages in progress:
- Shakespeare Programming Language

## Priority future languages:
- Go
- Swift
- Perl

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
- INTERCAL
- Chef
- Regex

## Not Planned
- CSS

## Licensing:
This code is licensed under the MIT License.
