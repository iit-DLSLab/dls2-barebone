#include "periodic_app_plugins/RvizInterface/rviz_interface.hpp"

// topics
// Include the TypeSupport of each message associated to each topic
#include <dls_messages/dds/ros2_interface/sensor_msgs/msg/JointStatePubSubTypes.hpp>
#include <dls_messages/dds/ros2_interface/tf2_msgs/msg/TFMessagePubSubTypes.hpp>

#include "dls2/topics/topics.hpp"

#include "robotlib/robot_factory.hpp"

#include <yaml-cpp/yaml.h>

#include <filesystem>
#include <iostream>
#include <map>

namespace
{
    constexpr const char* kConfigPath = "/usr/include/dls2/periodic_app_plugins/rviz_interface/config/rviz_interface.yaml";

    // Installed config, or the source one when running from the build tree
    std::string configPath()
    {
        namespace fs = std::filesystem;
        if (fs::exists(kConfigPath)) {
            return kConfigPath;
        }
        const fs::path source_config =
            fs::path(__FILE__).parent_path().parent_path() / "config" / "rviz_interface.yaml";
        return fs::exists(source_config) ? source_config.string() : std::string{};
    }

    // type_hashes from the config: ROS type name -> "RIHS01_<64 hex>". Malformed ones are skipped.
    std::map<std::string, std::string> loadTypeHashes()
    {
        std::map<std::string, std::string> hashes;
        const std::string path = configPath();
        if (path.empty()) {
            std::cerr << "RVIZ INTERFACE: config not found (" << kConfigPath << "), no type hashes advertised" << std::endl;
            return hashes;
        }
        try {
            const YAML::Node type_hashes = YAML::LoadFile(path)["type_hashes"];
            if (!type_hashes || !type_hashes.IsMap()) {
                return hashes;
            }
            for (const auto& entry : type_hashes) {
                const auto type_name = entry.first.as<std::string>();
                const auto hash = entry.second.IsNull() ? std::string{} : entry.second.as<std::string>();
                if (hash.empty()) {
                    continue;
                }
                if (hash.size() != 71 || hash.compare(0, 7, "RIHS01_") != 0) {
                    std::cerr << "RVIZ INTERFACE: invalid type hash of " << type_name << " '" << hash
                              << "' (expected RIHS01_ followed by 64 hex digits), not advertised" << std::endl;
                    continue;
                }
                hashes[type_name] = hash;
            }
        } catch (const std::exception& e) {
            std::cerr << "RVIZ INTERFACE: cannot read " << path << " (" << e.what() << "), no type hashes advertised" << std::endl;
        }
        return hashes;
    }

    // Default writer QoS plus "typehash=<hash>;" in USER_DATA (rmw_fastrtps_cpp format) if configured
    eprosima::fastdds::dds::DataWriterQos typeHashQos(const std::map<std::string, std::string>& hashes,
                                                      const std::string& ros_type_name)
    {
        eprosima::fastdds::dds::DataWriterQos qos = eprosima::fastdds::dds::DATAWRITER_QOS_DEFAULT;
        const auto it = hashes.find(ros_type_name);
        if (it != hashes.end()) {
            const std::string user_data = "typehash=" + it->second + ";";
            qos.user_data().data_vec(std::vector<uint8_t>(user_data.begin(), user_data.end()));
        }
        return qos;
    }
}

namespace periodic_app_plugin 
{
    RvizInterface::RvizInterface (const std::string& ID, const robotlib::RobotBasePtr& robot)
    : dls::PeriodicAppPlugin(ID)
    , rviz_mapping_(robot) // instantiate module
    {
        loadConfig();

        blind_state_reader_ = buildInput<dls2_interface::msg::BlindState>(
            dls::topics::low_level_estimation::blind_state);

        base_state_reader_ = buildInput<dls2_interface::msg::BaseState>(
            dls::topics::high_level_estimation::base_state);

        // ROS 2 type hashes advertised to ROS 2 / zenoh bridge peers (config: type_hashes)
        const auto type_hashes = loadTypeHashes();

        joint_state_writer_ = buildOutput<sensor_msgs::msg::JointState>(
            dls::topicType(
                "joint_states",
                new sensor_msgs::msg::JointStatePubSubType()),
            typeHashQos(type_hashes, "sensor_msgs/msg/JointState"));

        // Only create the TF output when enabled, so nothing (not even an
        // empty TFMessage) is published on "tf" by this plugin otherwise.
        if(publish_base_tf_)
        {
            tf_writer_ = buildOutput<tf2_msgs::msg::TFMessage>(
            dls::topicType(
                "tf",
                new tf2_msgs::msg::TFMessagePubSubType()),
            typeHashQos(type_hashes, "tf2_msgs/msg/TFMessage"));
        }

		//define console functions here
        command_manager.addCommand<std::string>
        (
            "setFixedFrame",
            "Set the fixed frame for TF messages",
            std::function<bool(std::string)>([&](std::string type)->bool
            {
                return this->rviz_mapping_.setFixedFrame(type), true;
            }),
            {},
            true
        );

        command_manager.addCommand<std::string>
        (
            "setBaseFrame",
            "Set the base frame for TF messages",
            std::function<bool(std::string)>([&](std::string type)->bool
            {
                return this->rviz_mapping_.setBaseFrame(type), true;
            }),
            {},
            true
        );
        launchRobotStatePublisher(robot->getName());
    }

