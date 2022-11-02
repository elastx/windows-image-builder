default: clean install_deps build

prepare:
	packer init build-cloudimg.pkr.hcl

install_deps:
	curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add - && \
	apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com focal main" && \
	apt-get update && sudo apt-get install packer && \
	apt-get install qemu-system-x86

clean:
	rm -rf images

clean-cache:
	rm -rf /root/.cache/packer/

build-windows-2022:
	PACKER_LOG=1 packer build windows-2022.json

build-windows-2019:
	PACKER_LOG=1 packer build windows-2019.json

all: clean clean-cache install_deps prepare build
