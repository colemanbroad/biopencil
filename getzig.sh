cd ~/Desktop/software-thirdparty/
wget https://ziglang.org/download/0.10.0/zig-macos-aarch64-0.10.0.tar.xz
xz -d zig-macos-aarch64-0.10.0.tar.xz
tar -xvf zig-macos-aarch64-0.10.0.tar
cd ~/bin
ln -sf ~/Desktop/software-thirdparty/zig-macos-aarch64-0.10.0/zig 


cd ~/Desktop/software-thirdparty/
wget https://ziglang.org/builds/zig-macos-aarch64-0.11.0-dev.971+19056cb68.tar.xz
xz -d zig-macos-aarch64-0.11.0-dev.971+19056cb68.tar.xz
tar -xvf zig-macos-aarch64-0.11.0-dev.971+19056cb68.tar
cd ~/bin
ln -sf ~/Desktop/software-thirdparty/zig-macos-aarch64-0.11.0-dev.971+19056cb68/zig zig11
