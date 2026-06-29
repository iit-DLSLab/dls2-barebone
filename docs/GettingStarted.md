# Getting started
In order to install the DLS2 framework, please follow the \ref installation instruction of the dls2-barebone repo.

## Launch DLS2 with manual steps
With the manual procedure you need to specify a set of layers that you want to launch and then you can load applications through the console. By **loading** you are actually **launching at run-time** your node.

To launch a layer you can use the command

    dls -l<layer_name>

So in T1 you can launch

    dls --servers --super -lcontrol -lhardware -lestimation -llog -raliengo

%This command is launching the layers control, hardware, estimation and log. It is also specifying the robot name with the _-r_ option and it is launching the _supervisor_ with _--super_. The option _--servers_ is instead launching DDS servers to be able to discover nodes in the network and it is a necessary command. If you want to launch the _control_ layer you also have to specify the robot name. Moreover, if you don't launch the log layer you cannot see most of the info, warning and error messages.

You can now attach another terminal (T2) to the docker image and you can launch the console layer

    dls -lconsole

Once the console is ready, console commands can be executed to load and run your applications. By tabbing in the console (T2) you can see the list of commands that are available.

All the commands that starts with _load_, load at run-time the shared libraries of the nodes: for each node it is launched a process that goes in the _idle_ state(see \ref app_state_machine), which means that the process is in a sleeping state and it is ready to be activated. The only exception is _loadModel_ which launches gazebo plugins that does not follow the state machine. The _<owner_name>::activate_ commands are used instead to move the nodes to the _activation_ state.

_loadModel aliengo 0.4_ is setting the desired spawning height to 0.4m.

If for any reason the DLS2 framwork does not close when shutting it down, you can kill the framework by launching this command into another terminal (inside the docker image)
    
    dls --kill

<br>

Different layers can be run in different terminals too. For example, if you have 4 terminals T1, T2, T3 and T4, in each of them you can run the following commands

In T1

    dls --servers

In T2

    dls --super -lhardware

In T3

    dls -lcontrol -llog -raliengo

In T4

    dls -lconsole

## Startup routine
Let's now look at the startup routine that saves a lot of your precious time.

In _dls2/modules/main/src/default_startup.yaml_ it is already defined a set of layers and nodes that you can run inside the image. To do that just launch in T1

    dls --startup

To start interacting with the DLS2 network, you can now launch the console layer. You can do that by attaching another terminal (T2) to the docker image and then launching the command

    dls -lconsole

At this point you are now ready to start sending commands to the DLS2 network through the console.

You can also customize the set of nodes you want to launch by creating your yaml file. To do that the yaml file has to contain the following structure
```
    # layers
    layers: []

    # applications
    hardwares: []
    controllers: []
    motion_generators: []
    estimators: []
    python_periodic_apps: []
    generic_app_plugins: []
    generic_periodic_app_plugins: []

    # robot name
    robot_name: ""
    robot_spawning_height: 0.1

    # applications to be activated
    activate: []
```

As you can see, you need to list the sets you want to run and the robot name.

To launch your configuration file, you need to pass its path to the startup command

    dls --startup=<path_to_your_startup.yml>/startup.yml

The supervisor and the DDS servers are automatically launched when using the startup procedure.

## Mixed routine
To launch the DLS2 network you could also use a mixed approach: load some layers and nodes with the startup routine and others with the manual steps.