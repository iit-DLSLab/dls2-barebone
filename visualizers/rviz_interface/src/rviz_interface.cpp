#include "periodic_app_plugins/RvizInterface/rviz_interface.hpp"

// topics
// Include the TypeSupport of each message associated to each topic
#include <dls_messages/dds/ros2_interface/sensor_msgs/msg/JointStatePubSubTypes.hpp>
#include <dls_messages/dds/ros2_interface/tf2_msgs/msg/TFMessagePubSubTypes.hpp>

#include "dls2/topics/topics.hpp"

#include "robotlib/robot_factory.hpp"

namespace periodic_app_plugin 
{
    RvizInterface::RvizInterface (const std::string& ID, const robotlib::RobotBasePtr& robot)
    : dls::PeriodicAppPlugin(ID)
    , rviz_mapping_(robot) // instantiate module
    {
        blind_state_reader_ = buildInput<dls2_interface::msg::BlindState>(
            dls::topics::low_level_estimation::blind_state);

        base_state_reader_ = buildInput<dls2_interface::msg::BaseState>(
            dls::topics::high_level_estimation::base_state);

        joint_state_writer_ = buildOutput<sensor_msgs::msg::JointState>(
            dls::topicType(
                "joint_states",
                new sensor_msgs::msg::JointStatePubSubType()));

        tf_writer_ = buildOutput<tf2_msgs::msg::TFMessage>(
            dls::topicType(
                "tf",
                new tf2_msgs::msg::TFMessagePubSubType()));

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
        tf_writer_->msg = rviz_mapping_.map_base_state(base_state_reader_->msg);

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

    void RvizInterface::launchRobotStatePublisher(const std::string& robot_name)
    {
        // Run robot state publisher in a separate shell command, so rviz can
        // visualize the robot while this plugin publishes joint states and tf.
        std::string urdf_path = "/usr/include/" + robot_name +
            "_description/urdfs/" + robot_name + "_ros.urdf";
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
