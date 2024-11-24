
.PHONY: watch build lint deploy bundle

run: build
	love .

build:
	moonc .

watch:
	moonc -w .

lint:
	moonc -l *.moon

bundle: build
	lovekit-bin.sh depthgun build/

# deploy: 
# 	lovekit-bin.sh depthgun
# 	butler push depthgun-win32.zip leafo/depth-gun:win32
# 	butler push depthgun-osx.zip leafo/depth-gun:osx

tags:
	moon-tags $$(find -L . -type f -name "*.moon") > $@
