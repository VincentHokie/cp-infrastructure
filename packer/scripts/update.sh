#!/bin/bash -eux

sudo apt-get update -y
# sudo do-release-upgrade
sudo apt-get -y upgrade

# ensure the correct kernel headers are installed
sudo apt-get -y install linux-headers-$(uname -r)
# fix broken dependencies
sudo apt-get -y -f install
# update package index on boot
# cat <<EOF > /etc/init/refresh-apt.conf
# description "update package index"
# start on networking
# task
# exec /usr/bin/apt-get update
# EOF

# install curl to fix broken wget while retrieving content from secured sites
sudo apt-get -y install curl

# install general purpose packages
# install rsync
# used command for copying and synchronizing files and directories remotely as well
# as locally in Linux/Unix systems. With the help of rsync command you can copy and
# synchronize your data remotely and locally across directories, 
sudo apt-get -y install rsync

# install screen
sudo apt-get -y install screen

# install git
echo "Installing git"
sudo apt-get -y install git

# sshd config
# OpenSSH server reads a configuration file when it is started (/etc/ssh/sshd_config)

# UseDNS - Determines whether IP Address to Hostname lookup and comparison is performed
# Default value is No which avoids login delays when the remote client's DNS cannot be resolved
# Value of No implies that the usage of "from=" in authorized_keys will not support DNS host names but only IP addresses.
# Value of Yes supports host names in "from=" for authorized_keys. Additionally if the remote client's IP address does not match the resolved DNS host name (or could not be reverse lookup resolved) then a warning is logged.

# Specifies whether sshd(8) should look up the remote host name and
# check that the resolved host name for the remote IP address maps
# back to the very same IP address.
# sudo echo "UseDNS no" >> /etc/ssh/sshd_config

# Specifies whether user authentication based on
# GSSAPI(Generic_Security_Services_Application_Program_Interface) is allowed

# GSS-API
# The definitive feature of GSSAPI applications is the exchange of opaque messages (tokens)
# which hide the implementation detail from the higher-level application. The client and server
# sides of the application are written to convey the tokens given to them by their respective
# GSSAPI implementations. GSSAPI tokens can usually travel over an insecure network as the
# mechanisms provide inherent message security. After the exchange of some number of tokens, the
# GSSAPI implementations at both ends inform their local application that a security context has
# been established.
# Once a security context is established, sensitive application messages can be wrapped (encrypted)
# by the GSSAPI for secure communication between client and server. Typical protections guaranteed
# by GSSAPI wrapping include confidentiality (secrecy) and integrity (authenticity). The GSSAPI can
# also provide local guarantees about the identity of the remote user or remote host.

# sudo echo "GSSAPIAuthentication no" >> /etc/ssh/sshd_config

# sudoers config
# Only add the secure path line if it is not already present - Debian 7
# includes it by default.
# sudo grep -q 'secure_path' /etc/sudoers || sed -i -e '/Defaults\s\+env_reset/a Defaults\tsecure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"' /etc/sudoers
