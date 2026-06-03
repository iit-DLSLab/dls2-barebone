#ifndef RVIZINTERFACE_PLUGIN_HPP
#define RVIZINTERFACE_PLUGIN_HPP

// periodic plugin header
#include <dls2/plugin/periodic_app_plugin.hpp>
#include "periodic_app_plugins/RvizInterface/rviz_mapping.hpp"
// reader include
// #include "dls2/signal/reader.hpp"
// writer include
// #include "dls2/signal/writer.hpp"
// messages includes
#include "dls_messages/dds/BaseState.hpp"
#include "dls_messages/dds/BlindState.hpp"
#include "dls_messages/dds/JointState.hpp"
#include "dls_messages/dds/TFMessage.hpp"

#include "robotlib/robot_base.hpp"



namespace periodic_app_plugin
{
    class RvizInterface : public dls::PeriodicAppPlugin
    {
    public:
        RvizInterface (
            const std::string &ID, const robotlib::RobotBasePtr& robot);

        ~RvizInterface();

        void run(const std::chrono::system_clock::time_point &time) override;

        std::string where() override;

        AppStatus eStop() override { return getStatus(); }

        bool checkActivation() override;

        bool deactivation(const std::chrono::system_clock::time_point& time) override;

		// console commands definitions
		/* bool function_name();*/

    private:
        RvizMapping rviz_mapping_;

		dls::ReaderPtr<dls2_interface::msg::BlindState> blind_state_reader_;
		dls::ReaderPtr<dls2_interface::msg::BaseState> base_state_reader_;
		dls::WriterPtr<sensor_msgs::msg::JointState> joint_state_writer_;
		dls::WriterPtr<tf2_msgs::msg::TFMessage> tf_writer_;

        void launchRobotStatePublisher(const std::string& robot_name);
    };
} // namespace periodic_app_plugin


#endif // end of include guard: RVIZINTERFACE_PLUGIN_HPP
