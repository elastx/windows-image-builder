# Windows image builder

This repo is heavely influensed by: https://github.com/ruzickap/packer-templates

## To add a new windows image/version:

1. Create a json file for the release (copy an existing from the root of this repo)

```bash
cp -a http/windows-2022 http/windows-<version>
```

2. Make sure `Autounattend.xml` under `http/windows-<version>` is correct

```bash
vim http/windows-<version>/Autounattend.xml
```
