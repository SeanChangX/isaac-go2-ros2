#!/bin/bash -e

# Environment variables with defaults
USER_ID=${LOCAL_USER_ID:-1000}
GROUP_ID=${LOCAL_GROUP_ID:-1000}
USERNAME=ubuntu
ROS_DISTRO=${ROS_DISTRO:-humble}

# # Update ros user's UID and GID to match external user
# if [ "$(id -u $USERNAME)" != "$USER_ID" ] || [ "$(id -g $USERNAME)" != "$GROUP_ID" ]; then
#     echo "Updating $USERNAME UID and GID to match external user..."
#     usermod -u $USER_ID $USERNAME
#     groupmod -g $GROUP_ID $USERNAME
#     chown -R $USERNAME:$USERNAME /home/$USERNAME
# fi

# Enter the ROS workspace
if [ -d "$ROS_WS" ]; then
    cd $ROS_WS
else
    echo "Warning: ROS workspace $ROS_WS not found, staying in current directory"
fi

# # Change user to ros if running as root
# if [ "$(id -u)" != "$USER_ID" ]; then
#     echo "Switching to user $USERNAME..."
#     exec gosu $USERNAME "$0" "$@"
# fi

# Source ROS2 environment
if [ -f "/opt/ros/${ROS_DISTRO}/setup.bash" ]; then
    echo "Sourcing ROS2 ${ROS_DISTRO} environment..."
    source "/opt/ros/${ROS_DISTRO}/setup.bash"
fi

# Source workspace if it exists
if [ -f "$ROS_WS/install/setup.bash" ]; then
    echo "Sourcing workspace environment..."
    source "$ROS_WS/install/setup.bash"
fi

# Set RMW implementation for Isaac Sim
export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp
echo "Using RMW implementation: $RMW_IMPLEMENTATION"

# Initialize conda
echo "Initializing conda environment..."
if [ -f "/home/ubuntu/miniconda3/etc/profile.d/conda.sh" ]; then
    source "/home/ubuntu/miniconda3/etc/profile.d/conda.sh"
fi

# Activate isaaclab conda environment
if [ -f "/home/ubuntu/miniconda3/envs/isaaclab/bin/python" ]; then
    echo "Activating isaaclab conda environment..."
    conda activate isaaclab 2>/dev/null || echo "Warning: Failed to activate isaaclab environment, using current environment"
    echo "Current conda environment: $(conda info --envs 2>/dev/null | grep '*' | awk '{print $1}' || echo 'base')"
else
    echo "Warning: isaaclab conda environment not found, using base environment"
fi

# Isaac Sim specific environment variables
export ACCEPT_EULA=Y
export PRIVACY_CONSENT=N

# Auto build workspace
if [ "${AUTO_BUILD}" = "true" ]; then
    echo "Running colcon build..."
    source /opt/ros/${ROS_DISTRO}/setup.bash
    cd "$ROS_WS"
    colcon build --symlink-install

    # Re-source after build
    if [ -f "$ROS_WS/install/setup.bash" ]; then
        source "$ROS_WS/install/setup.bash"
    fi
fi

# Auto run program
if [ "${AUTO_RUN}" = "true" ]; then
    echo "Launching main program..."
    cd /home/ubuntu/isaac-go2-ros2
    python isaac_go2_ros2.py
fi

# If no command is provided, start an idle loop to keep the container alive
if [ $# -eq 0 ]; then
    echo "No command provided. Starting idle loop to keep container alive..."
    while true; do sleep 60; done
else
    echo "Executing command as $USERNAME: $@"
    # exec gosu $USERNAME "$@"
    exec "$@"
fi
