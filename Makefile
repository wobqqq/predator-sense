SHELL := /bin/bash

SHELLCHECK := docker run --rm -v "$(CURDIR)":/code -w /code koalaman/shellcheck:v0.11.0
BATS := docker run --rm -u "$(shell id -u):$(shell id -g)" -v "$(CURDIR)":/code -w /code bats/bats:1.11.1
FEDORA := docker run --rm -v "$(CURDIR)":/code:ro -w /code fedora:latest

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
