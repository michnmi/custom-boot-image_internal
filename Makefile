build:
	PACKER_LOG=1 PACKER_LOG_PATH=build.log packer build  -var-file variables.json ubuntu18.04_baseos.json
clean:
	rm -rf output*

build_22:
	PACKER_LOG=1 PACKER_LOG_PATH=build-22.log packer build  -var-file variables-22.04.json ubuntu22.04_baseos.json


all: build build_22 clean
