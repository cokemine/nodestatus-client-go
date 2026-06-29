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

# 判断vps地区，大陆服务器使用代理加速下载
if [[ $(curl -m 10 -s ip.ping0.cc/geo | grep '中国') != "" ]]; then
	url="https://ghproxy.com/https://github.com"
  url2="https://ghproxy.com/https://raw.githubusercontent.com"
else
	url="https://github.com"
  url2="https://raw.githubusercontent.com"
fi


# 检测系统发行版
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
# 安装依赖
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

# 检测缺少依赖
check_sys
if [[ $release == "alpine" ]]; then
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
# 有缺少依赖才会执行安装，没有则不会
if [ "$depend" ]; then
  install_dependencies
fi
# 检测系统架构
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
# 检查传入的dsn参数
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

function check_pid() {
  PID=$(pgrep -f "status-client")
}

# alpine操作，其他发行版会跳过这里
check_sys
if [[ $release == "alpine" ]]; then
  mkdir -p /usr/local/NodeStatus/client/
  cd /usr/local/NodeStatus/client/
  tar -zxvf <(wget -qO- "${url}/cokemine/nodestatus-client-go/releases/latest/download/status-client_linux_${arch}.tar.gz") status-client
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
  check_pid
  if [[ -n ${PID} ]]; then
    echo -e "${Info} NodeStatus Client 启动成功！"
  else
    echo -e "${Error} NodeStatus Client 启动失败！"
  fi
  exit 1
fi
# alpine操作到此完成
# 以下是别的Linux发行版操作，没有修改
# 这个pr仅仅增加alpine支持和优化依赖安装步骤

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
  cd /tmp && wget -N "${url}/cokemine/nodestatus-client-go/releases/latest/download/status-client_linux_${arch}.tar.gz"
  tar -zxvf "status-client_linux_${arch}.tar.gz" status-client
  mv status-client /usr/local/NodeStatus/client/
  chmod +x /usr/local/NodeStatus/client/status-client
  [[ -n ${dsn} ]] && echo -e "DSN=\"${dsn}\"" >/usr/local/NodeStatus/client/config.conf
  wget "${url2}/cokemine/nodestatus-client-go/master/service/status-client.service" -O /usr/lib/systemd/system/status-client.service
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
