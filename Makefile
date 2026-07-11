VERSIONS ?= 22.04 24.04 26.04

build:
	@for v in $(VERSIONS); do \
	  PACKER_LOG=1 PACKER_LOG_PATH=build-$$v.log packer build -var-file variables-$$v.json ubuntu$${v}_baseos.json || exit 1; \
	  sleep 15; \
	done

clean:
	rm -rf output*
	@for v in $(VERSIONS); do \
	  rm -rf cloud-init/ubuntu$${v}_baseos/nocloud.iso; \
	done

generate_iso:
	@for v in $(VERSIONS); do \
	  genisoimage -output cloud-init/ubuntu$${v}_baseos/nocloud.iso -volid cidata -joliet -rock cloud-init/ubuntu$${v}_baseos/user-data cloud-init/ubuntu$${v}_baseos/meta-data || exit 1; \
	done

all: build generate_iso clean
