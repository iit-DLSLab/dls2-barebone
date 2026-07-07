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
## Pull the docker image
You can pull the docker image with the following command:

```bash
docker pull ghcr.io/iit-dlslab/dls2-dev:latest
```

## Clone repository
```bash
mkdir dls_ws
cd dls_ws
git clone --recursive https://github.com/iit-DLSLab/dls2-barebone.git
```
## Open docker image
```bash
docker run -it --rm \
  --name dls_container \
  --hostname docker \
  --gpus all \
  --privileged \
  --network host \
  -e DISPLAY="$DISPLAY" \
  -e DLS=2 \
  -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
  -v "$PWD:$PWD" \
  -w "$PWD" \
  ghcr.io/iit-dlslab/dls2-dev:latest \
  /bin/bash
```
Remember that to attach another terminal to the already running container you can do

```bash
docker exec -it dls_container /bin/bash
```

## Build
```bash
cd dls2-barebone
mkdir build && cd build
cmake ..
make
sudo make install
```
The first compilation takes a bit of time because it needs to compile all the messages (the ROS2 default ones and the DLS2 ones).

# Run example
To run a simple node example follow these steps:

* open a shell, run the container and build the code as explained in the "Open docker image" and "Build" sections above.
* Run the fastdds servers and the supervisor

  ```bash
  dls --servers --super
  ```
* open a second terminal, launch the console:
  ```bash
  docker exec -it dls_container /bin/bash
  ```
  ```bash
  dls -lconsole
  ```
* load the `hello_world_plugin`
  ```bash
  Supervisor::loadPeriodicAppPlugin hello_world_plugin
  ```
  and activate the plugin typing: 
  ```bash
  hello_world_plugin::activate
  ```

  You will see a dummy print in the terminal where you have launched the Supervisor.
* unload the `hello_world_plugin`
  ```bash
  Supervisor::unloadPeriodicAppPlugin hello_world_plugin
  ```
* stop DLS2 with `CTRL-C` in any of the terminal

# Contributing
Feel free to open issues and/or PRs!

# TODOs:
* Integrated and ready-to-go examples with state estimator ([MUSE](https://github.com/iit-DLSLab/muse)) coming soon

# Mantainers
This repository is mantained by [Marco Marchitto](https://github.com/MMarcus95) and [Michele Pestarino](https://github.com/mich-pest).