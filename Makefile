default: clean install_deps prepare

prepare:
	packer init build-cloudimg.pkr.hcl
	curl -L -o /tmp/virtio-win.iso https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/latest-virtio/virtio-win.iso
	xorriso -report_about WARNING -osirrox on -indev /tmp/virtio-win.iso -extract / ./packer_cache/virtio-win
	find ./packer_cache/virtio-win -type d -exec chmod u+rwx {} \;

install_deps:
	curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add - && \
	apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com focal main" && \
	apt-get update && sudo apt-get install packer && \
	apt-get install qemu-system-x86 xorriso

clean:
	rm -rf images

clean-cache:
	rm -rf /root/.cache/packer/

build-windows-2022:
	PACKER_LOG=1 packer build windows-2022.json

build-windows-2019:
	PACKER_LOG=1 packer build windows-2019.json

all: clean clean-cache install_deps prepare build
