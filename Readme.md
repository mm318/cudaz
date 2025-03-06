# Examples of Using CUDA with Zig

![build](https://github.com/mm318/cudaz/actions/workflows/test.yml/badge.svg)

There are two approaches presented in the examples.

One example uses `nvcc` to compile the kernel into an object file and statically linked into the final executable.

The other example embeds the kernel source code into the executable and uses `nvrtc` to compile it at run-time.

## Usage

### Installation
```bash
git clone https://github.com/mm318/cudaz.git
```

### Build

All commands should be run from the newly cloned `cudaz` directory.

To build:
```bash
zig build                           # for debug build
zig build -Doptimize=ReleaseSafe    # for release build
```

### To Run Examples

There are build targets added to conveniently run the examples.
Similarly, all commands should be run from the cloned `cudaz` directory.

```bash
zig build -Doptimize=ReleaseSafe run           # to run the nvrtc example
zig build -Doptimize=ReleaseSafe run_static    # to run the nvcc example
```

Tested on Ubuntu 20.04 using zig 0.14.0.
