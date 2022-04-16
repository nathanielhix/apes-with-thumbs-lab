#version=RHEL8
# Use text install
text

repo --name="Minimal" --baseurl=http://pxe.int.fetid.net/images/almalinux-8-5/Minimal

%packages
@^minimal-environment
kexec-tools
sudo
openssh-server
openssh-clients

%end

# Keyboard layouts
keyboard --xlayouts='us'
# System language
lang en_US.UTF-8

# Network information
network  --bootproto=dhcp --device=ens192 --nameserver=192.168.101.10 --activate
#network  --hostname=unconfigured_host

# Use network installation
url --url="http://pxe.int.fetid.net/images/almalinux-8-5"

# Run the Setup Agent on first boot
firstboot --disable

ignoredisk --only-use=sda
autopart
# Partition clearing information
clearpart --all --drives=sda --initlabel

# System timezone
timezone America/Los_Angeles --isUtc

# Root password
rootpw --iscrypted #<redacted>

# Add groups
group --name=ssh-users --gid=3000

# Add svc-admin
user --name=svc-admin --uid=2000 --gid=2000 --groups=ssh-users --iscrypted --password=#<redacted>

sshkey --username=svc-admin "<redacted_pub_key>"

%addon com_redhat_kdump --enable --reserve-mb='auto'

%end

%anaconda
pwpolicy root --minlen=6 --minquality=1 --notstrict --nochanges --notempty
pwpolicy user --minlen=6 --minquality=1 --notstrict --nochanges --emptyok
pwpolicy luks --minlen=6 --minquality=1 --notstrict --nochanges --notempty
%end
