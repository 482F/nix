{
  home = {
    config,
    pkgs,
    lib,
    env,
    myLib,
    user,
    ...
  }: let
    jdtls-dir = "${config.xdg.dataHome}/jdtls";
    java-cacerts-path = "${jdtls-dir}/java-cacerts";
  in {
    # 独自 SSL 証明書を含む java-cacerts を作成
    home.activation.java-cacerts = config.lib.dag.entryAfter ["writeBoundary"] ''
      run mkdir -p '${jdtls-dir}'
      run ${pkgs.p11-kit.bin}/bin/trust extract --format=java-cacerts --purpose=server-auth ${java-cacerts-path}
    '';

    # mkJavaDerivation 内で export しても、nvim-jdtls 経由で起動したデバッグセッションに環境変数が反映されないのでグローバル定義
    home.sessionVariables = {
      JAVAX_NET_SSL_TRUSTSTORE = java-cacerts-path;
    };
    home.packages = let
      mkJavaDerivation = javapkg: destName:
        myLib.writeScriptBin destName ''
          ${javapkg.outPath}/bin/java \
            -Dhttps.proxyHost=${env.proxy.host or ""} \
            -Dhttp.proxyHost=${env.proxy.host or ""} \
            -Dhttps.proxyPort=${env.proxy.port or ""} \
            -Dhttp.proxyPort=${env.proxy.port or ""} \
            -Djavax.net.ssl.trustStore=${java-cacerts-path} \
            "$@"
        '';
      mvnJava = mkJavaDerivation pkgs.jdk11_headless "java";
      java11 = mkJavaDerivation pkgs.jdk11_headless "java11";
      java17 = mkJavaDerivation pkgs.jdk17_headless "java17";
      rawMvn = pkgs.maven.override {
        jdk_headless = pkgs.jdk11_headless;
      };
    in [
      java11
      java17
      (myLib.writeScriptBin "mvn" ''
        JAVA_HOME=${mvnJava} ${rawMvn}/bin/mvn "$@"
      '')
      (pkgs.checkstyle.override {jre = pkgs.jdk17_headless;})
    ];

    xdg.dataFile."checkstyle.xml".source = let
      xml = env.checkstyle.configXml or null;
    in
      lib.mkIf (xml != null) xml;

    # 下記のような形式だと何故かプロキシを通ってくれないことがあるので ~/.m2/settings.xml で設定
    # MAVEN_OPTS="-Dhttp.proxyHost=xxx.xxx.xxx.xxx -Dhttp.proxyPort=xxxxx -Dhttps.proxyHost=xxx.xxx.xxx.xxx -Dhttps.proxyPort=xxxxx" mvn foobar
    home.file.".m2/settings.xml" = rec {
      enable = (env.proxy or null) != null;
      text =
        if enable
        then # xml
          ''
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
          ''
        else null;
    };

    xdg.dataFile.jdks.source = let
      jdks = {
        "JavaSE-11" = pkgs.jdk11_headless;
      };
    in
      (pkgs.stdenv.mkDerivation rec {
        name = "jdks";
        unpackPhase =
          ''
            mkdir -p "$out"
          ''
          + (
            lib.concatLines
            (lib.mapAttrsToList (name: jdk: "ln -s ${jdk}/lib/openjdk $out/${name}") jdks)
          );
      })
      .outPath;

    # jdtls 内の色んな .jar ファイルに書き込み権限が無いと nvim-jdtls がエラーを吐くので実体を rsync でデプロイする
    home.activation.deploy-jdtls = let
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
      my-jdtls =
        pkgs.stdenv.mkDerivation
        rec {
          name = "jdtls";

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
        };
    in
      config.lib.dag.entryAfter ["writeBoundary"] ''
        run mkdir -p '${jdtls-dir}'
        ${pkgs.rsync}/bin/rsync --recursive --del --checksum --copy-links $VERBOSE_ARG ${my-jdtls}/ ${config.xdg.dataHome}/jdtls/
        run chmod -R 755 '${jdtls-dir}'
      '';

    my.gc.jdtls.script = ''rm -rf $XDG_DATA_HOME/nvim-jdtls/*'';
    my.gc.maven.script = ''rm -rf ~/.m2/repository/*'';
  };
}
