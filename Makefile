.PHONY: help
	.DEFAULT_GOAL := help

VERSION := . ./VERSION

help: ## show this message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

codebuild-project: ## creates an aws codebuild project
	$(VERSION) && cd deploy/codebuild/terraform && terraform apply -auto-approve

docker-build: ## build the docker image
	$(VERSION) && docker build -f $$DOCKERFILE -t $${REGISTRY}/$${IMAGE_NAME}:$${IMAGE_VERSION} .

tag: ## tag the docker image

docker-push: tag ## push the docker image
	$(VERSION) && docker push $${REGISTRY}/$${IMAGE_NAME}:$${IMAGE_VERSION}
