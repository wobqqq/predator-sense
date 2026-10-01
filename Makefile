SHELL := /bin/bash

RUN := docker compose run --rm --quiet-pull
SHELLCHECK := $(RUN) shellcheck
BATS := HOST_UID=$(shell id -u) HOST_GID=$(shell id -g) $(RUN) bats
FEDORA := $(RUN) fedora

SCRIPTS := install.sh uninstall.sh $(wildcard bin/*) $(wildcard scripts/*.sh) tests/helpers.bash

.PHONY: lint test build ready

lint:
	$(SHELLCHECK) -S style $(SCRIPTS) $(wildcard tests/*.bats)
	@for f in $(SCRIPTS); do bash -n "$$f" || exit 1; done

test:
	$(BATS) tests

build:
	$(FEDORA) bash scripts/build-driver.sh

ready: lint test build
