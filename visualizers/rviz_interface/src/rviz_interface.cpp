#include "periodic_app_plugins/RvizInterface/rviz_interface.hpp"

// topics
// Include the TypeSupport of each message associated to each topic
#include <dls_messages/dds/JointStatePubSubTypes.hpp>
#include <dls_messages/dds/TFMessagePubSubTypes.hpp>

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
		// command_manager.addCommand("function_name",
		// 									"Description",
		// 									&RvizInterfacePlugin::function_name, this, {}, true);
    }

    RvizInterface::~RvizInterface()
    { }
    
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

	// bool RvizInterface::function_name(){
	// 	return true;
	// }

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
