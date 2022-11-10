ifdef ISO_URL
ISO_URL := $(ISO_URL)
else
ISO_URL := https://software-download.microsoft.com/download/pr/17763.737.190906-2324.rs5_release_svc_refresh_SERVER_EVAL_x64FRE_en-us_1.iso
endif

ifdef ISO_CHECKSUM
ISO_CHECKSUM := $(ISO_CHECKSUM)
else
ISO_CHECKSUM := 549bca46c055157291be6c22a3aaaed8330e78ef4382c99ee82c896426a1cee1
endif

ifdef WIN_VERSION
WIN_VERSION := $(WIN_VERSION)
else
WIN_VERSION := 2019
endif

default: clean install_deps prepare

prepare:
	packer init build-cloudimg.pkr.hcl
	curl -L -o /tmp/virtio-win.iso https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/latest-virtio/virtio-win.iso
	xorriso -report_about WARNING -osirrox on -indev /tmp/virtio-win.iso -extract / ./packer_cache/virtio-win
	find ./packer_cache/virtio-win -type d -exec chmod u+rwx {} \;

install_deps:
	curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add - && \
	apt-add-repository -y "deb [arch=amd64] https://apt.releases.hashicorp.com focal main" && \
	apt-get update && sudo apt-get install packer && \
	apt-get install -y qemu-system-x86 xorriso python3-pip && \
	pip3 install ansible

clean:
	rm -rf images

clean-cache:
	rm -rf /root/.cache/packer/

build:
	PACKER_LOG=1 packer build -var iso_url="$(ISO_URL)" -var iso_checksum="$(ISO_CHECKSUM)" -var win_version="$(WIN_VERSION)" windows.pkr.hcl

all: clean clean-cache install_deps prepare build
