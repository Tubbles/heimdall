.PHONY: all
all:
	mkdir -p build
	odin build src -collection:module=module -out:build/odin_game

.PHONY: plugin
plugin:
	cd plugin && $(MAKE)

.PHONY: run
run: plugin
	odin run src -collection:module=module

.PHONY: clean
clean: clean-plugin
	rm -fr build

.PHONY: clean-plugin
clean-plugin:
	rm -fr plugin/build
