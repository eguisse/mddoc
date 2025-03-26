#
# Makefile for mddoc project
#
#
# Copyright (c) 2018 2020, Emmanuel GUISSE
#
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# import config.
# You can change the default config with `make cnf="config_special.env" build`
cnf ?= config.env
include $(cnf)
export $(shell sed 's/=.*//' $(cnf))

# import deploy config
# You can change the default deploy config with `make cnf="deploy_special.env" release`
#dpl ?= deploy.env
#include $(dpl)
#export $(shell sed 's/=.*//' $(dpl))

SHELL := /bin/bash
# grep the version from the mix file
VERSION=$(shell cat VERSION)
CURRENT_DIR := $(CURDIR)
ifeq ($(strip $(PROJECT_DIR)), )
PROJECT_DIR := $(CURRENT_DIR)
endif
export PROJECT_DIR
export CURRENT_DIR
export VERSION

# HELP
# This will output the help for each task
# thanks to https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
.PHONY: help

help: ## This help.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help


print-env:  ## print environment variables
	echo "PROJECT_DIR: $(PROJECT_DIR)"
	echo "CURRENT_DIR: $(CURRENT_DIR)"
	echo "VERSION: $(VERSION)"
	echo "CURDIR: $(CURDIR)"

clean-py-venv:  ## Delete python virtual environment
	@echo 'start clean-venv'
	rm -Rf $(PROJECT_DIR)/venv

build-py-venv: clean-py-venv   ## Build python virtual environment
	@echo 'start build-venv'
	python3 -m venv $(PROJECT_DIR)/venv
	source $(PROJECT_DIR)/venv/bin/activate && pip3 install wheel && pip3 install -r requirements.txt


run-docker-img-mddoc_build:    ## Run Docker image mddoc_build used for compilation
	docker run -it --rm --net=host --env-file $(cnf) -v "$(CURRENT_DIR):/mnt:rw" "mddoc_build:latest" bash

# DOCKER TASKS
# Build the container
build-docker-image:  ## Build the docker image
	@echo 'start build in $(PROJECT_DIR)'
	docker build $(DOCKER_BUILD_OPT) \
	-t "$(IMAGE_NAME):$(VERSION)-snapshot"  \
	--build-arg VERSION \
	--build-arg PANDOC_VERSION \
	--build-arg WKHTMLTOPDF_VERSION \
	$(PROJECT_DIR)

build-docker-image-nc:  ## Build the docker image without caching
	docker build $(DOCKER_BUILD_OPT) --no-cache \
	-t "$(IMAGE_NAME):$(VERSION)-snapshot"  \
	--build-arg VERSION \
	--build-arg PANDOC_VERSION \
	--build-arg WKHTMLTOPDF_VERSION \
	$(PROJECT_DIR)

build: build-docker-image  ## Build all
	@echo 'start build'

publish: tag-latest  tag-version  ## Publish the `latest` tagged container to docker hub
	@echo 'publish latest to $(DOCKER_REPO)'
	docker push $(DOCKER_REPO)/$(IMAGE_NAME):latest
	@echo 'publish $(VERSION) to $(DOCKER_REPO)'
	docker push $(DOCKER_REPO)/$(IMAGE_NAME):$(VERSION)

# Docker tagging
tag: tag-latest tag-version ## Generate container tags for the `{version}` ans `latest` tags

tag-latest: ## Generate container `latest` tag
	@echo 'create tag latest'
	docker tag "$(IMAGE_NAME):$(VERSION)-snapshot" "$(DOCKER_REPO)/$(IMAGE_NAME):latest"

tag-version: ## Generate container `{version}` tag
	@echo 'create tag $(VERSION)'
	docker tag "$(IMAGE_NAME):$(VERSION)-snapshot" "$(DOCKER_REPO)/$(IMAGE_NAME):$(VERSION)"

# testing

clean:  ## delete test build files
	rm -Rf $(PROJECT_DIR)/build

test-docker-pdf:  ## Run docker container for test convert to pdf
	@echo 'start test-docker-pdf for project path $(REPO_DOC_TEST)'
	docker run -it --rm -v "$(PROJECT_DIR):/mnt:rw" "$(IMAGE_NAME):$(VERSION)-snapshot" bash makepdf.sh -d docs -b build -o build/mddoc-docker-test.pdf -r src/resources -f mddoc.yml

test-docker-bash:  ## run docker container and execute bash
	@echo 'start test-docker-bash for project path $(REPO_DOC_TEST)'
	docker run -it --rm -v "$(CURRENT_DIR):/mnt:rw" "$(IMAGE_NAME):$(VERSION)-snapshot" bash

test-md: clean  ## test markdown transformation
	source venv/bin/activate && export PYTHONPATH=$(CURRENT_DIR)/src && python3 src/makepdf.py -f $(CURRENT_DIR)/mddoc.yml -p $(CURRENT_DIR) -b $(CURRENT_DIR)/build -d docs -r src/resources

test-docker-site:  ## Run docker container for test convert to html site
	@echo 'start test-docker-pdf for project path $(REPO_DOC_TEST)'
	docker run -it --rm -v "$(PROJECT_DIR):/mnt:rw" "$(IMAGE_NAME):$(VERSION)-snapshot" mkdocs build -f build/mkdocs.yaml

test-docker-site-server:  ## Run docker container as a http server to access to the generated sited
	@echo 'start test-docker-pdf for project path $(REPO_DOC_TEST)'
	docker run -it --rm -v "$(PROJECT_DIR):/mnt:rw" -p "8000:8000" "$(IMAGE_NAME):$(VERSION)-snapshot" mkdocs serve -f build/mkdocs.yaml

