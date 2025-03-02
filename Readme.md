# Examples of Using CUDA with Zig

There are two approaches presented in the examples.

One example uses `nvcc` to compile the kernel into an object file and statically linked into the final executable.

The other example embeds the kernel source code into the executable and uses `nvrtc` to compile it at run-time.

## Usage

### Installation
```bash
git clone https://github.com/mm318/cudaz.git
```

### Build
All commands should be run from the newly downloaded `cudaz` directory.

To build:
```bash
zig build run           # to run the nvrtc example
zig build run_static    # to run the nvcc example
```

(Currently, `zig` seems to have a bug where it passes `--no-as-needed .` to the linker resulting in a
`ld.lld: cannot open .: Is a directory` error.)
