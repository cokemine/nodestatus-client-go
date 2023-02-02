package main

import (
	"fmt"
	"github.com/cokemine/ServerStatus-goclient/pkg/status"
	"github.com/gorilla/websocket"
	"github.com/urfave/cli/v2"
	"github.com/vmihailenco/msgpack/v5"
	"log"
	"net/url"
	"os"
	"strings"
	"time"
)

var (
	SERVER   string
	USER     string
	PASSWORD string
	DSN      string
	INTERVAL float64
	VNSTAT   bool
	auth     []byte

	version string
)

type Identify struct {
	Username string `msgpack:"username"`
	Password string `msgpack:"password"`
}

type NodeStatus struct {
	Uptime      uint64  `msgpack:"uptime"`
	Load        float64 `msgpack:"load"`
	MemoryTotal uint64  `msgpack:"memory_total"`
	MemoryUsed  uint64  `msgpack:"memory_used"`
	SwapTotal   uint64  `msgpack:"swap_total"`
	SwapUsed    uint64  `msgpack:"swap_used"`
	HddTotal    uint64  `msgpack:"hdd_total"`
	HddUsed     uint64  `msgpack:"hdd_used"`
	CPU         float64 `msgpack:"cpu"`
	NetworkTx   uint64  `msgpack:"network_tx"`
	NetworkRx   uint64  `msgpack:"network_rx"`
	NetworkIn   uint64  `msgpack:"network_in"`
	NetworkOut  uint64  `msgpack:"network_out"`
	Online4     bool    `msgpack:"online4"`
	Online6     bool    `msgpack:"online6"`
}

func connect() {
	socket, _, err := websocket.DefaultDialer.Dial(SERVER+"/connect", nil)
	if err != nil {
		log.Println("Caught Exception:", err.Error())
		time.Sleep(5 * time.Second)
		return
	}
	defer func(socket *websocket.Conn) {
		_ = socket.Close()
		time.Sleep(5 * time.Second)
	}(socket)
	_, buf, err := socket.ReadMessage()
	if err != nil {
		return
	}
	message := status.BytesToString(buf)
	log.Println(message)
	if !strings.Contains(message, "Authentication required") {
		return
	}
	_ = socket.WriteMessage(websocket.BinaryMessage, auth)
	_, buf, _ = socket.ReadMessage()
	message = status.BytesToString(buf)
	log.Println(message)
	if !strings.Contains(message, "Authentication successful") {
		return
	}
	if !strings.Contains(message, "You are connecting via") {
		_, buf, _ = socket.ReadMessage()
		message = status.BytesToString(buf)
		log.Println(message)
	}
	timer := 0.0
	checkIP := 0
	if strings.Contains(message, "IPv4") {
		checkIP = 6
	} else if strings.Contains(message, "IPv6") {
		checkIP = 4
	} else {
		return
	}

	go func(socket *websocket.Conn) {
		for {
			if _, _, err := socket.NextReader(); err != nil {
				_ = socket.Close()
				break
			}
		}
	}(socket)

	item := NodeStatus{}

	for {
		CPU := status.Cpu(INTERVAL)
		var netIn, netOut, netRx, netTx uint64
		if !VNSTAT {
			netIn, netOut, netRx, netTx = status.Traffic(INTERVAL)
		} else {
			_, _, netRx, netTx = status.Traffic(INTERVAL)
			netIn, netOut, err = status.TrafficVnstat()
			if err != nil {
				log.Println("Please check if vnStat is installed")
			}
		}
		memoryTotal, memoryUsed, swapTotal, swapUsed := status.Memory()
		hddTotal, hddUsed := status.Disk(INTERVAL)
		uptime := status.Uptime()
		load := status.Load()
		item.CPU = CPU
		item.Load = load
		item.Uptime = uptime
		item.MemoryTotal = memoryTotal
		item.MemoryUsed = memoryUsed
		item.SwapTotal = swapTotal
		item.SwapUsed = swapUsed
		item.HddTotal = hddTotal
		item.HddUsed = hddUsed
		item.NetworkRx = netRx
		item.NetworkTx = netTx
		item.NetworkIn = netIn
		item.NetworkOut = netOut
		if timer <= 0 {
			if checkIP == 4 {
				item.Online4 = status.Network(checkIP)
				item.Online6 = true
			} else if checkIP == 6 {
				item.Online6 = status.Network(checkIP)
				item.Online4 = true
			}
			timer = 150.0
		}
		timer -= INTERVAL
		data, _ := msgpack.Marshal(item)
		err = socket.WriteMessage(websocket.BinaryMessage, data)
		if err != nil {
			log.Println(err.Error())
			break
		}
	}
}

func parseUrl(host string) {
	u, err := url.Parse(host)
	if err != nil {
		log.Println("Please check the host or dsn you input")
		os.Exit(1)
	}
	SERVER = fmt.Sprintf("%s://%s", strings.Replace(u.Scheme, "http", "ws", 1), u.Host)
	if u.User.Username() != "" {
		USER = u.User.Username()
	}
	password, ok := u.User.Password()
	if password != "" && ok {
		PASSWORD = password
	}
}

func main() {
	app := &cli.App{
		Name:    "NodeStatus-Client",
		Usage:   "The client of NodeStatus",
		Version: version,
		Flags: []cli.Flag{
			&cli.StringFlag{
				Name:        "server",
				Aliases:     []string{"s"},
				Usage:       "server address",
				Destination: &SERVER,
			},
			&cli.StringFlag{
				Name:        "username",
				Aliases:     []string{"u"},
				Usage:       "client username",
				Destination: &USER,
			},
			&cli.StringFlag{
				Name:        "password",
				Aliases:     []string{"p"},
				Usage:       "client password",
				Destination: &PASSWORD,
			},
			&cli.StringFlag{
				Name:        "dsn",
				Aliases:     []string{"d"},
				Usage:       "DSN, format: ws(s)://username:password@yourdomain.com",
				Destination: &DSN,
			},
			&cli.Float64Flag{
				Name:        "interval",
				Aliases:     []string{"i"},
				Usage:       "interval of data collection",
				Value:       1.5,
				Destination: &INTERVAL,
			},
			&cli.BoolFlag{
				Name:        "vnstat",
				Usage:       "use vnstat to collect traffic, Linux Only",
				Value:       false,
				Destination: &VNSTAT,
			},
		},
		Action: func(*cli.Context) error {
			if SERVER != "" {
				parseUrl(SERVER)
			}
			if DSN != "" {
				parseUrl(DSN)
			}
			if SERVER == "" || USER == "" || PASSWORD == "" {
				log.Println("SERVER, USERNAME, PASSWORD can not be blank!")
				os.Exit(1)
			}
			auth, _ = msgpack.Marshal(&Identify{Username: USER, Password: PASSWORD})
			for {
				connect()
			}
		},
	}

	if err := app.Run(os.Args); err != nil {
		log.Fatal(err)
	}
}
