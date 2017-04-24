
.PHONY: watch build lint deploy

build:
	moonc .

watch:
	moonc -w .

lint:
	moonc -l *.moon

deploy: 
	lovekit-bin.sh depthgun
	butler push depthgun-win32.zip leafo/depth-gun:win32
	butler push depthgun-osx.zip leafo/depth-gun:osx
