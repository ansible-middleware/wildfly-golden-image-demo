FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

LABEL maintainer="Your Name <your.email@example.com>" \
      description="WildFly Golden Image built with Ansible" \
      version="1.0.0"

# Install runtime dependencies and Ansible
RUN microdnf install -y \
    java-17-openjdk-headless \
    python3 \
    python3-pip \
    python3-dnf \
    tar \
    gzip \
    unzip && \
    microdnf clean all && \
    pip3 install --no-cache-dir ansible-core

# Copy Ansible configuration files
COPY ansible/ /tmp/ansible/
WORKDIR /tmp/ansible

# Install Ansible collections and run configuration
RUN ansible-galaxy collection install -r requirements.yml && \
    ansible-playbook -i inventory configure.yml && \
    rm -rf /tmp/ansible /root/.ansible /root/.cache && \
    ln -s /opt/wildfly/wildfly-39.0.1.Final /opt/wildfly/current

# Set working directory
WORKDIR /opt/wildfly/current

# Switch to non-root user
USER wildfly

# Expose WildFly ports
EXPOSE 8080 9990

# Start WildFly
CMD ["/opt/wildfly/current/bin/standalone.sh", "-b", "0.0.0.0", "-bmanagement", "0.0.0.0"]
