# zcellterm
Zig CLI implementation of the Wolfram Elementary Cellular Automaton
Inspired by the [Coding Train](https://www.youtube.com/watch?v=Ggxt06qSAe4) video on the subject

## Build
```
zig build
```
Should build on Zig 0.11.0 and up. Open an issue if not. Feel free to use optimization flags

## Usage
```
usage: zcellterm <rule>
rule should be a nubmer between 0 and 255.
```

## Supported platforms for automatic terminal size
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

## TODO
* Let user specify size while using term size by default (only using term size atm)
* Infinite scrolling mode
* Let user choose to have a random starting generation
* Let user start at a specific generation

## Thanks
Thank you @AliceDiNunno for testing out macOS compatibility, as well as Hestia and FelixLeTrain on the [Zig Programming Language Discord server](https://discord.gg/zig) for their feedback

I was able to improve the terminal size detection for Windows by taking example on [softprops’ implementation](https://github.com/softprops/zig-termsize)