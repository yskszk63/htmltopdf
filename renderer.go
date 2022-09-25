package main

import (
	"context"
	"log"
	"os"

	"github.com/chromedp/cdproto/page"
	"github.com/chromedp/chromedp"
)

func render(cx context.Context, chromeBin string, url string) ([]byte, error) {
	log.Printf("make prfile...\n")
	prof, err := os.MkdirTemp("", "prof-")
	if err != nil {
		return nil, err
	}
	defer os.RemoveAll(prof)
	log.Printf("profile: %s\n", prof)

	// ref https://github.com/puppeteer/puppeteer/issues/6776
	opts := append(
		chromedp.DefaultExecAllocatorOptions[:],
		chromedp.UserDataDir(prof),
		chromedp.ExecPath(chromeBin),
		chromedp.NoSandbox,
		chromedp.Flag("disable-setuid-sandbox", true),
		chromedp.DisableGPU,
		chromedp.Flag("single-process", true),
		chromedp.Flag("use-gl", "egl"),
	)

	log.Printf("make exec allocator...\n")
	alloccx, alloccxcancel := chromedp.NewExecAllocator(cx, opts...)
	defer alloccxcancel()

	log.Printf("make context...\n")
	cx2, cxCancel := chromedp.NewContext(alloccx, chromedp.WithLogf(log.Printf), chromedp.WithDebugf(log.Printf), chromedp.WithErrorf(log.Printf))
	defer cxCancel()

	var buf []byte
	actions := []chromedp.Action{
		chromedp.Navigate(url),
		chromedp.ActionFunc(func (cx context.Context) error{
			var err error
			log.Printf("print to pdf...\n")
			buf, _, err = page.PrintToPDF().Do(cx)
			if err != nil {
				return err
			}
			log.Printf("print to pdf...OK\n")
			return nil
		}),
	}
	log.Printf("run...\n")
	if err := chromedp.Run(cx2, actions...); err != nil {
		return nil, err
	}
	log.Printf("run...OK\n")

	return buf, nil
}
