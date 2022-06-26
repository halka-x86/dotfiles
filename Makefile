.DEFAULT_GOAL := help
SCRIPT_INSTALL := ./install.sh
SCRIPT_DEPLOY := ./deploy.sh

.PHONY: install
install:  ## install
	$(SCRIPT_INSTALL)

.PHONY: deploy
deploy:  ## deploy
	$(SCRIPT_DEPLOY)


.PHONY: help
help:  ## Display this help screen
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'
