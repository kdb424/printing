SSH_PORT = 22
SSH_USER = $(USER)
BASE_DIR = $(CURDIR)
OUTPUT_DIR = $(BASE_DIR)/public

.PHONY: default
default: build

.PHONY: all
all: build upload

.PHONY: test
test:
	zola check

.PHONY: check
check:
	zola check

.PHONY: build
build:
	zola build

.PHONY: clean
clean:
	[ ! -d "$(OUTPUT_DIR)" ] || rm -rf "$(OUTPUT_DIR)"

.PHONY: serve
serve:
	zola serve

.PHONY: update
	git submodule update --remote

.PHONY: upload
upload: clean build
	rsync -e "ssh -p $(SSH_PORT)" -P -rvz --delete $(OUTPUT_DIR)/* $(SSH_USER)@$(SSH_HOST):$(SSH_TARGET_DIR)
