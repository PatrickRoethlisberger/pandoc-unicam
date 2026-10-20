PANDOC := pandoc --data-dir=$(CURDIR)/pandoc -d unicam
KIT := $(shell find pandoc -type f)

.PHONY: examples clean
examples: build/minimal.pdf build/full.pdf

build/minimal.pdf: $(wildcard examples/minimal/*) $(KIT)
	mkdir -p build
	cd examples/minimal && $(PANDOC) thesis.md -o ../../$@

build/full.pdf: $(shell find examples/full -type f) $(KIT)
	mkdir -p build
	cd examples/full && $(PANDOC) 00-meta.md chapters/*.md -o ../../$@

clean:
	rm -rf build
