package main

import (
	"context"
	"fmt"
	"io"
	"log"
	"os"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	echolambda "github.com/awslabs/aws-lambda-go-api-proxy/echo"
	"github.com/labstack/echo/v4"
	"github.com/labstack/echo/v4/middleware"
)

func isEnvVarDefined(name string) bool {
	_, found := os.LookupEnv(name)
	return found
}

func isLambda() bool {
	//return isEnvVarDefined("_LAMBDA_SERVER_PORT") && isEnvVarDefined("AWS_LAMBDA_RUNTIME_API")
	return isEnvVarDefined("AWS_LAMBDA_RUNTIME_API")
}

func chromeBin() string {
	bin, found := os.LookupEnv("CHROME_BIN")
	if found {
		return bin
	}
	return "/opt/chrome-linux/chrome"
}

func route(e *echo.Echo) error {
	chrome := chromeBin()
	e.Use(middleware.Logger())

	e.GET("/", func(c echo.Context) error {
		url := c.QueryParam("q")
		if url == "" {
			c.Response().WriteHeader(400)
			c.Response().Write([]byte("no query parameter `q` specified."))
			return nil
		}

		buf, err := render(context.TODO(), chrome, url)
		if err != nil {
			return err
		}
		c.Response().Header().Add("content-type", "application/pdf")
		c.Response().Write(buf)
		return nil
	})

	e.POST("/", func(c echo.Context) error {
		fp, err := os.CreateTemp("", "*.html")
		if err != nil {
			return err
		}
		defer os.Remove(fp.Name())

		io.Copy(fp, c.Request().Body)

		buf, err := render(context.TODO(), chrome, fmt.Sprintf("file://%s", fp.Name()))
		c.Response().Header().Add("content-type", "application/pdf")
		c.Response().Write(buf)
		return nil
	})

	return nil
}

func main() {
	e := echo.New()

	if err := route(e); err != nil {
		log.Fatal(err)
	}

	if !isLambda() {
		e.Start(":8080")
		return
	}


	proxy := echolambda.NewV2(e)
	lambda.Start(func(c context.Context, event events.APIGatewayV2HTTPRequest) (events.APIGatewayV2HTTPResponse, error) {
		return proxy.ProxyWithContext(c, event)
	})
}
