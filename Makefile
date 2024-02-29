build:
	PACKER_LOG=1 PACKER_LOG_PATH=build.log packer build  -var-file variables.json ubuntu18.04_baseos.json
clean:
	rm -rf output*
	rm -rf cloud-init/ubuntu22.04_baseos/nocloud.iso

build_22:
	PACKER_LOG=1 PACKER_LOG_PATH=build-22.log packer build  -var-file variables-22.04.json ubuntu22.04_baseos.json

generate_iso:
	genisoimage -output cloud-init/ubuntu22.04_baseos/nocloud.iso -volid cidata -joliet -rock cloud-init/ubuntu22.04_baseos/user-data cloud-init/ubuntu22.04_baseos/meta-data

all: build generate_iso build_22 clean
