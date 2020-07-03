.PHONY: build
build:
	PACKER_LOG=1 PACKER_LOG_PATH=build.log packer build  -var-file variables.json ubuntu18.04_baseos.json

.PHONY: clean
clean:
	rm -rf output*

all: build clean