    RvizInterface::~RvizInterface()
    {   //pkill the robot state publisher process when the plugin is destroyed
        if(std::system("pkill -f robot_state_publisher") != 0) {
            std::cerr << "Error occurred while trying to kill robot_state_publisher process." << std::endl;
        }
    }
    
    std::string RvizInterface::where()
    {
        std::stringstream ss;
        ss << "TODO \n";

        return ss.str();
    }
    
    void RvizInterface::run(const std::chrono::system_clock::time_point& time)
    {
        read();

        joint_state_writer_->msg = rviz_mapping_.map_blind_state(blind_state_reader_->msg);
        if(publish_base_tf_)
        {
            tf_writer_->msg = rviz_mapping_.map_base_state(base_state_reader_->msg);
        }

        write();
    }

    bool RvizInterface::checkActivation()
    {
        if(basicActivationChecks())
        {
            return true;
        }
        return false;
    }

    bool RvizInterface::deactivation(const std::chrono::system_clock::time_point& time){
        return true;
    }

    void RvizInterface::loadConfig()
    {
        try
        {
            const YAML::Node config = YAML::LoadFile(RVIZ_INTERFACE_CONFIG_PATH);
            if(config["publish_base_tf"])
            {
                publish_base_tf_ = config["publish_base_tf"].as<bool>();
            }
        }
        catch(const YAML::Exception& e)
        {
            std::cerr << "RVIZ INTERFACE: could not read " << RVIZ_INTERFACE_CONFIG_PATH
                      << " (" << e.what() << "), using defaults." << std::endl;
        }
        std::cout << "RVIZ INTERFACE: publish_base_tf = "
                  << (publish_base_tf_ ? "true" : "false") << std::endl;
    }

    void RvizInterface::launchRobotStatePublisher(const std::string& robot_name)
    {
        // Run robot state publisher in a separate shell command, so rviz can
        // visualize the robot while this plugin publishes joint states and tf.
        std::string urdf_path = "/usr/include/" + robot_name +
            "-description/urdfs/" + robot_name + "_ros.urdf";
        const std::string bash_command =
            ". /usr/bin/dls2/scripts/setup_ros2_for_dls2.bash && "
            "setsid ros2 run robot_state_publisher robot_state_publisher "
            "--ros-args "
            "-p robot_description:=\"$(cat " + shellQuote(urdf_path) + ")\" "
            "> /tmp/dls2_robot_state_publisher.log 2>&1 &";
        const std::string command = "bash -lc " + shellQuote(bash_command);
        if(std::system(command.c_str()) != 0) {
            std::cerr << "Error occurred while trying to launch robot_state_publisher process." << std::endl;
        }
    }

    std::string RvizInterface::shellQuote(const std::string& value)
    {
        std::string quoted = "'";
        for(const char c : value)
        {
            if(c == '\'')
            {
                quoted += "'\\''";
            }
            else
            {
                quoted += c;
            }
        }
        quoted += "'";
        return quoted;
    }

    extern "C" PeriodicAppPlugin *create(const std::string& ID, const std::string& robot_name)
    {
        /*call_plugin_constructor*/
        std::cout << "RVIZ INTERFACE: Loaded robot " << robot_name << std::endl;
        robotlib::RobotBasePtr robot = robotlib::RobotFactory::openRobot(robot_name);
        return new RvizInterface(ID, robot);
    }

    extern "C" void destroy(PeriodicAppPlugin *p)
    {
        delete p;
    }
} //namespace periodic_app_plugin
