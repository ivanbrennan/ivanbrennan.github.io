with (import <nixpkgs> {});
let
  env = bundlerEnv {
    name = "ivanbrennan.github.io-bundler-env";
    inherit ruby;
    gemfile  = ./Gemfile;
    lockfile = ./Gemfile.lock;
    gemset   = ./gemset.nix;
    groups   =
      [ "default"
        "jekyll_plugins"
      ];
  };
in stdenv.mkDerivation {
  name = "ivanbrennan.github.io";
  buildInputs = [ env ];

  shellHook = ''
    export PS1="\n╭\[\033[1m\]\w\[\033[0m\]$(_git_ps1_)\[\033[0m\] \[\033[0;30m\]\t\[\033[0m\]\n╰(\u:\[\033[1;32m\]nix\[\033[0m\])• "
  '';
}
