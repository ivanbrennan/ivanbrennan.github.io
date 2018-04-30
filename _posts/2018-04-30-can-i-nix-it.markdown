---
layout: post
title: "Can I Nix It?"
date: 2018-04-30T23:05:18-04:00
---

I've been using NixOS lately, and wanted to get octopress & jekyll set up so I could start writing about NixOS from within NixOS.
I'm still finding my way around the nix ecosystem, and I took a couple wrong turns along the way, but once I found my bearings it was pretty simple.

Since I'm using [octopress](https://github.com/octopress/octopress) and [jekyll](https://jekyllrb.com/), my blog is a Ruby project and dependencies are listed in Gemfile and Gemfile.lock.
Neither Ruby nor octopress are installed globally on my NixOS system, so I can't just `cd` into the project and start running octopress commands.
```
$ octopress new draft "Can I Nix It?"
octopress: command not found

$ type -t ruby || type -t gem || type -t bundler || echo Nothing
Nothing
```

Instead, I'm using `nix-shell` to spawn a development environment that's tailored to meet the needs of this particular project.
[bundix](https://github.com/manveru/bundix/) takes most of the legwork out of setting this up, so I ran a couple bundix commands in an ad hoc `nix-shell`.
```sh
nix-shell --packages bundix --run 'bundix --magic && bundix --init'
```

This generated a gemset.nix file, which describs the gem dependencies in a nix expression, as well as a shell.nix file, which configures the environment produced by running `nix-shell` in the project root directory.

I had to make one change to the generated shell.nix, specifying the gem [groups](http://bundler.io/v1.6/groups.html) I wanted included.
In particular, `octopress` is grouped under `jekyll_plugins` in my Gemfile,so I had to ensure that group was included in the environment.
```ruby
group :jekyll_plugins do
  gem 'octopress', '~> 3.0.11'
end
```

The full shell.nix looks like:
```nix
with (import <nixpkgs> {});
let
  env = bundlerEnv {
    name = "ivanbrennan.github.io-bundler-env";
    inherit ruby;
    gemfile  = ./Gemfile;
    lockfile = ./Gemfile.lock;
    gemset   = ./gemset.nix;
    groups   = [ "default" "jekyll_plugins" ];
  };
in stdenv.mkDerivation {
  name = "ivanbrennan.github.io";
  buildInputs = [ env ];
}
```

Now I can `cd` into the project, run `nix-shell`, and all the octopress & jekyll commands are available.
