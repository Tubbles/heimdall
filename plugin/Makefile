.PHONY: all
all:
	mkdir -p build
	odin build plugin.odin -file -target:freestanding_wasm32 -no-entry-point -collection:module=../module -collection:heimdall=heimdall -out:build/plugin.wasm
	odin build plugin2.odin -file -target:freestanding_wasm32 -no-entry-point -collection:module=../module -collection:heimdall=heimdall -out:build/plugin2.wasm

.PHONY: test
test:
	odin test plugin.odin -file -collection:module=../module -collection:heimdall=heimdall
	odin test plugin2.odin -file -collection:module=../module -collection:heimdall=heimdall

.PHONY: clean
clean:
	rm -fr build
