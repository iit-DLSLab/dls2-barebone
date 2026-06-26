# dls2-barebone

This repository provides a reusable, buildable base for DLS2 robot control applications. It brings together the DLS2 framework, the Robotlib robot interface, robot-specific glue code, RViz visualization support, and a ROS 2 interface for shared message definitions and network settings.

# Documentation - TODO

# Installation
## Pull or build docker image
You can either pull the docker image `ghcr.io/iit-dlslab/dls2-dev:latest` or you can build it from scratch.
### Pulling

```docker pull ghcr.io/iit-dlslab/dls2-dev:latest```

### Building - TODO

## Clone repository
```bash
git clone https://github.com/iit-DLSLab/dls2-barebone.git
cd dls2-barebone
git submodule update --init --recursive
```
## Open docker image - TODO
```bash
docker run
cd dls2-barebone
```
## Build
```bash
mkdir build && cd build
cmake ..
make
sudo make install
```
# Run example - TODO

# Contributing
Feel free to open issues and/or PRs!

## Repository Structure

| Component | Path | Description |
|-----------|------|-------------|
| **DLS2 Framework** | `dls2/` | Core control middleware. Contains modules for control, state estimation, messaging (DDS/IDL), plugins, tasks, state machines, signal handling, logging, and utilities. |
| **Robotlib** | `robotlib/` | Generic C++ robot abstraction layer. Provides a common API (kinematics, dynamics, Jacobians, data structures) that controllers target, independent of any specific robot morphology. Uses a factory pattern with `dlopen` for runtime-loadable robot libraries. |
| **GlueCode** | `gluecode/` | Robot-specific implementation of the Robotlib interface based on Pinocchio. Loaded at runtime as a shared library. |
| **RViz Interface** | `visualizers/rviz_interface/` | Visualization support for RViz. |
| **ROS 2 Interface** | `dls2_ros2_interface/` | Bidirectional message bridge between DLS2 IDL definitions and ROS 2 `.msg` types. Provides tooling to convert `.idl` ↔ `.msg` and scripts to configure FastDDS discovery so ROS 2 and DLS2 communicate over the same DDS domain. |