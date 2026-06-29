package status

import (
	"strings"
	"unsafe"
)

var invalidInterface = []string{"lo", "tun", "kube", "docker", "vmbr", "br-", "vnet", "veth"}
var validFs = []string{"ext4", "ext3", "ext2", "reiserfs", "jfs", "btrfs", "fuseblk", "zfs", "simfs", "ntfs", "fat32", "exfat", "xfs", "apfs"}

func BytesToString(b []byte) string {
	if len(b) == 0 {
		return ""
	}
	return unsafe.String(unsafe.SliceData(b), len(b))
}

func checkInterface(name string) bool {
	for _, v := range invalidInterface {
		if strings.Contains(name, v) {
			return false
		}
	}
	return true
}

func checkValidFs(name string) bool {
	for _, v := range validFs {
		if strings.ToLower(name) == v {
			return true
		}
	}
	return false
}
