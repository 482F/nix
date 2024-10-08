{
  home = {
    config,
    pkgs,
    env,
    user,
    ...
  }: {
    programs.bash = {
      enable = true;
      initExtra = ''
        function _tmux(){
            if [ "''${1:-}" = "" ]; then
                tmux attach -t main || tmux new -s main
            else
                tmux "$@"
            fi
        }

        alias tmux=_tmux

        if [ -z "$TMUX" ]; then
          if [ "$(pwd)" = "${config.home.homeDirectory}" ]; then
            _tmux; exit
          fi
        fi
      '';
    };

    programs.tmux = {
      enable = true;
      secureSocket = false;
      clock24 = true;
      keyMode = "vi";
      extraConfig = ''
        # tmux の色を true color に
        set-option -s default-terminal "xterm-256color"
        set-option -sa terminal-overrides ",xterm*:Tc"

        # xterm-256color だと Home と End キーが効かなくなるようなので変換する
        bind-key -n Home send Escape "OH"
        bind-key -n End send Escape "OF"

        # ステータスバーをトップに配置する
        set-option -g status-position top

        # 左右のステータスバーの長さを決定する
        set-option -g status-left-length 90
        set-option -g status-right-length 90

        # #P => ペイン番号
        # 最左に表示
        set-option -g status-left '#H:[#P]'

        # Wi-Fi、バッテリー残量、現在時刻
        # 最右に表示
        set-option -g status-right '#(wifi) #(battery --tmux) [%Y-%m-%d(%a) %H:%M]'

        # ステータスバーを1秒毎に描画し直す
        set-option -g status-interval 1

        # キーリピートの受付時間を 0.2 秒にする
        set-option -g repeat-time 200

        #ウィンドウ番号などを中央に
        set-option -g status-justify centre

        # ステータスバーの色を設定する
        set-option -g status-bg "colour238"

        # status line の文字色を指定する。
        set-option -g status-fg "colour255"

        # 番号基準値を変更
        set-option -g base-index 1

        # エスケープキーの入力遅延をなくす
        set-option -g escape-time 0

        # 設定の再読み込み
        bind r source-file ~/.tmux.conf

        # ウィンドウ自体の移動
        bind -r < swap-window -t -1 \; previous-window
        bind -r > swap-window -t +1 \; next-window

        # ウィンドウ間の移動
        bind -r p previous-window
        bind -r n next-window

        # ペイン間の移動
        bind -r o select-pane -t :.+

        # ペイン同期のオンオフ
        bind -r s setw synchronize-panes \; display "synchronize-panes #{?pane_synchronized,on,off}"

        # コピーモード vi に
        set-window-option -g mode-keys vi

        # ウィンドウ名を勝手に変えないように
        set-option -g allow-rename off

        # マウスの操作を有効化
        set-option -g mouse on

        # 選択時の色変更
        set-window-option -g mode-style "fg=black,bg=#A3D7FF"

        # ウィンドウ作成時に、現在のペインのカレントディレクトリを継承するように
        bind '"' split-window -c "#{pane_current_path}"
        bind % split-window -h -c "#{pane_current_path}"
        bind c new-window -c "#{pane_current_path}"

        # クリップボード機能の有効化 (OSC 52 用)
        set-option -g set-clipboard on
      '';
    };
  };
}
