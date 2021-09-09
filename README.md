# NodeStatus-client-go

The client of NodeStatus written in Golang

## 使用说明

请直接下载[release](https://github.com/cokemine/nodestatus-client-go/releases)下的对应平台的二进制文件。

运行时需传入客户端对应参数。

假设你的服务端地址是`https://tz.mydomain.com`，客户端用户名`username`，密码`password`

你可以这样运行

```shell
mkdir -p /usr/local/NodeStatus/client/
cd /tmp && wget "https://github.com/cokemine/nodestatus-client-go/releases/latest/download/status-client_linux_amd64.tar.gz"
tar -zxvf status-client_linux_amd64.tar.gz status-client
mv status-client /usr/local/NodeStatus/client/
chmod +x /usr/local/NodeStatus/client/status-client
echo 'DSN="wss://username:password@tz.mydomain.com"' > /usr/local/NodeStatus/client/config.conf
wget https://raw.githubusercontent.com/cokemine/nodestatus-client-go/master/service/status-client.service -P /usr/lib/systemd/system/
systemctl enable status-client
systemctl start status-client
systemctl status status-client
```

## CLI Options

```bash
  -dsn string
        Input DSN, format: ws(s)://username:password@host
  -h string
        Input the host of the server
  -interval float
        Input the INTERVAL (default 1.5)
  -p string
        Input the client's password
  -u string
        Input the client's username
  -vnstat
        Use vnstat for traffic statistics, linux only
```

