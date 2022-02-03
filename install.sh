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
  else
    echo -e "NodeStatus Client 暂不支持该 Linux 发行版"
    exit 1
  fi
  bit=$(uname -m)
}

function check_pid() {
  PID=$(pgrep -f "status-client")
}

function install_dependencies() {
  case ${release} in
  centos)
    yum install -y wget curl
    ;;
  debian)
    apt-get update -y
    apt-get install -y wget curl
    ;;
  arch)
    pacman -Syu --noconfirm wget curl
    ;;
  *)
    exit 1
    ;;
  esac
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
  [[ ${is_update} == 0 ]] && echo -e "DSN=\"${dsn}\"" >/usr/local/NodeStatus/client/config.conf
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
case "$1" in
uninstall)
  uninstall_client
  ;;
update)
  is_update=1
  uninstall_client
  install_client
  ;;
*)
  install_dependencies
  input_dsn
  install_client
  ;;
esac
