#ifndef RVIZMAPPING_PLUGIN_HPP
#define RVIZMAPPING_PLUGIN_HPP


#include "dls_messages/dds/BaseState.hpp"
#include "dls_messages/dds/BlindState.hpp"
#include "dls_messages/dds/JointState.hpp"
#include "dls_messages/dds/TFMessage.hpp"

#include "robotlib/robot_base.hpp"

class RvizMapping
{
public:
    RvizMapping(const robotlib::RobotBasePtr& robot, const std::string& fixed_frame = "map", const std::string& base_frame = "base_link");
    ~RvizMapping();

    sensor_msgs::msg::JointState map_blind_state(const dls2_interface::msg::BlindState& blind_state) const;

    tf2_msgs::msg::TFMessage map_base_state(const dls2_interface::msg::BaseState& base_state) const;

    void setFixedFrame(const std::string& fixed_frame);
    void setBaseFrame(const std::string& base_frame);

private:
    robotlib::RobotBasePtr robot_;
    std::string fixed_frame_;
    std::string base_frame_;

    void set_stamp_from_nanoseconds(std_msgs::msg::Header& header, uint64_t timestamp_ns) const;

};


#endif // end of include guard: RVIZIMAPPING_PLUGIN_HPP
