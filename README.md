# dls2-barebone

This repository provides a reusable, buildable base for DLS2 robot control applications. It brings together the DLS2 framework, the Robotlib robot interface, robot-specific glue code, RViz visualization support, and a ROS 2 interface for shared message definitions and network settings.

## Repository Structure

| Component | Path | Description |
|-----------|------|-------------|
| **DLS2 Framework** | `dls2/` | Core control middleware. Contains modules for control, state estimation, messaging (DDS/IDL), plugins, tasks, state machines, signal handling, logging, and utilities. |
| **Robotlib** | `robotlib/` | Generic C++ robot abstraction layer. Provides a common API (kinematics, dynamics, Jacobians, data structures) that controllers target, independent of any specific robot morphology. Uses a factory pattern with `dlopen` for runtime-loadable robot libraries. |
| **GlueCode** | `gluecode/` | Robot-specific implementation of the Robotlib interface based on Pinocchio. Loaded at runtime as a shared library. |
| **RViz Interface** | `visualizers/rviz_interface/` | Visualization support for RViz. |
| **ROS 2 Interface** | `dls2_ros2_interface/` | Bidirectional message bridge between DLS2 IDL definitions and ROS 2 `.msg` types. Provides tooling to convert `.idl` ↔ `.msg` and scripts to configure FastDDS discovery so ROS 2 and DLS2 communicate over the same DDS domain. |


## Building

```bash
mkdir build && cd build
cmake ..
make
```

## Documentation: TODO


## Docker image

- Docker image `ghcr.io/iit-dlslab/dls2-dev:latest` 
