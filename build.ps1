$LLVM_VERSION = $args[0]
$LLVM_REPO_URL = $args[1]

if ([string]::IsNullOrEmpty($LLVM_REPO_URL)) {
    $LLVM_REPO_URL = "https://github.com/llvm/llvm-project.git"
}

if ([string]::IsNullOrEmpty($LLVM_VERSION)) {
    Write-Output "Usage: $PSCommandPath <llvm-version> <llvm-repository-url>"
    Write-Output ""
    Write-Output "# Arguments"
    Write-Output "  llvm-version         The name of a LLVM release branch without the 'release/' prefix"
    Write-Output "  llvm-repository-url  The URL used to clone LLVM sources (default: https://github.com/llvm/llvm-project.git)"

	exit 1
}

# Download and extract the LLVM release branch as a zipball using tar.
if (-not (Test-Path -Path "llvm-project" -PathType Container) ) {
    $zipUrl = "https://github.com/llvm/llvm-project/archive/refs/heads/release/$LLVM_VERSION.zip"
    $zipPath = "$env:TEMP\llvm-project.zip"

    Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath

    tar -xf $zipPath -C ./
    Rename-Item -Path "llvm-project-release-$LLVM_VERSION" -NewName "llvm-project"
}

Set-Location llvm-project

# Create a directory to build the project.
New-Item -Path "build" -Force -ItemType "directory"
Set-Location build

# Create a directory to receive the complete installation.
New-Item -Path "install" -Force -ItemType "directory"

# Adjust compilation based on the OS.
$CMAKE_ARGUMENTS = ""

# Adjust cross compilation
$CROSS_COMPILE = ""

# Run `cmake` to configure the project.
cmake `
  -DCMAKE_CXX_FLAGS="/utf-8" `
  -G "Visual Studio 17 2022" `
  -DCMAKE_BUILD_TYPE=MinSizeRel `
  -DCMAKE_INSTALL_PREFIX=destdir `
  -DLLVM_ENABLE_PROJECTS="clang;lld;lldb" `
  -DLLVM_ENABLE_TERMINFO=OFF `
  -DLLVM_ENABLE_ZLIB=OFF `
  -DLLVM_INCLUDE_DOCS=OFF `
  -DLLVM_INCLUDE_EXAMPLES=OFF `
  -DLLVM_INCLUDE_GO_TESTS=OFF `
  -DLLVM_INCLUDE_TESTS=OFF `
  -DLLVM_INCLUDE_TOOLS=ON `
  -DLLVM_INCLUDE_UTILS=OFF `
  -DLLVM_OPTIMIZED_TABLEGEN=ON `
  -DLLVM_ENABLE_RUNTIMES="libc;libcxxabi;pstl;libcxx;compiler-rt;openmp;llvm-libgcc;offload" `
  $CROSS_COMPILE `
  $CMAKE_ARGUMENTS `
  ../llvm

# Showtime!
cmake --build . --config Release --target llvm-nm -- /m
New-Item -ItemType Directory -Path "NATIVE/Release/bin" -Force | Out-Null
Copy-Item "Release/bin/llvm-nm.exe" "NATIVE/Release/bin/llvm-nm.exe" -ErrorAction SilentlyContinue
cmake --build . --config Release -- /m


# Not using DESTDIR here, quote from
# https://cmake.org/cmake/help/latest/envvar/DESTDIR.html
# > `DESTDIR` may not be used on Windows because installation prefix
# > usually contains a drive letter like in `C:/Program Files` which cannot
# > be prepended with some other prefix.
cmake --install . --strip --config Release
