# Examples of Using CUDA with Zig

![build](https://github.com/mm318/cudaz/actions/workflows/test.yml/badge.svg)

There are two approaches presented in the examples.

One example uses `nvcc` to compile the kernel into an object file and statically linked into the final executable.

The other example embeds the kernel source code into the executable and uses `nvrtc` to compile it at run-time.

## Usage

### Installation

#### Install CUDA (Ubuntu)

Run `nvidia-smi` and note the `Driver Version` and `CUDA Version`.

For your CUDA version, install the local repository (this way you may install the specific version of CUDA
on a version of Ubuntu that it's not officially released for):
```
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-ubuntu2204.pin
sudo mv cuda-ubuntu2204.pin /etc/apt/preferences.d/cuda-repository-pin-600
wget https://developer.download.nvidia.com/compute/cuda/12.4.0/local_installers/cuda-repo-ubuntu2204-12-4-local_12.4.0-550.54.14-1_amd64.deb
sudo dpkg -i cuda-repo-ubuntu2204-12-4-local_12.4.0-550.54.14-1_amd64.deb
sudo cp /var/cuda-repo-ubuntu2204-12-4-local/cuda-*-keyring.gpg /usr/share/keyrings/
sudo apt-get update
sudo apt install cuda-nvrtc-dev-12-4
sudo apt install cuda-nvcc-12-4
sudo apt install libnvidia-compute-550  # based on "Driver Version"
```

#### Install cudaz

```bash
git clone https://github.com/mm318/cudaz.git
```

### Build

All commands should be run from the newly cloned `cudaz` directory.

To build:
```bash
cd cudaz/example/
zig build                           # for debug build
zig build -Doptimize=ReleaseSafe    # for release build
```

### To Run Examples

There are build targets added to conveniently run the examples.
Similarly, all commands should be run from the cloned `cudaz` directory.

```bash
cd cudaz/example/
zig build -Doptimize=ReleaseSafe run           # to run the nvrtc example
zig build -Doptimize=ReleaseSafe run_static    # to run the nvcc example
```

Tested on Ubuntu 24.04 using zig 0.14.1.
