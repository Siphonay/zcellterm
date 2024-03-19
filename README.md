# zcellterm
CLI toy, Zig implementation of the Wolfram Elementary Cellular Automaton, with various customization features
Inspired by the [Coding Train](https://www.youtube.com/watch?v=Ggxt06qSAe4) video on the subject.

## Demo
![zcellterm demo, made with asciinema](https://demiboy.online/zcellterm_demo.gif)

## Features
* Call any of the 256 rules of the Elementary Cellular Automaton
* Automatic terminal size detection, manual size setting, infinite mode
* Pre-computation of a specified number of generations before display
* Per-line display delay
* Start with only one active cell in the middle of the automaton, or specify a custom or random starting condition

## Supported platforms for automatic terminal size detection
### Tested
* Linux
* macOS
* Windows
* FreeBSD
* OpenBSD
### Untested, [works in theory](https://ziglang.org/documentation/master/std/#A;std?.T.IOCGWINS) if you can build for those platforms (might be non-trivial)
* NetBSD
* Haiku
* Solaris

Know how to implement size detection for a platform not listed here? Feel free to contribute!

## Build
```
zig build
```
Use the master Zig version, or if you have Zig 0.11.0, switch to the 1.0.0-zig0.11.0 branch. Feel free to use optimization flags.

## Thanks
I’m using [zig-clap](https://github.com/Hejsil/zig-clap) library to parse arguments.

Thank you [@AliceDiNunno](https://github.com/AliceDiNunno) for testing out macOS compatibility, as well as all the nice people on the [Zig Programming Language Discord server](https://discord.gg/zig) who gave me their help and feedback.

I was able to improve the terminal size detection for Windows by taking example on [softprops’ implementation](https://github.com/softprops/zig-termsize).