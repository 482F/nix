# for wsl in powershell

```powershell
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

reboot

# download https://aka.ms/wsl2kernel and install

wsl --update --web-download; wsl --update --pre-release --web-download

cd D:\wsl
# wsl.exe --unregister nixos
wsl.exe --import nixos nixos nixos-wsl.tar.gz --version 2
wsl.exe -d nixos
```

# in nix
```bash
cd ~
ln -s /mnt/d/wsl/nix-private ~/nix-private
ln -s /mnt/d/wsl/nix ~/nix

nix eval --raw --experimental-features 'nix-command' --impure --expr 'let env = (import ./nix-private {myLib = null;}).env; in builtins.concatStringsSep "\n" (builtins.attrValues env.pki.certificates)' --write-to /tmp/init.crt
if [ -n "$(cat /tmp/init.crt)" ]; then
    export NIX_SSL_CERT_FILE="/tmp/init.crt"
fi
export HTTPS_PROXY="$(nix eval --raw --experimental-features 'nix-command' --impure --expr 'let env = (import ./nix-private {myLib = null;}).env; in if (env.proxy != null) then builtins.concatStringsSep "" [ "http://" env.proxy.host ":" env.proxy.port ] else ""')"

cat << EOF > ~/esudo
#!/usr/bin/env bash
sudo NIX_SSL_CERT_FILE="\${NIX_SSL_CERT_FILE}" HTTPS_PROXY="\${HTTPS_PROXY}" "\${@}"
EOF
chmod 744 ~/esudo

~/esudo systemctl set-environment NIX_SSL_CERT_FILE="${NIX_SSL_CERT_FILE}" HTTPS_PROXY="${HTTPS_PROXY}"
~/esudo systemctl restart nix-daemon

~/esudo nix-channel --add  https://nixos.org/channels/nixos-24.05 nixos

~/esudo nix-channel --update -v

~/esudo nixos-rebuild switch -v

nix --experimental-features 'nix-command flakes' shell nixpkgs#git --command ~/esudo nixos-rebuild switch --flake "$(readlink ~/nix)#my-nixos" --impure
unset NIX_SSL_CERT_FILE
~/esudo systemctl unset-environment NIX_SSL_CERT_FILE HTTPS_PROXY
~/esudo systemctl restart nix-daemon
```

