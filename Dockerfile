FROM ubuntu:16.04

# The Xilinx toolchain version
ARG XILVER=2021.1

# The SDK installer *GENERATED FROM THE WebInstall WITH OPTION "Extract to directory" (and zip)*
# SDK will be installed in /opt/Xilinx/SDK/${XILVER}
# File is expected in the "resources" subdirectory
ARG SDK_INSTALLER=Xilinx-SDK-v${XILVER}.tgz

# The PetaLinux base. We expect ${PETALINUX_BASE}-installer.run to be the patched installer.
# PetaLinux will be installed in /opt/${PETALINX_BASE}
# File is expected in the "resources" subdirectory
ARG PETALINUX_BASE=petalinux-v${XILVER}-final

# The PetaLinux runnable installer
ARG PETALINUX_INSTALLER=${PETALINUX_BASE}-installer.run

RUN dpkg --add-architecture i386 && apt-get update && apt-get install -y \ 
	python3.4 \
	tofrodos \
	iproute2 \
	gawk \
	xvfb \
	gcc-4.8 \
	git \
	make \
	net-tools \
	libncurses5-dev \
	tftpd \
	tftp-hpa \
	zlib1g-dev:i386 \
	libssl-dev \
	flex \
	bison \
	libselinux1 \
	gnupg \
	wget \
	diffstat \
	chrpath \
	socat \
	xterm \
	autoconf \
	libtool \
	tar \
	unzip \
	texinfo \
	zlib1g-dev \
	gcc-multilib \
	build-essential \
	libsdl1.2-dev \
	libglib2.0-dev \
	screen \
	expect \
	locales \
	cpio \
	sudo \
	software-properties-common \
	pax \
	gzip \
	vim \
	libgtk2.0-0 \
	&& apt-get autoremove --purge && apt-get autoclean

RUN echo "%sudo ALL=(ALL:ALL) ALL" >> /etc/sudoers \
	&& echo "%sudo ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers \
	&& ln -fs /bin/bash /bin/sh

# Set locale
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8  
ENV LANGUAGE en_US:en  
ENV LC_ALL en_US.UTF-8 

# Add user 'petalinux' with password 'petalinux' and give it access to install directory /opt
RUN useradd -m -G dialout,sudo -p '$6$wiu9XEXx$ITRrMySAw1SXesQcP.Bm3Su2CuaByujc6Pb7Ztf4M9ES2ES7laSRwdcbgG96if4slduUxyjqvpEq2I0OhxKCa1' petalinux \
	&& chmod +w /opt \
	&& chown -R petalinux:petalinux /opt \
	&& mkdir /opt/${PETALINUX_BASE} \
	&& chmod 755 /opt/${PETALINUX_BASE} \
	&& chown petalinux:petalinux /opt/${PETALINUX_BASE}

# Install under /opt, with user petalinux
WORKDIR /opt
USER petalinux

# Install SDK
#COPY resources/install_config_sdk.txt .
# COPY ${}
# RUN mkdir t && cd t && wget -q ${HTTP_SERV}/install_config_sdk.txt \
# 	&& wget -q -O - ${HTTP_SERV}/${SDK_INSTALLER} | tar -xz \
# 	&& ./xsetup -b Install -a XilinxEULA,3rdPartyEULA,WebTalkTerms -c install_config_sdk.txt \
# 	&& cd .. && rm -rf t \
# 	&& echo "source /opt/Xilinx/SDK/${XILVER}/settings64.sh" >> ~/.bashrc \
# 	&& echo "source /opt/${PETALINUX_BASE}/settings.sh" >> ~/.bashrc

COPY ${PETALINUX_INSTALLER} .

# Install PetaLinux
RUN chown -R petalinux:petalinux . \
	&& chmod a+x ${PETALINUX_INSTALLER} \
	&& SKIP_LICENSE=y ./${PETALINUX_FILE}${PETALINUX_INSTALLER} /opt/${PETALINUX_BASE} \
	&& rm -f ./${PETALINUX_INSTALLER} \
	&& rm -f petalinux_installation_log

# Source settings at login
USER root
RUN echo "source /opt/${PETALINUX_BASE}/settings.sh" >> /etc/profile
