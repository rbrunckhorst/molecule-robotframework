# Copyright 2020-2021 Sine Nomine Associates

.PHONY: help init lint import test docs sdist wheel rpm deb upload clean distclean

ROLE_VERSION=1.7.0
ROLE_REPO=https://github.com/meffie/ansible-role-robotframework.git
PYTHON3=python3
BIN=.venv/bin
PIP=$(BIN)/pip
PYTHON=$(BIN)/python
PYFLAKES=$(BIN)/pyflakes
YAMLLINT=$(BIN)/yamllint
PYTEST=$(BIN)/pytest
TWINE=$(BIN)/twine
BASH=/bin/bash

help:
	@echo "usage: make <target>"
	@echo ""
	@echo "targets:"
	@echo "  init       create python virtual env"
	@echo "  lint       run linter"
	@echo "  import     import external ansible roles"
	@echo "  test       run tests"
	@echo "  docs       build html docs"
	@echo "  sdist      create source distribution"
	@echo "  wheel      create wheel distribution"
	@echo "  rpm        create rpm package"
	@echo "  deb        create deb package"
	@echo "  upload     upload to pypi.org"
	@echo "  clean      remove generated files"
	@echo "  distclean  remove generated files and virtual env"

.venv/bin/activate: requirements.txt Makefile
	$(PYTHON3) -m venv .venv
	$(PIP) install -U pip wheel
	$(PIP) install -r requirements.txt
	$(PIP) install -e .
	touch .venv/bin/activate

.config/molecule/config.yml: Makefile
	mkdir -p .config/molecule
	@echo "---" > .config/molecule/config.yml
	@echo "driver:" >> .config/molecule/config.yml
	@echo "  name: vagrant" >> .config/molecule/config.yml

init: .venv/bin/activate .config/molecule/config.yml

lint: init
	$(PYFLAKES) src/*/*.py
	$(PYFLAKES) tests/*.py
	$(YAMLLINT) src/*/playbooks/*.yml
	$(YAMLLINT) tests/molecule/default/*.yml
	$(PYTHON) setup.py -q checkdocs

import:
	mkdir -p src/molecule_robotframework/playbooks/roles/robotframework
	git clone $(ROLE_REPO) /tmp/ansible-role-robotframework.git
	(cd /tmp/ansible-role-robotframework.git && git archive $(ROLE_VERSION)) | \
	  (cd src/molecule_robotframework/playbooks/roles/robotframework && tar xf -)
	rm -rf src/molecule_robotframework/playbooks/roles/robotframework/molecule
	rm -rf /tmp/ansible-role-robotframework.git

check test: init lint
	$(BASH) -c '. .venv/bin/activate && pytest -v $(T) tests'

doc docs:
	$(MAKE) -C docs html

sdist: init
	$(PYTHON) setup.py sdist

wheel: init
	$(PYTHON) setup.py bdist_wheel

rpm: init
	$(PYTHON) setup.py bdist_rpm

deb: init
	$(PYTHON) setup.py --command-packages=stdeb.command bdist_deb

upload: init sdist wheel
	$(TWINE) upload dist/*

clean:
	rm -rf .pytest_cache src/*/__pycache__ tests/__pycache__
	rm -rf tests/molecule/*/output
	rm -rf build dist
	rm -rf .eggs *.egg-info src/*.egg-info
	rm -rf docs/build

distclean: clean
	rm -rf .venv
	rm -rf .config
