#!/usr/bin/env bash
#=================================================
#  System Required: CentOS/Debian/ArchLinux with Systemd Support
#  Description: NodeStatus Client-Go
#  Version: v1.0.1
#  Author: Kagurazaka Mizuki
#=================================================

Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[信息]${Font_color_suffix}"
Error="${Red_font_prefix}[错误]${Font_color_suffix}"
Tip="${Green_font_prefix}[注意]${Font_color_suffix}"

is_update=0

function check_sys() {
  if [[ -f /etc/redhat-release ]]; then
    release="centos"
  elif grep -q -E -i "debian|ubuntu" /etc/issue; then
    release="debian"
  elif grep -q -E -i "centos|red hat|redhat" /etc/issue; then
    release="centos"
  elif grep -q -E -i "Arch|Manjaro" /etc/issue; then
    release="arch"
  elif grep -q -E -i "debian|ubuntu" /proc/version; then
    release="debian"
  elif grep -q -E -i "centos|red hat|redhat" /proc/version; then
    release="centos"
  elif grep -q -E -i "alpine" /proc/version; then
    release="alpine"
  else
    echo -e "NodeStatus Client 暂不支持该 Linux 发行版"
    exit 1
  fi
  bit=$(uname -m)
}

function install_dependencies() {
  case ${release} in
  centos)
    yum update -y
    yum install -y $depend
    ;;
  debian)
    apt-get update -y
    apt-get install -y $depend
    ;;
  arch)
    pacman -Syu --noconfirm $depend
    ;;
  alpine)
    apk --no-cache add $depend
    ;;
  *)
    exit 1
    ;;
  esac
}

# 检测缺少依赖并补全
check_sys
if [[ $release = "alpine" ]]; then
depends=("curl" "wget" "nohup" "openrc")
else
depends=("curl" "wget")
fi
depend=""
for i in "${!depends[@]}"; do
	now_depend="${depends[$i]}"
	if [ ! -x "$(command -v $now_depend)" ]; then
		depend="$now_depend $depend"
	fi
  done
if [ "$depend" ]; then
install_dependencies
fi
function check_arch() {
  case ${bit} in
  x86_64)
    arch=amd64
    ;;
  i386)
    arch=386
    ;;
  aarch64 | aarch64_be | arm64 | armv8b | armv8l)
    arch=arm64
    ;;
  arm | armv6l | armv7l | armv5tel | armv5tejl)
    arch=arm
    ;;
  mips | mips64)
    arch=mips
    ;;
  *)
    exit 1
    ;;
  esac
}

while [[ $# -gt 0 ]]; do
  case $1 in
  -d | --dsn)
    dsn="$2"
    shift
    shift
    ;;
  uninstall)
    action=2
    shift
    ;;
  update)
    action=1
    shift
    ;;
  *)
    action=0
    shift
    ;;
  esac
done

# alpine
  check_sys
  if [[ $release == "alpine" ]];then 
  check_arch
  mkdir -p /usr/local/NodeStatus/client/
  cd /usr/local/NodeStatus/client/ 
  tar -zxvf <(wget -qO- "https://github.com/cokemine/nodestatus-client-go/releases/latest/download/status-client_linux_${arch}.tar.gz") status-client
  chmod +x /usr/local/NodeStatus/client/status-client
  echo "#!/sbin/openrc-run
start() {
nohup /usr/local/NodeStatus/client/status-client --dsn ${dsn} >/dev/null 2>&1 &
}

stop() {
kill -9 ""$""(ps -A|grep status-client) >/dev/null 2>&1
}" >/etc/init.d/status-client
chmod +x /etc/init.d/status-client
rc-update add status-client
rc-service status-client start
exit 1
fi


function check_pid() {
  PID=$(pgrep -f "status-client")
}


function input_dsn() {
  echo -e "${Info} 请输入服务端的 DSN, 格式为 “ws(s)://username:password@yourdomain”"
  read -re dsn
}

function install_client() {
  case ${bit} in
  x86_64)
    arch=amd64
    ;;
  i386)
    arch=386
    ;;
  aarch64 | aarch64_be | arm64 | armv8b | armv8l)
    arch=arm64
    ;;
  arm | armv6l | armv7l | armv5tel | armv5tejl)
    arch=arm
    ;;
  mips | mips64)
    arch=mips
    ;;
  *)
    exit 1
    ;;
  esac
  mkdir -p /usr/local/NodeStatus/client/
  cd /tmp && wget -N "https://github.com/cokemine/nodestatus-client-go/releases/latest/download/status-client_linux_${arch}.tar.gz"
  tar -zxvf "status-client_linux_${arch}.tar.gz" status-client
  mv status-client /usr/local/NodeStatus/client/
  chmod +x /usr/local/NodeStatus/client/status-client
  [[ -n ${dsn} ]] && echo -e "DSN=\"${dsn}\"" >/usr/local/NodeStatus/client/config.conf
  wget https://raw.githubusercontent.com/cokemine/nodestatus-client-go/master/service/status-client.service -P /usr/lib/systemd/system/
  systemctl enable status-client
  systemctl start status-client
  check_pid
  if [[ -n ${PID} ]]; then
    echo -e "${Info} NodeStatus Client 启动成功！"
  else
    echo -e "${Error} NodeStatus Client 启动失败！"
  fi
}

function uninstall_client() {
  systemctl stop status-client
  systemctl disable status-client
  if [[ ${is_update} == 0 ]]; then
    rm -rf /usr/local/NodeStatus/client/
  else
    rm -rf /usr/local/NodeStatus/client/status-client
  fi
  rm -rf /usr/lib/systemd/system/status-client.service
}

check_sys
action=0

case "${action}" in
0)
  [[ -z ${dsn} ]] && input_dsn
  install_client
  ;;
1)
  is_update=1
  uninstall_client
  install_client
  ;;
2)
  uninstall_client
  ;;
esac