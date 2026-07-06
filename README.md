# dls2-barebone
This repository contains the official implementation of _D. Wildgrube Bertol, G. Fink, M. Marchitto, Y. Nisticò, M. Pestarino, and C. Semini, “DLS2: A distributed microcomponent-based robotic software architecture”_, which is currently under review.

It provides a reusable, buildable base for DLS2 robot control applications. It brings together the DLS2 framework, the Robotlib robot interface, the pinocchio-gluecode, RViz visualization support, and a ROS 2 interface for shared message definitions and network settings.

# Project Status
This project is currently in **pre-release** and under active development.

[![Build Test](https://github.com/iit-DLSLab/dls2-barebone/actions/workflows/build_test.yml/badge.svg)](https://github.com/iit-DLSLab/dls2-barebone/actions/workflows/build_test.yml)

# Repository Structure

| Component | Path | Description |
|-----------|------|-------------|
| **DLS2 Framework** | `dls2/` | Core control middleware. Contains modules for control, state estimation, messaging (DDS/IDL), plugins, state machines, signal handling, logging, and utilities. |
| **Robotlib** | `robotlib/` | Generic C++ robot abstraction layer. Provides a common API (kinematics, dynamics, Jacobians, data structures) that controllers target, independent of any specific robot morphology. Uses a factory pattern with `dlopen` for runtime-loadable robot libraries. |
| **GlueCode** | `pinocchio-gluecode/` | Robot-specific implementation of the Robotlib interface based on Pinocchio. Loaded at runtime as a shared library. |
| **RViz Interface** | `visualizers/rviz_interface/` | Visualization support for RViz. |
| **ROS 2 Interface** | `dls2_ros2_interface/` | Bidirectional message bridge between DLS2 IDL definitions and ROS 2 `.msg` types. Provides tooling to convert `.idl` ↔ `.msg` and scripts to configure FastDDS discovery so ROS 2 and DLS2 communicate over the same DDS domain. |

# Documentation
To generate the documentation:

```bash
cd dls2-barebone
doxygen docs/Doxifile
```
To open the documentation double click on the file build/html/index.html.

# Installation
## Pull or build docker image
You can either pull the docker image `ghcr.io/iit-dlslab/dls2-dev:latest` or you can build it from scratch.
### Pulling

```docker pull ghcr.io/iit-dlslab/dls2-dev:latest```

### Building - TODO

## Clone repository
```bash
git clone --recursive https://github.com/iit-DLSLab/dls2-barebone.git
cd dls2-barebone
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
The first compilation takes a bit of time because it needs to compile all the messages (the ROS2 default ones and the DLS2 ones).

# Run example - TODO
To run an example, you can have a look at this repo, where a ready-to-use framework is provided for quadruped locomotion.

# Contributing
Feel free to open issues and/or PRs!