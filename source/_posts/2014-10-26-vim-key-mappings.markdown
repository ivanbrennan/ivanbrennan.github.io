---
layout: post
title: "vim key-mappings"
date: 2014-10-26 12:04
comments: true
categories: vim
---

### :map
In the land of Vim, most key sequences can easily be mapped to others. The basic syntax is `map a b`, which tells Vim that when you type `a`, it should act like `b`. Similarly, `map abc wxyz` would process `wxyz` when you typed `abc`, but let's look at a more useful example.

You can use `m` to set a mark at the current cursor position, then jump to it later using the backtick (`` ` ``) key. Take this buffer for example:
``` ruby
def penguify(being)
  Penguin.new(being.mass)
rescue NameError
  puts "Can't penguify massless being."
end
```
I'll put my cursor on the *N* in `NameError` and type (in normal mode) `mx`. This sets a mark we can jump to by typing ```x``. This is nice, but the backtick isn't the most comfortable key to reach for.

There's a similar command using the single-quote. Typing `'x` jumps to the first non-whitespace character on the marked line. Probably not as useful. Let's map the more reachable `'` to the more useful `` ` ``.

On Vim's command-line, enter: ``map ' ` ``. Now both `` ` `` and `'` will take us directly to our mark. Instead of ditching the single-quote's original command entirely, let's map the backtick to it with ``map ` '``. But this causes a problem. Hit either `` ` `` or `'` and you'll get an error (`E223: recursive mapping`). We've mapped `` ` `` to `'`, which triggers `` ` ``, which triggers `'`, and on and on.

### :noremap
To recover, let's remove both mappings with ``unmap ` `` and `unmap '`, to start fresh. Now instead of using `map` we'll use `noremap`. Running `noremap a b` will map `a` to `b` but avoid triggering anything `b` is mapped to. So we can enter ``noremap ' ` `` and ``noremap ` '`` to swap our keys without falling into a recursive pit.

### map-modes
Depending on how you define them, your key-mappings will only apply in certain modes. The mappings we created with `map` and `noremap` apply in Normal, Visual, Select, and Operator-pending modes. Note the absence of Insert mode in that list -- we're not in danger of inserting ``doesn`t`` when we wanted `doesn't`.

The `map`, `noremap`, and `unmap` commands each have mode-specific variations. My .vimrc, for instance, has a mapping for line-completion in Insert mode:

    inoremap <C-L> <C-X><C-L>

The `<C-L>` represents Control-L, and is case-insensitive (same as `<c-l>`). This makes line-completion less cumbersome without polluting modes other than Insert with the mapping. For more on map-modes, check out `:help :map-modes`. The map-overview (`:help map-overview`) is a good place to start.

### key-notation
Vim uses a special notation for some keys. We saw `<C-L>` already. There's also `<Left>`, `<S-Left>` (shift-left), `<Space>`, `<CR>` (carriage return / enter), and many more (see `:help key-notation`). We can use these to expand our key-mapping vocabulary.

### editor-envy
I noticed a feature in Sublime Text that I wanted to simulate in Vim: `⌘Enter` adds a newline to the *end* of the current line rather than inserting it at the cursor position. This is handy if you're in the middle of a line and want to open a new line beneath it without breaking the text the cursor's on.

To similate this, I needed to `inoremap` something to `<C-O>o`. From Insert mode, `<C-O>` pops you into Normal mode for a single command. Once there, `o` opens a new line beneath the current one and drops you onto it in Insert mode. In the interest of portability, I decided against using the `⌘` key, since it's Mac-specific, and went with Control instead:

    inoremap <C-CR> <C-O>o

Now I can hit Control-Enter from Insert mode to drop down to a new line without disrupting the one I'm on. Actually no, I can't. I can if I'm using MacVim, but terminal Vim doesn't recognize the `<C-CR>` key-combo. This is where things get interesting.

### terminal keycodes
To get the `<C-CR>` key-mapping to work in terminal Vim, I needed to first tell iTerm what to send when I hit Control-Enter, then tell Vim what to listen for and how to interpret it. Let's start with iTerm. The steps for Terminal.app are similar, though the menus and appearance will differ.

In iTerm's *Preferences* (`⌘,`), the *Profiles* tab has a *Keys* subtab. From there, you can define custom actions to trigger with any number of key-combinations. Clicking the '**+**' at the bottom of the list reveals a dialog to add a new combination.

{% img screenshot /images/iterm/keys.png 'keys' 'iterm keys screenshot' %}

I hit Control-Enter to enter `^↩` in the *Keyboard Shortcut* field and selected *Send Escape Sequence* from the *Action* drop-down, revealing a field labeled "Esc+". Here I entered `[25~`, telling iTerm to send Esc + `[25~` when Control-Enter is typed.

"Why `[25~`? Where did that come from?" I was hoping you wouldn't ask. Figuring out what codes to use, what wouldn't conflict with anything, and what would be interpretted consistently across xterm, GNU screen, and tmux was not a straightforward process. Lots of googling and trial and error, and recounting it is probably best saved for another post. For now, I'll stay focused on getting it wired up with Vim.

Next, I needed to tell Vim how to interpret the `^[[25~` escape sequence that iTerm would be sending its way. (Note that the initial `^[` is the Escape character itself.) I set an unused Function key to the escape sequence:

    set <F13>=^[[25~

To enter that command correctly, you need to type `set <F13>=`, hit Control-V, hit Escape, then finish with `[25~`. Control-V followed by Escape enters the actual terminal code for the Escape key (which *appears* as the single character `^[`). The same is true whether you're entering it on Vim's command-line or inserting it in your .vimrc.

With Vim listening for the escape sequence and associating it with a key, I mapped that key to `<C-CR>`:

    map  <F13> <C-Cr>  
    map! <F13> <C-Cr>

The call to `map` applies the mapping in Normal, Visual, Select, and Operator-pending mappings, while `map!` applies to Insert and Command-line mappings. With all this in place, terminal Vim can recognize Control-Enter and the `<C-CR>` key-notation.

You can apply this approach to a lot of other key's that would otherwise be off-limits. A section of my [vimrc](https://github.com/ivanbrennan/vim/blob/master/vimrc) wires up a bunch of them. I'm cutting down on the mappings these days, but it's nice to know you can do this:

    if &term =~ "xterm" || &term =~ "screen" || &term =~ "builtin_gui"
      " Ctrl-Enter
      set  <F13>=[25~
      map  <F13> <C-CR>
      map! <F13> <C-CR>

      " Shift-Enter
      set  <F14>=[27~
      map  <F14> <S-CR>
      map! <F14> <S-CR>

      " Ctrl-Space
      set  <F15>=[29~
      map  <F15> <C-Space>
      map! <F15> <C-Space>

      " Shift-Space
      set  <F16>=[30~
      map  <F16> <S-Space>
      map! <F16> <S-Space>

      " Ctrl-Backspace
      set  <F17>=[1;5P
      map  <F17> <C-BS>
      map! <F17> <C-BS>

      " Alt-Tab
      set  <F18>=[1;5Q
      map  <F18> <M-Tab>
      map! <F18> <M-Tab>

      " Alt-Shift-Tab
      set  <F19>=[1;5R
      map  <F19> <M-S-Tab>
      map! <F19> <M-S-Tab>

      " Ctrl-Up
      set  <F20>=[1;5A
      map  <F20> <C-Up>
      map! <F20> <C-Up>

      " Ctrl-Down
      set  <F21>=[1;5B
      map  <F21> <C-Down>
      map! <F21> <C-Down>

      " Ctrl-Right
      set  <F22>=[1;5C
      map  <F22> <C-Right>
      map! <F22> <C-Right>

      " Ctrl-Left
      set  <F23>=[1;5D
      map  <F23> <C-Left>
      map! <F23> <C-Left>

      " Ctrl-Tab
      set  <F24>=[31~
      map  <F24> <C-Tab>
      map! <F24> <C-Tab>

      " Ctrl-Shift-Tab
      set  <F25>=[32~
      map  <F25> <C-S-Tab>
      map! <F25> <C-S-Tab>

      " Ctrl-Comma
      set  <F26>=[33~
      map  <F26> <C-,>
      map! <F26> <C-,>

      " Ctrl-Shift-Space
      set  <F27>=[34~
      map  <F27> <C-S-Space>
      map! <F27> <C-S-Space>
    endif
