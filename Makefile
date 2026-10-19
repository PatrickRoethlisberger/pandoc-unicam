PANDOC := pandoc --data-dir=$(CURDIR)/pandoc -d unicam
KIT := $(shell find pandoc -type f)

.PHONY: example clean
example: build/thesis.pdf

build/thesis.pdf: example/thesis.md example/bibliography.bib $(KIT)
	mkdir -p build
	cd example && $(PANDOC) thesis.md -o ../$@

clean:
	rm -rf build
