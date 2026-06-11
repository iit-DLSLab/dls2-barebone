#include "periodic_app_plugins/RvizInterface/rviz_mapping.hpp"


RvizMapping::RvizMapping (const robotlib::RobotBasePtr& robot, const std::string& fixed_frame, const std::string& base_frame)
: robot_(robot)
, fixed_frame_(fixed_frame)
, base_frame_(base_frame)
{}

RvizMapping::~RvizMapping()
{ }

sensor_msgs::msg::JointState RvizMapping::map_blind_state(
    const dls2_interface::msg::BlindState& blind_state) const
{
    sensor_msgs::msg::JointState joint_state;
    joint_state.header().frame_id(base_frame_);
    set_stamp_from_nanoseconds(joint_state.header(), blind_state.timestamp());

    auto urdf_names = robot_->getNameMap();
    for (const auto& name : blind_state.joints_name())
    {
        joint_state.name().push_back(urdf_names[name]);
    }

    const std::size_t joint_count = joint_state.name().size();
    if (blind_state.joints_position().size() == joint_count)
    {
        joint_state.position() = blind_state.joints_position();
    }
    else
    {
        joint_state.position().assign(joint_count, 0.0);
    }

    if (blind_state.joints_velocity().size() == joint_count)
    {
        joint_state.velocity() = blind_state.joints_velocity();
    }
    else
    {
        joint_state.velocity().assign(joint_count, 0.0);
    }

    if (blind_state.joints_effort().size() == joint_count)
    {
        joint_state.effort() = blind_state.joints_effort();
    }
    else
    {
        joint_state.effort().assign(joint_count, 0.0);
    }
    return joint_state;
}

tf2_msgs::msg::TFMessage RvizMapping::map_base_state(
    const dls2_interface::msg::BaseState& base_state) const
{
    tf2_msgs::msg::TFMessage tf_message;
    tf_message.transforms().resize(1);

    auto& transform_stamped = tf_message.transforms()[0];
    transform_stamped.header().frame_id(fixed_frame_);
    transform_stamped.child_frame_id(base_frame_);
    set_stamp_from_nanoseconds(transform_stamped.header(), base_state.header().timestamp());

    const auto& position = base_state.pose().position();
    const auto& orientation = base_state.pose().orientation();

    transform_stamped.transform().translation().x(position[0]);
    transform_stamped.transform().translation().y(position[1]);
    transform_stamped.transform().translation().z(position[2]);

    transform_stamped.transform().rotation().x(orientation[0]);
    transform_stamped.transform().rotation().y(orientation[1]);
    transform_stamped.transform().rotation().z(orientation[2]);
    transform_stamped.transform().rotation().w(orientation[3]);
    return tf_message;
}

void RvizMapping::setFixedFrame(const std::string& fixed_frame)
{
    fixed_frame_ = fixed_frame;
}

void RvizMapping::setBaseFrame(const std::string& base_frame)
{
    base_frame_ = base_frame;
}

void RvizMapping::set_stamp_from_nanoseconds(
    std_msgs::msg::Header& header,
    const uint64_t timestamp_ns) const
{
    if (timestamp_ns<=0)
    {
        std::cerr << "RvizMapping class: WARNING: Timestamp is not set or invalid (timestamp_ns=" << timestamp_ns << ")." << std::endl;
        return;
    }
    header.stamp().sec(static_cast<int32_t>(timestamp_ns / 1000000000ULL));
    header.stamp().nanosec(static_cast<uint32_t>(timestamp_ns % 1000000000ULL));
}
