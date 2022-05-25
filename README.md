# Windows image builder

This repo is heavely influensed by: https://github.com/ruzickap/packer-templates

## To add a new windows image/version:

1. Create a json file for the release (copy an existing from the root of this repo)

```bash
cp windows-2022 windows-<version>
```

2. Update `windows_version`, `iso_url` and `iso_checksum`

```bash
vim windows-<version>
```

3. Create an `Autounattend.xml` file under the folder `http/windows-<version>/Autounattend.xml` with update vars for this specific release

```bash
vim windows-<version>
```

4. Create an ansible playbook/taskfile under `ansible/`, you can most likely just copy another playbook

```bash
cp ansible/windows-2022.yml cp ansible/windows-<version>.yml
```

5. Add build to `Makefile`, simply copy the value from an existing build

```bash
vim Makefile
```
