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
wsl.exe -d nixos -u root
```

# in nix
```bash
ln -s /mnt/d/wsl/nix-private /nix-private
function nixevalenv() {
  local script="${1}"
  shift 1
  nix eval --raw --experimental-features 'nix-command' --impure --expr "let env = (import /nix-private {myLib = null;}).env; in ${script}" "${@}"
}
U_NAME="$(nixevalenv 'env.username')"
U_HOME="/home/${U_NAME}"
usermod nixos -l "${U_NAME}" -d "${U_HOME}" -m
cd "${U_HOME}"
ln -s /mnt/d/wsl/nix "${U_HOME}/nix"
chown -h "${U_NAME}:users" /nix-private "${U_HOME}/nix"

nixevalenv 'builtins.concatStringsSep "\n" (builtins.attrValues env.pki.certificates)' --write-to /tmp/init.crt
if [ -n "$(cat /tmp/init.crt)" ]; then
    export NIX_SSL_CERT_FILE="/tmp/init.crt"
fi
export HTTPS_PROXY="$(nixevalenv 'if ((env.proxy or null) != null) then builtins.concatStringsSep "" [ "http://" env.proxy.host ":" env.proxy.port ] else ""')"
export NIXPKGS_ALLOW_UNFREE=1
export NIXPKGS_ALLOW_INSECURE=1

systemctl set-environment NIX_SSL_CERT_FILE="${NIX_SSL_CERT_FILE}" HTTPS_PROXY="${HTTPS_PROXY}"
systemctl restart nix-daemon

nix-channel --add  https://nixos.org/channels/nixos-24.05 nixos

nix-channel --update -v

nixos-rebuild switch -v

nix --experimental-features 'nix-command flakes' shell nixpkgs#git --command nixos-rebuild switch --flake "$(readlink "${U_HOME}/nix")#my-nixos" --impure
unset NIX_SSL_CERT_FILE
systemctl unset-environment NIX_SSL_CERT_FILE HTTPS_PROXY
systemctl restart nix-daemon

reboot nixos
```

