#!/bin/bash
# Author:  yeho <lj2007331 AT gmail.com>
# BLOG:  https://linuxeye.com
#
# Notes: OneinStack for CentOS/RedHat 7+ Debian 9+ and Ubuntu 16+
#
# Project home page:
#       https://oneinstack.com
#       https://github.com/oneinstack/oneinstack

# Custom profile
cat > /etc/profile.d/oneinstack.sh << EOF
HISTSIZE=10000
HISTTIMEFORMAT="%F %T \$(whoami) "

alias l='ls -AFhlt --color=auto'
alias lh='l | head'
alias ll='ls -l --color=auto'
alias ls='ls --color=auto'
alias vi=vim

GREP_OPTIONS="--color=auto"
alias grep='grep --color'
alias egrep='egrep --color'
alias fgrep='fgrep --color'
EOF

sed -i 's@^"syntax on@syntax on@' /etc/vim/vimrc

# PS1
[ -z "$(grep ^PS1 ~/.bashrc)" ] && echo "PS1='\${debian_chroot:+(\$debian_chroot)}\\[\\e[1;32m\\]\\u@\\h\\[\\033[00m\\]:\\[\\033[01;34m\\]\\w\\[\\033[00m\\]\\$ '" >> ~/.bashrc

# history
[ -z "$(grep history-timestamp ~/.bashrc)" ] && echo "PROMPT_COMMAND='{ msg=\$(history 1 | { read x y; echo \$y; });user=\$(whoami); echo \$(date \"+%Y-%m-%d %H:%M:%S\"):\$user:\`pwd\`/:\$msg ---- \$(who am i); } >> /tmp/\`hostname\`.\`whoami\`.history-timestamp'" >> ~/.bashrc

# /etc/security/limits.conf
[ -e /etc/security/limits.d/*nproc.conf ] && rename nproc.conf nproc.conf_bk /etc/security/limits.d/*nproc.conf
[ -z "$(grep 'session required pam_limits.so' /etc/pam.d/common-session)" ] && echo "session required pam_limits.so" >> /etc/pam.d/common-session
sed -i '/^# End of file/,$d' /etc/security/limits.conf
cat >> /etc/security/limits.conf <<EOF
# End of file
* soft nproc 1000000
* hard nproc 1000000
* soft nofile 1000000
* hard nofile 1000000
root soft nproc 1000000
root hard nproc 1000000
root soft nofile 1000000
root hard nofile 1000000
EOF

# /etc/hosts
[ "$(hostname -i | awk '{print $1}')" != "127.0.0.1" ] && sed -i "s@127.0.0.1.*localhost@&\n127.0.0.1 $(hostname)@g" /etc/hosts

# Set timezone
rm -rf /etc/localtime
ln -s /usr/share/zoneinfo/${timezone} /etc/localtime

# /etc/sysctl.conf
[ -z "$(grep 'fs.file-max' /etc/sysctl.conf)" ] && cat >> /etc/sysctl.conf << EOF
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
EOF
sysctl -p

sed -i 's@^ACTIVE_CONSOLES.*@ACTIVE_CONSOLES="/dev/tty[1-2]"@' /etc/default/console-setup
locale-gen en_US.UTF-8
[ -d "/var/lib/locales/supported.d" ] && echo "en_US.UTF-8 UTF-8" > /var/lib/locales/supported.d/local
cat > /etc/default/locale << EOF
LANG=en_US.UTF-8
LANGUAGE=en_US:en
EOF

# ufw
if [ "${firewall_flag}" == 'y' ]; then
  ufw allow 22/tcp
  [ "${ssh_port}" != "22" ] && ufw allow ${ssh_port}/tcp
  ufw allow 80/tcp
  ufw allow 443/tcp
  ufw --force enable
else
  ufw --force disable
fi
systemctl restart rsyslog ssh

. /etc/profile
. ~/.bashrc
