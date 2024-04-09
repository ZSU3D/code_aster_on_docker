FROM phusion/baseimage:0.11

# Avoid prompts from apt
ENV DEBIAN_FRONTEND=noninteractive

# Set locale environment
ENV LC_ALL=C.UTF-8 \
    LANG=C.UTF-8 \
    LANGUAGE=C.UTF-8

# Prepare Ubuntu and install dependencies
RUN apt-get update && apt-get upgrade -y --with-new-pkgs -o Dpkg::Options::="--force-confold" && \
    apt-get install -y locales sudo gcc g++ gfortran wget python3 python3-dev python3-numpy libxft2 libxmu6 libxss1 patch make cmake grace zlib1g-dev tk bison flex libglu1-mesa libxcursor-dev libmpich-dev libopenblas-dev libsuperlu-dev libboost-python-dev && \
    echo "C.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Add user aster with sudo privileges
RUN adduser --disabled-password --gecos "" aster && \
    adduser aster sudo && \
    echo "%sudo ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers


# Switch back to root for final setup
USER root

# Custom scripts or additional setup
# Example: COPY some-script.sh /usr/local/bin/some-script.sh
# RUN chmod +x /usr/local/bin/some-script.sh

# Cleanup (if any)
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENTRYPOINT ["/sbin/my_init", "--quiet", "--", "/sbin/setuser", "aster", "/bin/bash", "-l", "-c"]
CMD ["/bin/bash", "-i"]
