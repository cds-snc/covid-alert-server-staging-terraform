.DEFAULT_GOAL := help

help: ## List the targets
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

tfsec: ## Run TFSec scan
	docker run --rm -it -v "$(CURDIR)/server/aws:/src" tfsec/tfsec-alpine:v0.39.26 /src

.PHONY: \
	tfsec \