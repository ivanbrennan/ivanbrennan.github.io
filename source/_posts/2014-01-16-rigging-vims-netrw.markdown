---
layout: post
title: "Rigging Vim's Netrw"
date: 2014-01-16 01:00
comments: true
categories: vim
---
If you're a Vim user, you're probably familiar with the [NERDTree](http://www.vim.org/scripts/script.php?script_id=1075), a plugin that provides a sidebar for navigating the filesystem, much like you get with a more graphical editor such as Sublime Text. It's a nice feature, but you don't necessarily need to install another plugin to get it. Most distributions of Vim come with [Netrw](http://www.vim.org/scripts/script.php?script_id=1075) already built in. Built by [Charles CampBell](http://www.drchip.org/astronaut/index.html), Netrw is a plugin for browsing, reading, and writing files both locally and across networks.

Netrw is not NERDTree. It does much more, but the flip side is that NERDTree focuses on doing one thing well. That being said, at some point I got interested in reproducing what I liked about NERDTree using the built-in capabilities of Netrw. It took a bit of configuration and some dirty language (vimscript) but if you're not averse to any of that, read on.

{% img screenshot /images/vextoggle/4.png 'vim' 'vim screenshot' %}

My first goal was to toggle a sidebar navigator open/closed with a keystroke or two. The `:Vexplore` command opens a Netrw browser in a vertical split. If you pass the command a directory, it will open into that location, otherwise it opens in the current file's parent directory. There's a distinction between the current file's parent directory and the "current working directory" that Vim keeps track of. Say you start Vim from within ~/Development. You can `:edit` files anywhere you like (~/Development/resources, ~, /usr/local, etc.), and until you explicitly tell Vim to `:cd` to a new location, the current working directory will remain where it started, at ~/Development. You can use this as a home-base to work from in the current Vim session. With this in mind, I composed a small set of functions to toggle the sidebar in either the current file's directory (to access neighboring files), or the "current working directory" (which I tend to leave at the project root), and mapped them to a couple keystrokes I find convenient.

```
fun! VexToggle(dir)
  if exists("t:vex_buf_nr")
    call VexClose()
  else
    call VexOpen(a:dir)
  endif
endf
```

I'm using `t:vex_buf_nr` to track whether the sidebar is currently open. The `t:` is scoping the variable to the current tab. That's so each tab can have its own sidebar. If you're not familiar with Vim's tabs, don't worry about it. It's a minor detail here. In the else clause, we pass `a:dir` (the `dir` argument that was passed into `VexToggle()`) to `VexOpen()`.

```
fun! VexOpen(dir)
  let g:netrw_browse_split=4    " open files in previous window
  let vex_width = 25

  execute "Vexplore " . a:dir
  let t:vex_buf_nr = bufnr("%")
  wincmd H

  call VexSize(vex_width)
endf
```

`VexOpen()` starts by setting some options. "Open files in previous window" ensures that when we select a file to open, it opens in the window (split) we were in before entering the browser. We're also setting the desired window width for later use.

Next, we use vimscript's string concatenation operator (`.`) to compose the `Vexplore` call. It's a little ugly, but sometimes vimscript paints you into a corner like that. Now that we have an explorer open, let's remember it (the next line). The `"%"` expands to the current file name, and we store the associated buffer number for later reference.

If you have several splits open, calling `:Vexplore` will open a Netrw explorer in a vertical split next to *the current split*, so there's no guarantee it will sit on the far left of the screen or even occupy the full height of Vim. Calling `wincmd H` fixes that. Finally, calling `VexSize()` will set the sidebar's width.

I made a couple mappings to call `VexToggle()`. The first passes it Vim's "current working directory" as an argument, while the second passes an empty string. That way, I can use the first mapping to toggle an explorer sidebar from the project root and the second to toggle an explorer from whichever directory houses the file I'm currently editing.

```
noremap <Leader><Tab> :call VexToggle(getcwd())<CR>
noremap <Leader>` :call VexToggle("")<CR>
```

{% img screenshot /images/vextoggle/8.png 'vim' 'vim screenshot' %}

When the sidebar is open, either mapping can be used to close it. `VexClose()` starts by noting which window it was called from, so it can return the cursor to that window after the sidebar has closed. The exception is when the cursor was *in* the sidebar when `VexClose()` was called, in which case the cursor will land in the previous window (whichever window holds the alternate file `"#"`). The middle section switches to the sidebar, closes it, and removes the internal variable that was tracking its presence. Finally, we switch to the appropriate destination window and call `NormalizeWidths()` to normalize the widths of all open windows. Note that we have to subtract 1 from the original window number that was stored, since closing the sidebar window decremented all the remaining window numbers.

```
fun! VexClose()
  let cur_win_nr = winnr()
  let target_nr = ( cur_win_nr == 1 ? winnr("#") : cur_win_nr )

  1wincmd w
  close
  unlet t:vex_buf_nr

  execute (target_nr - 1) . "wincmd w"
  call NormalizeWidths()
endf
```

{% img screenshot /images/vextoggle/10.png 'vim' 'vim screenshot' %}

All that's left are the final touches to window sizing, which occur in `VexSize()` and `NormalizeWidths()`. The first function sets and locks the sidebar width, then calls the second to normalize the widths off all other windows. `NormalizeWidths()` is a little hacky, but as far as I can tell it's the only native vimscript way to normalize window widths without affecting their heights. `'eadirection'` controls which dimensions are affected when `'equal always'` is set. We set it to `hor` (horizontal), toggle `'equal always'` off and back on (it's on by default), triggering the width normalization, and finally restore `'eadirection'` to it's original value.

```
fun! VexSize(vex_width)
  execute "vertical resize" . a:vex_width
  set winfixwidth
  call NormalizeWidths()
endf

fun! NormalizeWidths()
  let eadir_pref = &eadirection
  set eadirection=hor
  set equalalways! equalalways!
  let &eadirection = eadir_pref
endf
```

Netrw lets you open a selected file in a vertical split with the `v` key, and I wanted to normalize window widths when such a split was added so things would remain evenly sized. The following autocommand makes it so.

```
augroup NetrwGroup
  autocmd! BufEnter * call NormalizeWidths()
augroup END
```

{% img screenshot /images/vextoggle/12.png 'vim' 'vim screenshot' %}

***Closing Notes***

I ran into a couple minor bugs in Netrw during all of this, and turned to the [vim_use](https://groups.google.com/forum/#!topic/vim_use/XNOcLYsgk8Y) mailing list for help. Netrw's author (Dr. Chip) was quick to respond with a fix and point me toward the [newest version](http://www.drchip.org/astronaut/vim/index.html#NETRW). Big thanks Dr. Chip!

I find myself mostly using Netrw's "thin" liststyle rather than the "tree" style I originally liked, but both work equally well in the sidebar. Finally, my [vimrc](https://github.com/ivanbrennan/vim/blob/master/vimrc) is available for reference, though the relevant Netrw settings I'm using are pasted below:

```
let g:netrw_liststyle=0         " thin (change to 3 for tree)
let g:netrw_banner=0            " no banner
let g:netrw_altv=1              " open files on right
let g:netrw_preview=1           " open previews vertically
```
