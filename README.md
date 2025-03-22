## Setup
#### Me
```shell
g cl --recurse-submodules git@github.com:ashgw/dotfiles.git
```
#### Not me

This will work on any POSIX machine, to **automatically**:
- Configure the terminal (ZSH, starship, zioxde, etc...)
- SSH [setup](./.ssh/_gh_gen.sh)
- Neovim, TMUX, FZF...
- Nix
- [Packages](./install/bootsrap) I use
- [Languages](./install/arbitrary) I use
- Git [configuration](./.gitconfig), (Aliases, multiple accounts, etc...)


>[!CAUTION]
>The installation script is meant to be used on a minimal Debian installation. It will replace any existing configuration. Proceed with caution.
```shell
bash <(curl -L ashgw.me/api/v1/bootstrap)
```

### Overview

 <div style="flex: 1; min-width: 200px; margin: 5px;">
    <img src="./images/ag.png" alt="Image 1" style="width: 100%;">
  </div>

 <div style="flex: 1; min-width: 200px; margin: 5px;">
    <img src="./images/research.png" alt="Image 1" style="width: 100%;">
  </div>



 <div style="flex: 1; min-width: 200px; margin: 5px;">
    <img src="./images/blur0.png" alt="Image 1" style="width: 100%;">
  </div>
 <div style="flex: 1; min-width: 200px; margin: 5px;">
    <img src="./images/tux.png" alt="Image 1" style="width: 100%;">
  </div>


 <div style="flex: 1; min-width: 200px; margin: 5px;">
    <img src="./images/snow.png" alt="Image 1" style="width: 100%;">
  </div>

 <div style="flex: 1; min-width: 200px; margin: 5px;">
    <img src="./images/files.png" alt="Image 1" style="width: 100%;">
  </div>





<div style="flex: 1; min-width: 200px; margin: 5px;">
    <img src="./images/black0.png" alt="Image 1" style="width: 100%;">
  </div>


 <div style="flex: 1; min-width: 200px; margin: 5px;">
    <img src="./images/purp.png" alt="Image 1" style="width: 100%;">
  </div>


 <div style="flex: 1; min-width: 200px; margin: 5px;">
    <img src="./images/red-is-dead.png" alt="Image 1" style="width: 100%;">
  </div>
 <div style="flex: 1; min-width: 200px; margin: 5px;">
    <img src="./images/black-1.png" alt="Image 1" style="width: 100%;">
  </div>
 <div style="flex: 1; min-width: 200px; margin: 5px;">
    <img src="./images/vscode-dark.png" alt="Image 1" style="width: 100%;">
  </div>


<div style="flex: 1; min-width: 200px; margin: 5px;">
    <img src="./images/w-vim.png" alt="Image 1" style="width: 100%;">
  </div>

 <div style="flex: 1; min-width: 200px; margin: 5px;">
    <img src="./images/btop-dark.png" alt="Image 1" style="width: 100%;">
  </div>

 <div style="flex: 1; min-width: 200px; margin: 5px;">
    <img src="images/new/pyyyyo.png" alt="Image 1" style="width: 100%;">
  </div>


### Workflow

1- A ton of aliases, even aliasing the aliases, I don't like mental overhead, if it takes more than 3 words to type, it has to be aliased. So this what I usually type, it might not make sense to you, but it makes a lot of sense to me

```shell
dprune && lpg && g ck -b dev && j t && j l && v . && c && gh
```
you can also check [zshfuncs](https://github.com/ashgw/zshfuncs).

2- Mediocre rice

3- Neovim, tmux & fzf? YES
