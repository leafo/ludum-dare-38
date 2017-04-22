
.PHONY: watch build lint

build:
	moonc .

watch:
	moonc -w .

lint:
	moonc -l *.moon
