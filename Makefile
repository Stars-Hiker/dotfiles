# dotfiles — convenience entrypoints. Run `make` or `make help`.
# Thin wrappers around bin/*.sh and install.sh (no logic lives here); the
# dotsync / dots / pkgsnap shell aliases keep working unchanged.

.DEFAULT_GOAL := help
.PHONY: help install sync snap seal unseal doctor

help:
	@echo 'dotfiles make targets:'
	@echo '  make install   stow all config packages (idempotent)'
	@echo '  make sync      snapshot pkglists, commit & push   (= dotsync)'
	@echo '  make snap      regenerate pkglists only (no commit)'
	@echo '  make seal      encrypt secrets -> secrets/secrets.tar.age'
	@echo '  make unseal    decrypt secrets back into your home (needs age key)'
	@echo '  make doctor    health-check this machine (no sudo)'

install:
	@./install.sh

sync:
	@bin/sync.sh

snap:
	@bin/pkg-snapshot.sh

seal:
	@bin/secrets-seal.sh

unseal:
	@bin/secrets-unseal.sh

doctor:
	@bin/doctor.sh
