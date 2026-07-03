#!/bin/bash

clear
sudo rm -r ./build/*
cd build
cmake ..
make -j14
cd ..
