---
layout: post
title: "Vim on NixOS"
date: 2018-05-09T08:51:23-04:00
---

Configuring Vim on NixOS took me into the depths of Vim's initialization process and was a good primer on composing Nix expressions.

The [`vim_configurable`](https://github.com/NixOS/nixpkgs/blob/a9cbf62c60ad68a54af0a4c10277af6d5655910b/pkgs/applications/editors/vim/configurable.nix) derivation lets you bake plugins and configuration options into Vim system-wide, rather than on a per-user basis.
There's still room for per-user configuration, but this provides a nice baseline, and means you won't be faced with an unconfigured Vim when you need to run as root.

### sudoedit

If you're familiar with `sudoedit`, you might ask why I'd bother with a system-wide Vim configuration when I could instead run `sudoedit` from my normal user account, launching the editor with elevated privileges and still loading my user's configuration.

While this works well when editing a single file, it's less helpful when you want to edit several related files.
Because `sudoedit` uses tempfiles to run its magic, the editing buffer lives in `/var/tmp`.
Attempting to open another file relative to the one you're editing won't behave as expected.
Also, any root-owned files you open from within Vim will be opened read-only, rather than as editable tempfiles.

So `sudoedit` is nice when you know upfront exactly which files you'll be touching, but if there's any exploration involved, it falls short.
For these reasons, I switch to the root user and run Vim directly when I need to edit a family of root-owned files, such as the components of my nixos configuration.

### vim\_configurable

In the following [default.nix](https://github.com/ivanbrennan/nixbox/blob/24bfa278be03df421af228401d9710105d3903d8/overlays/vim/default.nix) overlay, I use `vim_configurable` to set up my plugins and vimrc:
```nix
self: super:

let
  configured = {
    packages.core = (import ./core-package.nix) self;
    customRC = builtins.readFile "${self.dotvim}/vimrc";
  };

in

{
  dotvim = super.callPackage ./dotvim.nix { };

  vimPrivatePlugins = (import ./plugins.nix) super;

  vim-configured = self.vim_configurable.customize {
    name = "vim";
    vimrcConfig = configured;
  };
}
```

[core-packages.nix](https://github.com/ivanbrennan/nixbox/blob/24bfa278be03df421af228401d9710105d3903d8/overlays/vim/core-package.nix) lists the plugins to include in a Vim native package.
It can select plugins from `pkgs.vimPlugins` (plugins already defined in nixpkgs) and `pkgs.vimPrivatePlugins` (additional plugins I define in plugins.nix).
```nix
pkgs:

with (pkgs.vimPlugins) // (pkgs.vimPrivatePlugins); {
  start =
    [ abolish
      articulate
      # ...
    ];

  opt =
    [ haskell-vim
      splitjoin
      # ...
    ];
}
```

In [plugins.nix](https://github.com/ivanbrennan/nixbox/blob/24bfa278be03df421af228401d9710105d3903d8/overlays/vim/plugins.nix), I describe a set of Vim plugins not already present in `pkgs.vimPlugins`.
```nix
pkgs:

{
  abolish = pkgs.vimUtils.buildVimPlugin {
    name = "abolish";
    src = pkgs.fetchFromGitHub {
      owner = "tpope";
      repo = "vim-abolish";
      rev = "b6a8b49e2173ba5a1b34d00e68e0ed8addac3ebd";
      sha256 = "0i9q3l7r5p8mk4in3c1j4x0jbln7ir9lg1cqjxci0chjjzfzc53m";
    };
  };

  # ...
}
```

[dotvim.nix](https://github.com/ivanbrennan/nixbox/blob/24bfa278be03df421af228401d9710105d3903d8/overlays/vim/dotvim.nix) is a derivation that pulls my vimrc from a git repo.
This lets me read the contents of my vimrc into the `rcConfig` attribute that `vim_configurable` uses.
```nix
{ stdenv
, fetchFromGitHub
}:

stdenv.mkDerivation {
  name = "dotvim";

  src = fetchFromGitHub {
    owner = "ivanbrennan";
    repo = "dotvim";
    rev = "97bed1f2e534ea583c51b4317d8d9ea53c4728cf";
    sha256 = "0bxhqvzswg37dswnqqgrwq4fwc1jb3lks85fb26i77has57lzv2y";
  };

  phases = [
    "unpackPhase"
    "installPhase"
  ];

  installPhase = ''
    mkdir -p $out
    cp $src/vimrc $out/vimrc
  '';

  meta = {
    description = "A minimal vimrc.";
  };
}
```

### Nix store

To see how this all ties together, let's list everything in the nix store related to Vim.
```sh
nix-store --query --requisites \
  /run/current-system/sw \
  | grep -P '^[^-]+-.*?\K\bvim'
```

The first several results are paths to plugins, for example:
```
/nix/store/0lgaf7k8sjciky1hd1n70h82mi62cznd-vimplugin-fzf-0.17.3
```

The remainder includes `vim-pack-dir` (the result of core-packages.nix), a couple vimrc's (more on these in a moment), `vim_configurable`, and `vim` (a wrapper script):
```
/nix/store/79a8mada9j90b6sr74v16c1afhl65hcw-vim-pack-dir
/nix/store/d52j23wnwz3swwbgv68mnl1i463a1hpn-vimrc
/nix/store/63av9cp8hkwsr332nv5whpnq2k3z0iqg-nixos-vimrc
/nix/store/sz52xjgb6viyfbp7w0221hj2jr5avkgf-vim_configurable-8.0.1605
/nix/store/pf28xvba6q4j50iiihlzym58l4x4w0rg-vim
```

So where's the real Vim?
```sh
which vim
/run/current-system/sw/bin/vim

readlink -f $(which vim)
/nix/store/pf28xvba6q4j50iiihlzym58l4x4w0rg-vim/bin/vim
```

So when I run `vim` at the command line, that's what my PATH is pointing to.
This is not the actual executable, but a wrapper script:
```sh
cat $( readlink -f $(which vim) )
#!/bin/sh
exec /nix/store/sz52xjgb6viyfbp7w0221hj2jr5avkgf-vim_configurable-8.0.1605/bin/vim -u /nix/store/d52j23wnwz3swwbgv68mnl1i463a1hpn-vimrc  "$@"
```
It invokes Vim using `-u` to control which vimrc is used.

## vimrc

Let's see what's actually loaded when I start Vim.
```sh
vim -c 'set nomore' \
    -c 'redir > outfile | scriptnames | redir END' \
    -c 'quit'
```

The `scriptnames` ex command lists all the scripts Vim has sourced, in order.
The resulting `outfile` lists about 60 scripts, but it's worth noting what's *not* in the list.
When we queried the nix store earlier, we saw a couple vimrc entries:
```
/nix/store/d52j23wnwz3swwbgv68mnl1i463a1hpn-vimrc
/nix/store/63av9cp8hkwsr332nv5whpnq2k3z0iqg-nixos-vimrc
```

The first one sets up Vim's `'packpath'` (so the plugins in `vim-pack-dir` can be used) and contains the contents of the vimrc I passed as `customRC`.
This is what Vim is using.

The second, `nixos-vimrc`, is not being used, so why is it there?
We can see that it's referenced by `vim_configurable`, and it turns out the reference is a [symlink](https://github.com/NixOS/nixpkgs/blob/a9cbf62c60ad68a54af0a4c10277af6d5655910b/pkgs/applications/editors/vim/configurable.nix#L183) in `"$out"/share/vim/vimrc`.
```
nix-store --query --referrers /nix/store/63av9cp8hkwsr332nv5whpnq2k3z0iqg-nixos-vimrc
/nix/store/sz52xjgb6viyfbp7w0221hj2jr5avkgf-vim_configurable-8.0.1605

ls -l $(nix-store --query --requisites \
          /run/current-system/sw \
        | grep 'vim_configurable')/share/vim/vimrc
```

Inside Vim, we can see that `"$out"/share/vim/vimrc` corresponds to `$VIM/vimrc`:
```
:echo glob("$VIM/vimrc")
/nix/store/sz52xjgb6viyfbp7w0221hj2jr5avkgf-vim_configurable-8.0.1605/share/vim/vimrc
```

When Vim is started normally, it reads the system vimrc (e.g. `$VIM/vimrc`) and your personal vimrc (e.g. `$HOME/.vim/vimrc`).
But when invoked with `-u` specifying a vimrc, Vim loads *only* that vimrc.

This is why neither the symlinked `nixos-vimrc` nor `$HOME/.vim/vimrc` are loaded by our `vim` wrapper.
It's also why `$MYVIMRC` isn't set.

We can verify this by comparing a wrapped invocation with one that calls the executable directly:
```sh
# wrapped: /nix/store/pf28xvba6q4j50iiihlzym58l4x4w0rg-vim/bin/vim
vim \
  -c 'set nomore' \
  -c 'redir @a | scriptnames | redir END' \
  -c 'call append(".", matchstr(@a, "\\S\\+vimrc\\S*\\>"))'
```

```sh
# direct: /nix/store/sz52xjgb6viyfbp7w0221hj2jr5avkgf-vim_configurable-8.0.1605/bin/vim
$(grep --max-count=1 -oP 'exec \K\S+' $(readlink -f $(which vim))) \
  -c 'set nomore' \
  -c 'redir @a | scriptnames | redir END' \
  -c 'call append(".", matchstr(@a, "\\S\\+vimrc\\S*\\>"))'
```

Since we're not using `nixos-vimrc`, what are we missing out on?

`nixos-vimrc` [searches a few locations](https://github.com/NixOS/nixpkgs/blob/a9cbf62c60ad68a54af0a4c10277af6d5655910b/pkgs/applications/editors/vim/configurable.nix#L23-L33), including `/run/current-system/sw/share/vim-plugins/`, for plugins.
It then [sources](https://github.com/NixOS/nixpkgs/blob/a9cbf62c60ad68a54af0a4c10277af6d5655910b/pkgs/applications/editors/vim/configurable.nix#L40-L44) `/etc/vimrc` or `/etc/vim/vimrc` if either exists.

In light of this, I might rethink my current configuration.
I'd like to continue using Vim's `'packpath'` to manage plugins, but rather than using `-u` to specify a vimrc, I think putting my system-wide configuration in `/etc/vimrc` would provide a more consistent, intuitive user experience, since `$HOME/.vim/vimrc` would still be loaded and `$MYVIMRC` would be set.

The plugins you bake into Vim using `vim_configurable.customize` won't get symlinked into `/run/current-system/sw/share/vim-plugins/` unless you also list them in `environment.systemPackages`.
So if you don't want to bother with the intricacies of `customize`, you could instead list `vimHugeX` and the plugins you want in `environment.systemPackages`.
`vimHugeX` uses `vim_configurable` as is, so the `nixos-vimrc` will be used and it will load your plugins.
And since it also checks for the presence of `/etc/vimrc`, you could put your system-wide configuration there.

## vimrc

Let's look at the vimrc that Vim *is* using.
```sh
# /nix/store/d52j23wnwz3swwbgv68mnl1i463a1hpn-vimrc
less $(nix-store --query --requisites \
         /run/current-system/sw \
         | grep -P '^[^-]+-vimrc$')
```
```vim
" minimal setup, generated by NIX
set nocompatible

set packpath-=~/.vim/after
set packpath+=/nix/store/79a8mada9j90b6sr74v16c1afhl65hcw-vim-pack-dir
set packpath+=~/.vim/after

filetype indent plugin on | syn on

" This file is sourced early in the initialization process.
"
" I've extracted most customizations to into plugins organized using Vim 8's
" package feature. The only settings that need to remain in vimrc are those
" that must be set before loading other runtime files, plugins, or packages.

if exists('g:loaded_vimrc') | finish | endif
let g:loaded_vimrc = 1

let g:loaded_netrwPlugin = 1 " disable netrw (use dirvish instead)
let g:is_bash=1              " sh is bash
let g:sh_fold_enabled=1      " fold sh functions
let g:vimsyn_folding = "f"   " fold vim functions
let g:vimsyn_noerror = 1     " vim.vim sometimes gets it wrong
let g:fugitive_no_maps = 1   " leave me free to remap <C-R>

silent! source ~/.vim/vimrc.local
```

It adds `/nix/store/79a8mada9j90b6sr74v16c1afhl65hcw-vim-pack-dir` to Vim's `'packpath'`, allowing Vim's native `packages` feature to pick up the plugins I listed in `core-package.nix`.
Everything after the `filetype` line is from the `customRC` that I configured.
I've extracted most of my personal configuration into plugins, so my vimrc only contains things that need to be configured *before* plugins are loaded.

## plugins, packages, after

After reading vimrc(s), Vim searches its `'runtimepath'` for plugins.
From Vim's `:help load-plugins`:
> Load the plugin scripts.
> This does the same as the command: `runtime! plugin/**/*.vim`
>
> The result is that all directories in the 'runtimepath' option will be
> searched for the "plugin" sub-directory and all files ending in ".vim"
> will be sourced (in alphabetical order per directory), also in subdirectories.
> However, directories in 'runtimepath' ending in "after" are skipped

Next, Vim searches for packages:
> Packages are loaded.  These are plugins, as above, but found in the
> "start" directory of each entry in 'packpath'.  Every plugin directory
> found is added in 'runtimepath' and then the plugins are sourced.

Finally, Vim sources the contents of any `after` directories in the `'runtimepath'`.

## More to come

As I mentioned, using `-u` to specify a vimrc means Vim won't try to load `/etc/vimrc` or `$HOME/.vim/vimrc`, nor will it set the `$MYVIMRC` variable.
This is inconsistent with the behavior most users (myself included) are used to.

After getting more familiar with the inner workings of `vim_configurable`, I suspect it would be preferable to use `/etc/vimrc` to drive my system-wide configuration.
I'll revisit this in a followup post if I make that change.
