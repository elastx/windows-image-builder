variable "iso_url" {
  type    = string
  default = "https://software-download.microsoft.com/download/pr/17763.737.190906-2324.rs5_release_svc_refresh_SERVER_EVAL_x64FRE_en-us_1.iso"
}

variable "iso_checksum" {
  type    = string
  default = "549bca46c055157291be6c22a3aaaed8330e78ef4382c99ee82c896426a1cee1"
}

variable "win_version" {
  type    = string
  default = "2019"
}

variable "ssh_password" {
  type    = string
  default = "s3cr3tbu1ldp4ssw0rd"
}

source "qemu" "windows" {
  accelerator       = "kvm"
  boot_wait         = "1s"
  communicator      = "ssh"
  cpus              = "4"
  disk_compression  = "true"
  disk_interface    = "virtio"
  disk_size         = "51200M"
  floppy_files      = [
    "http/windows-${var.win_version}/Autounattend.xml",
    "scripts/win-common/setup-openssh.ps1",
    "scripts/win-common/unattend.xml",
    "scripts/win-common/sysprep.bat"
  ]
  headless          = "true"
  iso_url           = "${var.iso_url}"
  iso_checksum      = "${var.iso_checksum}"
  cd_files          = [
    "./packer_cache/virtio-win"
  ]
  memory            = "8192"
  net_device        = "virtio-net"
  output_directory  = "images"
  shutdown_command  = "A:\\sysprep.bat"
  shutdown_timeout  = "15m"
  skip_compaction   = "false"
  vm_name           = "windows-${var.win_version}"
  ssh_username      = "Administrator"
  ssh_password      = "${var.ssh_password}"
  ssh_timeout      = "1h"
  qemuargs          = [
    [ "--cpu", "EPYC-Milan-v1" ]
  ]
}

build {
  sources = ["source.qemu.windows"]
  provisioner "shell-local" {
    inline = [
      "ansible-playbook --connection=ssh --extra-vars='ansible_password=${var.ssh_password}  ansible_shell_type=powershell' -i 127.0.0.1:${build.Port}, ansible/windows.yml -vv"
    ]
    environment_vars = [
      "ANSIBLE_CONFIG=ansible/ansible.cfg",
      "ANSIBLE_REMOTE_USER=Administrator"
    ]
  }
}

