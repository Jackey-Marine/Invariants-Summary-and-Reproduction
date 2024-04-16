# SAVIOR

This repository contains the implementation of SAVIOR on an aerial and ground vehicle. Each folder contains the specific files needed for each vehicle. On the aerial vehicles, the main controller is PX4 while on the ground vehicle the main controller is ROS Kinetic Kame.

此存储库包含 SAVIOR 在Copter和Rover的实现。每个文件夹包含每辆车所需的特定文件。在Copter中，主控制器为 PX4；在Rover中，主控制器为 ROS Kame。

## Getting Started

### Clone Repo

```bash
# Copter
cd Copter
git clone https://github.com/RaulQT/Firmware
git submodule update --init --recursive

# Rover
cd Rover
git clone https://github.com/RaulQT/como
git submodule update --init --recursive
```

### Following the Tutorial.md
