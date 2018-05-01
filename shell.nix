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
}
