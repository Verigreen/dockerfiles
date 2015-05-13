# Purpose: Builds an image for the Verigreen Collector App
# Author(s):
#	Ricardo Quintana <https://github.com/rqc>
#

FROM tomcat:7.0.57-jre7
MAINTAINER Ricardo Quintana https://github.com/rqc


# Install necessary OS packages, including:
# - `Git`
# - `host` - for automated deployment scripts
RUN apt-get update && apt-get install -y \
									curl \
									git \									
									tar \
									bash \
									host \
									openjdk-7-jdk \
									maven && \
									apt-get clean

# Handy environment variables that point to directories.
# Interestingly, we need to set the `VG_ROOT` in a previous layer for it to be available for latter references. 
ENV VG_ROOT="/var/vg" \
	VERIGREEN_VERSION="2.0.0"

ENV VG_PROJECT="$VG_ROOT/app" \
	VG_HOME="$VG_ROOT/config" \
	VG_REPO="/var/repo" \
	ROOT_SSH_DIR="/root/.ssh" \
	TOMCAT_WEBAPPS_DIR="/usr/local/tomcat/webapps"

# Create directories for Verigreen
# Download the release source code for verigreen (from Github)
# Build the entire Verigreen project and copy war to tomcat webapps directory.
# Finally, cleanup and prepare startup scripts.
RUN mkdir -p $VG_ROOT && \
	mkdir -p $VG_HOME && \
	mkdir -p $VG_PROJECT && \
	rm -rf $TOMCAT_WEBAPPS_DIR/ROOT && \
	curl -sSL https://github.com/Verigreen/verigreen/archive/verigreen-$VERIGREEN_VERSION.tar.gz -o /tmp/verigreen.tar.gz && \
	cd /tmp && \
	tar -zxvf /tmp/verigreen.tar.gz && \
	cp -R /tmp/verigreen-verigreen-$VERIGREEN_VERSION/* $VG_PROJECT/ && \
	rm -rf /tmp/verigreen-verigreen-$VERIGREEN_VERSION && \
	rm -rf /tmp/verigreen.tar.gz && \
	cd "$VG_PROJECT" && \
	mvn clean install && \
	cp "$VG_PROJECT/verigreen-collector-webapp/target/verigreen-collector.war" "$TOMCAT_WEBAPPS_DIR/ROOT.war" && \
	rm -rf /root/.m2 && \
	rm -rf $VG_PROJECT && \ 
	apt-get remove --purge -y maven

# Add the `run.sh` script which will setup correctly the container's environment for Verigreen and it will start the app.
ADD run.sh $VG_ROOT/

# Change to the root directory where our scripts will be located.
WORKDIR $VG_ROOT

# Prepare script for execution.
RUN chmod +x run.sh

# Run Verigreen using deployment script `run.sh`.
# Default Verigreen port is `8080` and is exposed by parent tomcat image.
CMD ["./run.sh"]