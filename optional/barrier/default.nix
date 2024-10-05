{
  home = {
    config,
    pkgs,
    env,
    lib,
    myLib,
    user,
    ...
  }: let
    innounp = pkgs.stdenv.mkDerivation rec {
      pname = "innounp";
      version = "0.50";
      src = pkgs.fetchurl {
        url = "https://github.com/WhatTheBlock/innounp/releases/download/v${version}/innounp.exe";
        hash = "sha256-m3Ktn5PRZ2UqDivzkhq9/T5nR8XnGEYaLli536zTH0w=";
      };
      buildCommand = ''
        mkdir -p $out/bin
        dest=$out/bin/${pname}
        cp -ai $src $dest
        chmod 755 $dest
      '';
    };
    barrierBinNames = ["barrier.exe" "barrierc.exe" "barriers.exe"];
    pname = "barrier";
    version = "2.4.0";
    storePath = "${env.winNixStore}/${pname}-${version}";
    win-barrier = pkgs.stdenv.mkDerivation {
      inherit pname version;
      src = pkgs.fetchurl {
        url = "https://github.com/debauchee/barrier/releases/download/v${version}/BarrierSetup-${version}-release.exe";
        hash = "sha256-fma3tNEzEuYH7dBvjqOPPJsJs+iuorVSUMALJfmJKIU=";
      };
      buildCommand =
        ''
          mkdir -p $out/dep
          cp -ai $src $out/dep/setup.exe

          mkdir -p $out/bin
        ''
        + lib.concatMapStrings (binName: ''
          ln -s ${storePath}/bin/${binName} $out/bin/${binName}
        '')
        barrierBinNames;
    };
  in {
    my.pkgs = {inherit win-barrier;};
    home.activation.win-barrier = config.lib.dag.entryAfter ["writeBoundary"] ''
      function main() {
        if [[ -d ${storePath} ]]; then
          return 0
        fi
        mkdir -p ${storePath}
        cd ${storePath}

        cp ${innounp}/bin/innounp ./
        cp ${win-barrier}/dep/setup.exe ./setup.exe
        ./innounp -x -d. setup.exe 2>&1

        rm setup.exe innounp

        mkdir -p dep
        mv \{app\}/* dep/

        rm -rf \{app\} \{tmp\}

        chmod 755 dep/*.exe

        mkdir -p bin
        ${lib.concatMapStrings (binName: ''
          ln -s ../dep/${binName} bin/${binName}
        '')
        barrierBinNames}
      }
      main
      unset -f main
    '';
  };
}
