######################################################################
# - Base stage
#   - This stage serves as the base image for the following stages.
#   - Based on Isaac Sim official image
######################################################################

FROM nvcr.io/nvidia/isaac-sim:4.5.0 AS base

LABEL org.opencontainers.image.title="Isaac Go2 ROS2"
LABEL org.opencontainers.image.authors="scx@gapp.nthu.edu.tw"
LABEL org.opencontainers.image.licenses="MIT"

ARG USERNAME=ubuntu
ARG USER_UID=1000
ARG USER_GID=1000

######################################################################
# - User setup stage
#   - Create a non-root user with default bash shell.
######################################################################

FROM base AS user-setup

# RUN groupadd --gid $USER_GID $USERNAME \
    # && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
RUN apt-get update \
    && apt-get install -y sudo gosu \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME \
    && rm -rf /var/lib/apt/lists/*

######################################################################
# - ROS2 Installation stage
#   - Install ROS2 Humble and related packages
######################################################################

FROM user-setup AS ros2-setup

USER ubuntu
WORKDIR /home/ubuntu

# ARG variables need to be redeclared in each stage
ARG ROS_DISTRO=humble

# Install ROS2 Humble
RUN sudo apt-get update && sudo apt-get install -y \
    locales \
    software-properties-common \
    curl \
    gnupg \
    lsb-release \
    && sudo locale-gen en_US en_US.UTF-8 \
    && sudo update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 \
    && sudo add-apt-repository universe \
    && sudo rm -rf /var/lib/apt/lists/*
ENV LANG=en_US.UTF-8

# Add ROS2 repository
RUN curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /tmp/ros-archive-keyring.gpg \
    && sudo mv /tmp/ros-archive-keyring.gpg /usr/share/keyrings/ros-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo $UBUNTU_CODENAME) main" | sudo tee /etc/apt/sources.list.d/ros2.list > /dev/null

# Set timezone non-interactively
ENV DEBIAN_FRONTEND=noninteractive
RUN sudo ln -fs /usr/share/zoneinfo/UTC /etc/localtime

# Install ROS 2 packages (official Desktop Install method)
RUN sudo apt-get update && sudo apt-get upgrade -y \
    && sudo apt-get install -y \
    ros-${ROS_DISTRO}-ros-base \
    ros-${ROS_DISTRO}-rmw-cyclonedds-cpp \
    ros-${ROS_DISTRO}-foxglove-bridge \
    ros-${ROS_DISTRO}-cv-bridge \
    ros-${ROS_DISTRO}-ament-cmake \
    python3-colcon-common-extensions

# Additional ROS2 packages (commented out to reduce build time and image size)
# Uncomment as needed for your specific use case:
# ros-${ROS_DISTRO}-nav2-msgs \
# ros-${ROS_DISTRO}-nav2-util \
# ros-${ROS_DISTRO}-navigation2 \
# ros-${ROS_DISTRO}-nav2-bringup \
# ros-${ROS_DISTRO}-turtlebot3* \
# ros-${ROS_DISTRO}-urdf-launch \
# ros-${ROS_DISTRO}-joint-state-publisher \
# ros-${ROS_DISTRO}-joint-state-publisher-gui \
# ros-${ROS_DISTRO}-behaviortree-cpp \
# ros-${ROS_DISTRO}-generate-parameter-library

######################################################################
# - Tools Installation stage
#   - Install common tools for development.
######################################################################
FROM ros2-setup AS tools

RUN sudo apt-get update && sudo apt-get install -y \
    tmux \
    htop \
    tree \
    vim \
    git \
    wget \
    curl \
    unzip \
    usbutils \
    python3-pip \
    bash-completion
    
RUN mkdir -p ~/miniconda3 \
    && wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda3/miniconda.sh \
    && bash ~/miniconda3/miniconda.sh -b -u -p ~/miniconda3 \
    && rm ~/miniconda3/miniconda.sh \
    && bash -c "source ~/miniconda3/bin/activate && conda init --all"

# Add conda to PATH
ENV PATH="/home/ubuntu/miniconda3/bin:$PATH"

# Configure conda to avoid TOS issues
RUN /home/ubuntu/miniconda3/bin/conda config --remove channels defaults && \
    /home/ubuntu/miniconda3/bin/conda config --add channels conda-forge && \
    /home/ubuntu/miniconda3/bin/conda config --set channel_priority strict && \
    /home/ubuntu/miniconda3/bin/conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/main && \
    /home/ubuntu/miniconda3/bin/conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/r

# Clone IsaacLab repository and create symbolic link
RUN git clone https://github.com/isaac-sim/IsaacLab.git /home/ubuntu/IsaacLab && \
    cd /home/ubuntu/IsaacLab && \
    ln -s /isaac-sim _isaac_sim && \
    ./isaaclab.sh --conda isaaclab

# Install IsaacLab extensions
RUN sudo chown -R ubuntu:ubuntu /isaac-sim
RUN cd /home/ubuntu/IsaacLab && \
    bash -c "source /home/ubuntu/miniconda3/bin/activate && conda activate isaaclab && ./isaaclab.sh --install"

RUN sudo apt-get update && sudo apt-get dist-upgrade -y \
    && sudo apt-get autoremove -y \
    && sudo apt-get autoclean -y \
    && sudo apt-get clean -y \
    && sudo rm -rf /var/lib/apt/lists/*

######################################################################
# - Final stage
#   - Set up the environment and entrypoint.
######################################################################

FROM tools AS final

# Set up the user environment
ENV TZ=Asia/Taipei
ENV SHELL=/bin/bash
ENV TERM=xterm-256color

# Isaac Sim environment variables
ENV ACCEPT_EULA=Y
ENV PRIVACY_CONSENT=N
ENV NVIDIA_DRIVER_CAPABILITIES=all

# ROS2 environment variables
ENV ROS_DISTRO=${ROS_DISTRO}
ENV RMW_IMPLEMENTATION=rmw_cyclonedds_cpp

USER root
WORKDIR /home/$USERNAME

# Set up bashrc
COPY .bashrc .bashrc.conf
RUN cat .bashrc.conf >> .bashrc && rm .bashrc.conf

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/bin/bash"]