# Verigreen Collector Dockerfile
# ==============================
# ## Purpose
# 	- Builds an image for the Verigreen Collector App
# ## Author(s):
#	- Ricardo Quintana https://github.com/rqc
#

FROM tomcat:7.0.57-jre7
MAINTAINER Ricardo Quintana https://github.com/rqc

# Install necessary OS packages, including:
# - `Git`
# - `host` - for automated deployment scripts
RUN apt-get update && apt-get install -y \
										--fix-missing  \
										curl \
										git \									
										tar \
										bash \
										host \
										&& \
										apt-get clean

# Environment variables that point to directories.
ENV	VERIGREEN_RELEASE="verigreen-2.0.1"

ENV APP_DIR="/app" \
	VG_HOME="/vg" \
	VG_REPO="/repo" \
	ROOT_SSH_DIR="/root/.ssh" \
	TOMCAT_WEBAPPS_DIR="/usr/local/tomcat/webapps" \
	VG_DOWNLOAD_URL="https://github.com/Verigreen/verigreen/releases/download/$VERIGREEN_RELEASE/verigreen-collector.war"

# Create directories for Verigreen
# Download the release source code for verigreen (from Github)
# Build the entire Verigreen project and copy war to tomcat webapps directory.
# Finally, cleanup and prepare startup scripts.
RUN	mkdir -p $VG_HOME && \
	mkdir -p $APP_DIR && \
	rm -rf $TOMCAT_WEBAPPS_DIR/ROOT && \
	curl -SL "$VG_DOWNLOAD_URL" -o "$TOMCAT_WEBAPPS_DIR/ROOT.war"

# Add the `docker-entrypoint.sh` script which will setup correctly the container's environment for Verigreen and it will start the app.
ADD docker-entrypoint.sh $APP_DIR/

# Change to the root directory where our scripts will be located.
WORKDIR $APP_DIR

# Prepare script for execution.
RUN chmod +x docker-entrypoint.sh

# Run Verigreen using deployment script `docker-entrypoint.sh`.
# Default Verigreen port is `8080` and is exposed by parent tomcat image.
CMD ["./docker-entrypoint.sh"]