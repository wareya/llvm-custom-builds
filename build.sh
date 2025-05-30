#!/bin/bash

# Display all commands before executing them.
set -o errexit
set -o errtrace

LLVM_VERSION=$1
LLVM_REPO_URL=${2:-https://github.com/llvm/llvm-project.git}
LLVM_CROSS="$3"

if [[ -z "$LLVM_REPO_URL" || -z "$LLVM_VERSION" ]]
then
  echo "Usage: $0 <llvm-version> <llvm-repository-url> [aarch64/riscv64]"
  echo
  echo "# Arguments"
  echo "  llvm-version         The name of a LLVM release branch without the 'release/' prefix"
  echo "  llvm-repository-url  The URL used to clone LLVM sources (default: https://github.com/llvm/llvm-project.git)"
  echo "  aarch64 / riscv64    To cross-compile an aarch64/riscv64 version of LLVM"

  exit 1
fi

# Shallow clone the LLVM project.
if [ ! -d llvm-project ]; then
  git clone --depth 1 --branch "release/$LLVM_VERSION" "$LLVM_REPO_URL" llvm-project
fi
cd llvm-project

# Create a directory to build the project.
mkdir -p build
cd build

# Create a directory to receive the complete installation.
mkdir -p install

# Adjust compilation based on the OS.
CMAKE_ARGUMENTS=""

case "${OSTYPE}" in
    darwin*) ;;
    linux*) ;;
    *) ;;
esac

# Adjust cross compilation
CROSS_COMPILE=""

case "${LLVM_CROSS}" in
    aarch64*) CROSS_COMPILE="-DLLVM_HOST_TRIPLE=aarch64-linux-gnu" ;;
    riscv64*) CROSS_COMPILE="-DLLVM_HOST_TRIPLE=riscv64-linux-gnu" ;;
    *) ;;
esac

# Run `cmake` to configure the project.
cmake \
  -G Ninja \
  -DCMAKE_BUILD_TYPE=MinSizeRel \
  -DCMAKE_INSTALL_PREFIX="destdir" \
  -DLLVM_ENABLE_PROJECTS="clang;lld;lldb" \
  -DLLVM_ENABLE_TERMINFO=OFF \
  -DLLVM_ENABLE_ZLIB=OFF \
  -DLLVM_INCLUDE_DOCS=OFF \
  -DLLVM_INCLUDE_EXAMPLES=OFF \
  -DLLVM_INCLUDE_GO_TESTS=OFF \
  -DLLVM_INCLUDE_TESTS=OFF \
  -DLLVM_INCLUDE_TOOLS=ON \
  -DLLVM_INCLUDE_UTILS=OFF \
  -DLLVM_OPTIMIZED_TABLEGEN=OFF \
  -DLLVM_ENABLE_RUNTIMES=all \
  "${CROSS_COMPILE}" \
  "${CMAKE_ARGUMENTS}" \
  ../llvm

# Showtime!
cmake --build . --config Release
cmake --install . --strip --config Release
