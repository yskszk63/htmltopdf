AWS_PROFILE := default
-include .env

SRCS := main.go

repourl_expr = .values|to_entries[]|.value.resources[]|select(.address == "aws_ecr_repository.ecr")|.values.repository_url
fnname_expr = .values|to_entries[]|.value.resources[]|select(.address == "aws_lambda_function.fn")|.values.function_name

# REF https://commondatastorage.googleapis.com/chromium-browser-snapshots/index.html?prefix=Linux_x64/
CHROMIUM_REV = 1050637

chrome-linux-$(CHROMIUM_REV).zip:
	curl -f 'https://commondatastorage.googleapis.com/chromium-browser-snapshots/Linux_x64/$(CHROMIUM_REV)/chrome-linux.zip' -o$@

chrome-linux-$(CHROMIUM_REV): chrome-linux-$(CHROMIUM_REV).zip
	unzip $<
	mv chrome-linux $@

chrome-linux-$(CHROMIUM_REV).tar.gz: chrome-linux-$(CHROMIUM_REV)
	tar --transform 's/^$</chrome-linux/' -zcvf $@ $<

.PHONY: build
build: chrome-linux-$(CHROMIUM_REV).tar.gz
	docker build --build-arg CHROMIUM_REV=$(CHROMIUM_REV) -t htmltopdf:latest .

.PHONY: apply
apply:
	$(MAKE) -C terraform apply

.PHONY: push
push: build apply
	AWS_PROFILE=$(AWS_PROFILE) aws ecr get-login-password | docker login --username AWS --password-stdin $$(terraform -chdir=terraform show -json|jq -r '$(repourl_expr)')
	docker tag htmltopdf:latest $$(terraform -chdir=terraform show -json|jq -r '$(repourl_expr)'):latest
	docker push $$(terraform -chdir=terraform show -json|jq -r '$(repourl_expr)')
	AWS_PROFILE=$(AWS_PROFILE) aws lambda update-function-code --function-name $$(terraform -chdir=terraform show -json|jq -r '$(fnname_expr)') --image-uri $$(terraform -chdir=terraform show -json|jq -r '$(repourl_expr)'):latest
	AWS_PROFILE=$(AWS_PROFILE) aws lambda wait function-updated --function-name $$(terraform -chdir=terraform show -json|jq -r '$(fnname_expr)')
