.PHONY: build
build:
	PACKER_LOG=1 packer build  -var-file variables.json ubuntu18.04_baseos.json > build.log

.PHONY: clean
clean:
	rm -rf output*

all: build clean
