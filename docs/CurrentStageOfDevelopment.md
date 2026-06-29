# Current stage of development

The implementation of DLS2 is progressing incrementally, translating its architectural principles as distribution, real-time awareness, modularity, and platform independence, into operational software components. Development milestones are organized per architectural layer and subsystem, enabling iterative validation and controlled evolution. Each architectural element has been addressed through targeted development efforts, resulting in a system that is both operational and extensible.

The current implementation includes the following capabilities:

- **Distributed Node Architecture**: A node management subsystem abstracts each hardware unit as a node and supports dynamic application placement, coordinated lifecycle management, and comprehensive health monitoring at both the device and process levels, including execution status, real-time compliance, resource utilization, and data integrity and synchronization checks.
- **Omnipresent Layers**: Functional domains (Hardware, Control, Estimation, Console, Log) are instantiated on any capable node, with explicit classification into real-time (RT) or best-effort (BE) execution contexts.
- **Controller Layer**: Orchestrates multiple controllers, and aggregates control signals under deterministic scheduling constraints.
- **Distributed Supervisor**: Local automata embedded within processes (\eg drivers, estimators, controllers) compose global behavior, enabling safe initialization and controlled switching.
- **Containerization Runtime**: Packages applications with dependencies to ensure reproducible deployment across heterogeneous nodes and enable migration under policy constraints.
- **QoS-Aware Communication**: A DDS-class messaging substrate provides publish--subscribe and request--response semantics with configurable QoS, semantic domain segregation, and automatic discovery.
- **Real-Time Conformance Tooling**: Preliminary tooling validates configuration against RT policies (\eg latency budgets, jitter bounds, deadline miss ratios) and reports metrics to guide placement and scheduling.
- **Console and Logging**: Operator-facing tools provide diagnostics, structured logs, and runtime introspection of processes and topics.
- **Dynamic Discovery and Interoperability**: Nodes can join or leave with minimal reconfiguration; compatibility with ROS2 is fully supported, provided that the used middleware is FastDDS.
- **Plugin Architecture**: External libraries can be attached as plugins, promoting reuse and framework independence.


The current implementation of the DDS standard is based on **FastDDS**. From
an implementation standpoint, the vast majority of the framework’s features and tools are developed in C++. However, Python-based processes are also integrated through a dedicated binding that exploits the proposed plugin architecture. %This solution preserves real-time guarantees and ensures consistent node lifecycle management across programming languages, while enabling rapid prototyping and development by leveraging the extensive Python library ecosystem.