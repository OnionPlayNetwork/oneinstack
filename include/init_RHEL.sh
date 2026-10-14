#!/bin/bash
# Author:  yeho <lj2007331 AT gmail.com>
# BLOG:  https://linuxeye.com
#
# Notes: OneinStack for CentOS/RedHat 7+ Debian 9+ and Ubuntu 16+
#
# Project home page:
#       https://oneinstack.com
#       https://github.com/oneinstack/oneinstack

# Close SELINUX
setenforce 0
sed -i 's/^SELINUX=.*$/SELINUX=disabled/' /etc/selinux/config

# Custom profile
cat > /etc/profile.d/oneinstack.sh << EOF
HISTSIZE=10000
PS1="\[\e[37;40m\][\[\e[32;40m\]\u\[\e[37;40m\]@\h \[\e[35;40m\]\W\[\e[0m\]]\\\\$ "
HISTTIMEFORMAT="%F %T \$(whoami) "

alias l='ls -AFhlt'
alias lh='l | head'
alias vi=vim

GREP_OPTIONS="--color=auto"
alias grep='grep --color'
alias egrep='egrep --color'
alias fgrep='fgrep --color'
EOF
[[ "${Platform}" =~ ^euleros$|^openeuler$ ]] && sed -i '/HISTTIMEFORMAT=/d' /etc/profile.d/oneinstack.sh

[[ ! "${Platform}" =~ ^euleros$|^openeuler$ ]] && [ -z "$(grep ^'PROMPT_COMMAND=' /etc/bashrc)" ] && cat >> /etc/bashrc << EOF
PROMPT_COMMAND='{ msg=\$(history 1 | { read x y; echo \$y; });logger "[euid=\$(whoami)]":\$(who am i):[\`pwd\`]"\$msg"; }'
EOF

# /etc/security/limits.conf
[ -e /etc/security/limits.d/*nproc.conf ] && rename nproc.conf nproc.conf_bk /etc/security/limits.d/*nproc.conf
sed -i '/^# End of file/,$d' /etc/security/limits.conf
cat >> /etc/security/limits.conf <<EOF
# End of file
* soft nproc 1000000
* hard nproc 1000000
* soft nofile 1000000
* hard nofile 1000000
EOF

# /etc/hosts
[ "$(hostname -i | awk '{print $1}')" != "127.0.0.1" ] && sed -i "s@127.0.0.1.*localhost@&\n127.0.0.1 $(hostname)@g" /etc/hosts

# Set timezone
rm -rf /etc/localtime
ln -s /usr/share/zoneinfo/${timezone} /etc/localtime

# ip_conntrack table full dropping packets
echo -e "modprobe nf_conntrack\nmodprobe nf_conntrack_ipv4" > /etc/sysconfig/modules/nf_conntrack.modules
chmod +x /etc/sysconfig/modules/nf_conntrack.modules
modprobe nf_conntrack
modprobe nf_conntrack_ipv4
echo options nf_conntrack hashsize=131072 > /etc/modprobe.d/nf_conntrack.conf

# /etc/sysctl.conf
[ ! -e "/etc/sysctl.conf_bk" ] && /bin/mv /etc/sysctl.conf{,_bk}
cat > /etc/sysctl.conf << EOF
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.core.rmem_default = 16777216
net.core.wmem_default = 16777216
net.core.optmem_max = 4194304
net.ipv4.tcp_rmem = 3145728 8388608 16777216
net.ipv4.tcp_wmem = 3145728 8388608 16777216
net.ipv4.udp_mem = 3145728 8388608 16777216
net.ipv4.tcp_mem = 3145728 12582912 25165824
net.ipv4.udp_rmem_min = 16384
net.ipv4.udp_wmem_min = 16384
net.core.netdev_max_backlog = 100000
net.core.somaxconn = 32768
net.ipv4.tcp_max_syn_backlog = 16384
net.core.busy_poll = 50
net.core.busy_read = 50
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_notsent_lowat = 16384
net.core.dev_weight = 64
net.ipv4.tcp_max_tw_buckets = 2000000
net.ipv4.ip_local_port_range = 1024 65535
net.ipv4.tcp_congestion_control = bbr
net.core.default_qdisc = fq
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_sack = 1
net.ipv4.tcp_dsack = 1
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_fin_timeout = 10
net.ipv4.tcp_keepalive_time = 300
net.ipv4.tcp_keepalive_intvl = 10
net.ipv4.tcp_keepalive_probes = 6
net.ipv4.tcp_moderate_rcvbuf = 1
net.ipv4.tcp_frto = 2
net.ipv4.tcp_mtu_probing = 1
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
kernel.sched_rt_runtime_us = 980000
kernel.sched_autogroup_enabled = 0
kernel.sched_cfs_bandwidth_slice_us = 3000
vm.swappiness = 10
vm.dirty_ratio = 5
vm.dirty_background_ratio = 2
vm.dirty_expire_centisecs = 1000
vm.dirty_writeback_centisecs = 100
vm.zone_reclaim_mode = 0
vm.min_free_kbytes = 196608
vm.vfs_cache_pressure = 70
vm.overcommit_memory = 0
vm.overcommit_ratio = 50
vm.max_map_count = 1048576
vm.page-cluster = 0
vm.oom_kill_allocating_task = 1
fs.file-max = 32000000
fs.nr_open = 6400000
fs.aio-max-nr = 262144
fs.inotify.max_user_instances = 2048
fs.inotify.max_user_watches = 2097152
kernel.pid_max = 524288
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
net.nf_conntrack_max = 6553500
net.netfilter.nf_conntrack_max = 6553500
net.netfilter.nf_conntrack_tcp_timeout_close_wait = 60
net.netfilter.nf_conntrack_tcp_timeout_fin_wait = 120
net.netfilter.nf_conntrack_tcp_timeout_time_wait = 120
net.netfilter.nf_conntrack_tcp_timeout_established = 3600
EOF
sysctl -p

if [ ${RHEL_ver} -ge 7 >/dev/null 2>&1 ]; then
  sed -i 's@LANG=.*$@LANG="en_US.UTF-8"@g' /etc/locale.conf
fi

# firewall
if [ "${firewall_flag}" == 'y' ]; then
  systemctl enable firewalld
  systemctl start firewalld
  firewall-cmd --permanent --zone=public --add-port={22/tcp,80/tcp,443/tcp}
  [ "${ssh_port}" != "22" ] && firewall-cmd --permanent --zone=public --add-port=${ssh_port}/tcp
  firewall-cmd --reload
else
  systemctl stop firewalld
  systemctl disable firewalld
fi
systemctl restart rsyslog sshd

. /etc/profile
