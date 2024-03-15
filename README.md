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

## TODO
* Let user specify size while using term size by default (only using term size atm)
* Implement other platforms than Windows and Linux (please contribute!)
* Infinite scrolling mode
* Let user choose to have a random starting generation
* Let user start at a specific generation