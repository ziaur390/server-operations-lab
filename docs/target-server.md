# Target server: Ubuntu (WSL2)

The lab target server runs Ubuntu 24.04 LTS in a WSL2 environment
(native Linux userland with systemd, isolated from the Windows host).
This replaced the original VirtualBox plan after Hyper-V conflicts made
desktop virtualization impractical on this machine.

Why this still demonstrates the target skills:

- Real Ubuntu server environment with systemd service management
- Reached over SSH (port 2222), like any remote server
- Ansible configures it exactly as it would a cloud VM (same playbook works unchanged for an Azure VM — only the inventory changes)

## Setup performed

```bash
# inside Ubuntu (as root)
apt-get update && apt-get install -y openssh-server
# port 2222 (avoids clashing with other SSH on the host)
sed -i 's/^#\?Port .*/Port 2222/' /etc/ssh/sshd_config
systemctl enable --now ssh

# public key auth: Windows public key appended to ~/.ssh/authorized_keys
```

## Host-side SSH alias (`~/.ssh/config`)

```text
Host lab-vm
  HostName localhost
  Port 2222
  User ziaur26261
```

## Verification

```console
$ ssh lab-vm 'echo SSH-OK from $(hostname); uname -srm; cat /etc/os-release | head -2'
SSH-OK from zia
Linux 6.18.33.2-microsoft-standard-WSL2 x86_64
PRETTY_NAME="Ubuntu 24.04.3 LTS"
NAME="Ubuntu"

$ ssh lab-vm 'df -h / | tail -1; free -h | head -2 | tail -1; uptime -p'
/dev/sdf       1007G  1.9G  954G   1% /
Mem:           9.6Gi       1.3Gi       366Mi       50Mi       8.1Gi       8.3Gi
up 22 hours, 39 minutes
```

## Skills practiced

- Linux service management (`systemctl`)
- SSH key-based authentication, `sshd_config` changes
- Host resource inspection (`df`, `free`, `uptime`)
- Git history honesty: approach changed from VirtualBox to WSL2 — documented, not hidden
