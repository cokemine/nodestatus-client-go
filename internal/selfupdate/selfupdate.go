package selfupdate

import (
	"archive/zip"
	"bytes"
	"context"
	"fmt"
	"github.com/google/go-github/v50/github"
	"github.com/hashicorp/go-version"
	"github.com/minio/selfupdate"
	"io"
	"log"
	"net/http"
	"path"
	"runtime"
	"strings"
)

func DoUpdate(curVer string) error {
	client := github.NewClient(nil)
	releases, _, err := client.Repositories.ListReleases(context.Background(), "cokemine", "nodestatus-client-go", nil)
	if err != nil {
		return err
	}
	if len(releases) == 0 {
		return fmt.Errorf("no releases found")
	}
	latestTag := releases[0].GetName()
	latest, err := version.NewVersion(latestTag)
	if err != nil {
		return err
	}
	current, err := version.NewVersion(curVer)
	if err != nil {
		return err
	}
	if latest.GreaterThanOrEqual(current) {
		log.Println("current version is latest, no need to update")
		return nil
	}
	log.Printf("current version is %s, latest version is %s, updating...", current, latest)

	assets := releases[0].Assets

	os := runtime.GOOS
	arch := runtime.GOARCH

	var fileName string
	var downloadUrl string

	for _, asset := range assets {
		name := asset.GetName()
		if strings.Contains(name, os) && strings.Contains(name, arch) {
			fileName = name
			downloadUrl = asset.GetBrowserDownloadURL()
			break
		}
	}
	if downloadUrl == "" {
		return fmt.Errorf("no download url found")
	}
	resp, err := http.Get(downloadUrl)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	if path.Ext(fileName) == ".zip" {
		buff := bytes.NewBuffer([]byte{})
		size, err := io.Copy(buff, resp.Body)
		if err != nil {
			return err
		}

		reader := bytes.NewReader(buff.Bytes())
		zipReader, err := zip.NewReader(reader, size)
		if err != nil {
			return err
		}

		for _, file := range zipReader.File {
			if file.Name == "status-client.exe" {
				rc, err := file.Open()
				if err != nil {
					return err
				}
				defer rc.Close()
				err = selfupdate.Apply(rc, selfupdate.Options{})
				if err != nil {
					return err
				}
			}
		}

	} else {
		if err != nil {
			return err
		}
	}
	return nil
}
