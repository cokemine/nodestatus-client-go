# NodeStatus-client-go

The client of NodeStatus written in Go

## 使用说明

请直接下载 [release](https://github.com/cokemine/nodestatus-client-go/releases) 下的对应平台的二进制文件。

运行时需传入客户端对应参数。

假设你的服务端地址是 `https:/status.mydomain.com`，客户端用户名 `username`，密码 `password`

你也可以使用一键脚本进行安装
```shell
wget https://raw.githubusercontent.com/cokemine/nodestatus-client-go/master/install.sh
#安装
bash install.sh
#卸载
bash install.sh uninstall
# 更新
bash install.sh update
# 安装时指定 DSN
bash install.sh install --dsn "wss://username:password@status.mydomain.com"
```
或者手动安装
```shell
mkdir -p /usr/local/NodeStatus/client/
cd /tmp && wget "https://github.com/cokemine/nodestatus-client-go/releases/latest/download/status-client_linux_amd64.tar.gz"
tar -zxvf status-client_linux_amd64.tar.gz status-client
mv status-client /usr/local/NodeStatus/client/
chmod +x /usr/local/NodeStatus/client/status-client
echo 'DSN="wss://username:password@status.mydomain.com"' > /usr/local/NodeStatus/client/config.conf
wget https://raw.githubusercontent.com/cokemine/nodestatus-client-go/master/service/status-client.service -P /usr/lib/systemd/system/
systemctl enable status-client
systemctl start status-client
systemctl status status-client
```

对于 Arch Linux 用户，也可以从 AUR 获取 [nodestatus-client-go](https://aur.archlinux.org/packages/nodestatus-client-go) 来安装。
这里假设你使用 `yay` 作为 AUR Helper
```shell
yay -S nodestatus-client-go
cp /etc/nodestatus/client/config.conf.example  /etc/nodestatus/client/config.conf
# edit your DSN in /etc/nodestatus/client/config.conf
systemctl enable --now nodestatus-client
```

## CLI Options

```bash
NAME:
   NodeStatus-Client - The client of NodeStatus

USAGE:
   NodeStatus-Client [global options] command [command options] [arguments...]

VERSION:
   v1.0.9-next

COMMANDS:
   help, h  Shows a list of commands or help for one command

GLOBAL OPTIONS:
   --server value, -s value    server address
   --username value, -u value  client username
   --password value, -p value  client password
   --dsn value, -d value       DSN, format: ws(s)://username:password@yourdomain.com
   --interval value, -i value  interval of data collection (default: 1.5)
   --vnstat                    use vnstat to collect traffic, Linux Only (default: false)
   --help, -h                  show help
   --version, -v               print the version
```

