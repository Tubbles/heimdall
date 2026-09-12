.PHONY: all
all:
	mkdir -p build
	odin build plugin.odin -file -target:freestanding_wasm32 -no-entry-point -collection:module=../module -collection:engine=engine -out:build/plugin.wasm
	odin build plugin2.odin -file -target:freestanding_wasm32 -no-entry-point -collection:module=../module -collection:engine=engine -out:build/plugin2.wasm

.PHONY: clean
clean:
	rm -fr build
