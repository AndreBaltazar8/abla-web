ABLAC_DIR := $(abspath ../ablac)
COMPILER := $(ABLAC_DIR)/build/ablac

.PHONY: check example clean

check:
	mkdir -p build
	$(COMPILER) build tests/framework.ab -o build/framework --fast --no-cache
	build/framework; test $$? -eq 42
	$(COMPILER) build tests/build_source.ab -o build/build-source --fast --no-cache
	build/build-source; test $$? -eq 42
	$(COMPILER) build tests/integrations.ab -o build/integrations --fast --no-cache
	build/integrations; test $$? -eq 42

example:
	mkdir -p build
	$(COMPILER) build examples/basic/main.ab -o build/basic --fast --no-cache

clean:
	@if [ -d build ]; then gio trash build; fi
