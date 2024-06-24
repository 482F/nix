{
  config,
  pkgs,
  env,
  myLib,
  user,
  ...
}: {
  home.packages = [
    (myLib.writeScriptBinWithArgs "java17" "${pkgs.jdk17_headless.outPath}/bin/java")
    (pkgs.maven.override {
      jdk = pkgs.jdk11_headless;
    })
  ];

  # 下記のような形式だと何故かプロキシを通ってくれないことがあるので ~/.m2/settings.xml で設定
  # MAVEN_OPTS="-Dhttp.proxyHost=xxx.xxx.xxx.xxx -Dhttp.proxyPort=xxxxx -Dhttps.proxyHost=xxx.xxx.xxx.xxx -Dhttps.proxyPort=xxxxx" mvn foobar
  home.file.".m2/settings.xml".text =
    if env.proxy == null
    then ""
    else ''
      <settings>
        <proxies>
         <proxy>
            <id>sb-http</id>
            <active>true</active>
            <protocol>http</protocol>
            <host>${env.proxy.host}</host>
            <port>${env.proxy.port}</port>
          </proxy>
         <proxy>
            <id>sb-https</id>
            <active>true</active>
            <protocol>https</protocol>
            <host>${env.proxy.host}</host>
            <port>${env.proxy.port}</port>
          </proxy>
        </proxies>
      </settings>
    '';

  xdg.dataFile._jdtls.source = let
    jdtls = builtins.fetchurl {
      url = let version = "1.36.0"; in "https://www.eclipse.org/downloads/download.php?file=/jdtls/milestones/${version}/jdt-language-server-${version}-202405301306.tar.gz";
      sha256 = "0yxf7nq7y6v5cya5vl662dbgda0lyjgghmpx9ynir9pl0r6jg3h2";
    };
    lombok = builtins.fetchurl {
      url = "https://projectlombok.org/downloads/lombok-1.18.32.jar";
      sha256 = "0pd636gpv1zwaxyl05p37m27sy7q1phaqdip65x5cpx2w9s4cmwp";
    };
    formatterXml =
      if env.jdtls.formatterXml == null
      then null
      else
        pkgs.writeTextFile {
          name = "formatter.xml";
          text = builtins.readFile env.jdtls.formatterXml;
        };
  in
    (pkgs.stdenv.mkDerivation
      rec {
        name = "jstls";

        unpackPhase =
          ''
            mkdir -p "$out"

            ln -s "${lombok}" "$out/lombok.jar"

            tar -xf "${jdtls}" -C "$out"
            ln -s $out/plugins/org.eclipse.equinox.launcher_*.jar "$out/plugins/org.eclipse.equinox.launcher.jar"

            ln -s ${pkgs.vscode-extensions.vscjava.vscode-java-debug.outPath}/share/vscode/extensions/vscjava.vscode-java-debug/server/com.microsoft.java.debug.plugin-*.jar \
              "$out/com.microsoft.java.debug.plugin.jar"
          ''
          + (
            if formatterXml == null
            then ""
            else ''
              ln -s ${formatterXml} "$out/format-settings.xml"
            ''
          );
      })
    .outPath;

  # jdtls 内の色んな .jar ファイルに書き込み権限が無いと nvim-jdtls がエラーを吐くので、_jdtls にダミーを作ってそれの実体を rsync でデプロイする
  home.activation.deploy-jdtls = config.lib.dag.entryAfter ["writeBoundary"] ''
    run mkdir -p '${config.xdg.dataHome}/jdtls'
    run nix shell nixpkgs#rsync --command rsync -r --del --copy-links $VERBOSE_ARG ~/.local/share/{_,}jdtls/
    run chmod -R 755 ~/.local/share/jdtls
  '';
}
