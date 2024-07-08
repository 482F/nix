{
  config,
  pkgs,
  env,
  ...
}: {
  home.packages = [
    # LSP などは poetry 経由で入れる
    # poetry add --dev python-lsp-server --extras "pylint" --extras "autopep8"

    pkgs.poetry
    pkgs.python312
  ];
  home.sessionVariables = {
    CURL_CA_BUNDLE = "/etc/ssl/certs/ca-certificates.crt";
  };
}
