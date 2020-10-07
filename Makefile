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
CURRENT_DIR=$(shell pwd)
ifeq ($(strip $(PROJECT_DIR)), )
PROJECT_DIR := $(CURRENT_DIR)
endif
export PROJECT_DIR

# HELP
# This will output the help for each task
# thanks to https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
.PHONY: help

help: ## This help.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help

clean-py-venv:  ## Delete python virtual environment
	@echo 'start clean-venv'
	rm -Rf $(PROJECT_DIR)/venv

build-py-venv: clean-py-venv   ## Build python virtual environment
	@echo 'start build-venv'
	python3.8 -m venv $(PROJECT_DIR)/venv
	source $(PROJECT_DIR)/venv/bin/activate && pip3 install wheel && pip3 install -r requirements.txt

clean-wkhtmltopdf:
	rm -Rf build/wp

build-wkhtmltopdf-requirments:  ## install requirements to build wkhtmltopdf
	sudo apt install -y python-yaml docker.io vagrant virtualbox p7zip-full python3.8-venv

# doc ref: https://github.com/wkhtmltopdf/packaging
build-wkhtmltopdf: clean-wkhtmltopdf build-py-venv  ## Build wkhtmltopdf old
	@echo 'start build-wkhtmltopd'
	WP_DIR=$(PROJECT_DIR)/build/wp
	mkdir -p $(PROJECT_DIR)/build/wp
	cd $(PROJECT_DIR)/build/wp && git clone https://github.com/wkhtmltopdf/wkhtmltopdf.git
	cd $(PROJECT_DIR)/build/wp/wkhtmltopdf && git submodule init && git submodule update
	cd $(PROJECT_DIR)/build/wp && wget https://github.com/wkhtmltopdf/packaging/archive/0.12.6-3.tar.gz && tar -zxf 0.12.6-3.tar.gz
	source venv/bin/activate &&  cd $(PROJECT_DIR)/build/wp/packaging-0.12.6-3 && python build package-docker focal-amd64 $(PROJECT_DIR)/build/wp/wkhtmltopdf
	cp $(PROJECT_DIR)/build/wp/packaging-0.12.6-3/targets/wkhtmltox_*.focal_amd64.deb $(PROJECT_DIR)/build/wkhtmltox.focal_amd64.deb
	gsutil -m cp -r build/wkhtmltox.focal_amd64.deb gs://engineering-doc-egitc-com/dist/
	gsutil acl ch -r -u AllUsers:R gs://engineering-doc-egitc-com/dist/wkhtmltox.focal_amd64.deb
	# http://storage.googleapis.com/engineering-doc-egitc-com/dist/wkhtmltox.focal_amd64.deb

build-plantuml:  ## Build plantuml.jar
	@echo 'start build-plantuml'
	mkdir -p build/plantuml
	cd $(PROJECT_DIR) && ./build_plantuml.sh

run-docker-img-mddoc_build:    ## Run Docker image mddoc_build used for compilation
	docker run -it --rm --net=host --env-file $(cnf) -v "$(CURRENT_DIR):/mnt:rw" "mddoc_build:latest" bash

# DOCKER TASKS
# Build the container
build-docker-image:  ## Build the docker image
	@echo 'start build in $(PROJECT_DIR)'
	docker build $(DOCKER_BUILD_OPT) -t mddoc $(PROJECT_DIR)

build-docker-image-nc: ## Build the docker image without caching
	docker build $(DOCKER_BUILD_OPT) --no-cache -t mddoc $(PROJECT_DIR)

build: venv build-wkhtmltopdf build-plantuml build-docker-image  ## Build all
	@echo 'start build'

publish: tag-latest ## Publish the `latest` taged container to ECR
	@echo 'publish latest to $(DOCKER_REPO)'
	docker push $(DOCKER_REPO)/$(APP_NAME):latest
	@echo 'publish $(VERSION) to $(DOCKER_REPO)'
	docker push $(DOCKER_REPO)/$(APP_NAME):$(VERSION)

# Docker tagging
tag: tag-latest tag-version ## Generate container tags for the `{version}` ans `latest` tags

tag-latest: ## Generate container `{version}` tag
	@echo 'create tag latest'
	docker tag $(APP_NAME) $(DOCKER_REPO)/$(APP_NAME):latest

tag-version: ## Generate container `latest` tag
	@echo 'create tag $(VERSION)'
	docker tag $(APP_NAME) $(DOCKER_REPO)/$(APP_NAME):$(VERSION)

# testing

clean:  ## delete test build files
	rm -Rf $(PROJECT_DIR)/build

test-docker-pdf:  ## Run docker container for test convert to pdf
	@echo 'start test-docker-pdf for project path $(REPO_DOC_TEST)'
	docker run -it --rm -v "$(PROJECT_DIR):/mnt:rw" "mddoc:latest" bash makepdf.sh -d docs -b build -o build/mddoc-docker-test.pdf -r src/resources -f mddoc.yml

test-docker-bash:  ## run docker container and execute bash
	@echo 'start test-docker-bash for project path $(REPO_DOC_TEST)'
	docker run -it --rm -v "$(CURRENT_DIR):/mnt:rw" "mddoc:latest" bash

test-docker-site:  ## Run docker container for test convert to site
	@echo 'start test-docker-site for project path $(REPO_DOC_TEST)'
	rm -Rf $(CURRENT_DIR)/site
	mkdir $(CURRENT_DIR)/site
	docker run -it --rm -v "$(CURRENT_DIR):/mnt:rw" "mddoc:latest" bash makesite.sh -d docs -b build -r src/resources -f mddoc.yml -s site


test-docker-pdfandsite:  ## Run docker container for test convert to pdf
	@echo 'start test-docker-pdf for project path $(REPO_DOC_TEST)'
	rm -Rf $(CURRENT_DIR)/site
	mkdir $(CURRENT_DIR)/site
	docker run -it --rm -v "$(PROJECT_DIR):/mnt:rw" "mddoc:latest" bash makepdfandsite.sh -d docs -b build -o build/mddoc-docker-test.pdf -r src/resources -f mddoc.yml -s site

test-md: clean  ## test markdown transformation
	source venv/bin/activate && export PYTHONPATH=$(CURRENT_DIR)/src && python3 src/makepdf.py -f $(CURRENT_DIR)/mddoc.yml -p $(CURRENT_DIR) -b $(CURRENT_DIR)/build -d docs -r src/resources


