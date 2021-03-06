" init.vim/vimrc
"time the init script
let g:initstart = reltime()
let s:initfirstrun = v:false
set nocompatible "don't try to be compatible with vi, use vim features

let g:using_windows = has('win32') || has('win64')
let g:pathsep = '/'
if g:using_windows
    let g:pathsep = '\'
endif

"get the path to our VIMRC
let g:VIMRCPath = expand("<sfile>:p:h")

"Get the path prefix depending on the install
if has('nvim')
    let s:pathprefix = stdpath('data')
elseif g:using_windows
    let s:pathprefix = expand('~\vimfiles')
else
    let s:pathprefix = expand('~/.vim')
endif

"build a string to describe the environment
let s:env_desc_str = join([
            \ has('nvim') ? 'Running NVIM' : 'Running VIM',
            \ "in",
            \ g:using_windows ? 'WINDOWS' : '*NIX',
            \ has('gui_running') ? 'GUI' : 'CONSOLE',
            \ ], ' ')

"echo some useful env info into messages - add more by adding to list g:initmsgs
let g:initmsgs = [
            \ s:env_desc_str,
            \ 'Path Prefix = ' .. s:pathprefix,
            \ ]

augroup vimrc
    "clear the vimrc autocmds so they don't duplicate
    autocmd!
    "Want to write the messages, but not wait for a return if (N)VIM isn't open
    "so put an autocmd in on VimEntry
    autocmd VimEnter * echom "Init" $MYVIMRC |
                \ for msg in g:initmsgs | echom '  '..msg | endfor | redraw
    "That won't source the messages if we do it manually, though, so
    "if the VIMRC file is sourced from command, print out the messages
    autocmd SourceCmd $MYVIMRC source $MYVIMRC |
                \ echom ':source' $MYVIMRC |
                \ for msg in g:initmsgs | echom '  '..msg | endfor |
                \ redraw | AirlineRefresh
    "remove trailing whitespace on save
    autocmd BufWritePre * call StripTrailingWhite()
augroup END

"Assess whether we have vim-plug and install if needed, regardless of platform
"==============================================================================
"where to install vim-plug
if has('nvim')
    let s:vp_local = join([s:pathprefix, 'site', 'autoload', 'plug.vim'], g:pathsep)
else
    let s:vp_local = join([s:pathprefix, 'autoload', 'plug.vim'], g:pathsep)
endif

"where to get vim-plug
let s:vp_url = 'https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'

"install vim-plug if it isn't already installed in the expected place
if empty(glob(s:vp_local))
    if g:using_windows
        silent execute '!powershell -command "iwr -useb' s:vp_url
                    \ '| ni' s:vp_local '-Force"'
    else
        silent execute '!curl -fLo' s:vp_local '--create-dirs' s:vp_url
    endif
    autocmd VimEnter * PlugInstall --sync | source $MYVIMRC |
                \ echom ':source' $MYVIMRC |
                \ for msg in g:initmsgs | echom '  '..msg | endfor |
                \ redraw | AirlineRefresh
    let g:initmsgs += ['Installed vim-plug to '.. s:vp_local]
    let s:initfirstrun = v:true
endif
"==============================================================================

let s:pyvenv = join([s:pathprefix, 'vim_python_venv'], g:pathsep)
if !empty(glob(join([s:pyvenv, 'pyvenv.cfg'], g:pathsep)))
    let initmsgs += ["Python venv exists at: " .. s:pyvenv]
    let g:python3_host_prog = join([s:pyvenv, 'Scripts', 'python'], g:pathsep)
endif
let g:initmsgs += [has('python3') ? 'PYTHON3 enabled' : 'PYTHON3 _NOT_ enabled']

call plug#begin(join([s:pathprefix, 'plugged'], g:pathsep))

"colorschemes/aesthetics
Plug 'jnurmine/zenburn'
Plug 'joshdick/onedark.vim'
Plug 'junegunn/seoul256.vim'
Plug 'tomasr/molokai'
Plug 'ajmwagar/vim-deus'
Plug 'vim-scripts/neutron.vim'
Plug 'zaki/zazen'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'

"functional plugins
Plug 'scrooloose/nerdtree'
Plug 'scrooloose/nerdcommenter'
Plug 'jiangmiao/auto-pairs'
Plug 'Konfekt/FastFold'
Plug 'tpope/vim-fugitive'

"python dev plugins
Plug 'Vimjas/vim-python-pep8-indent'
Plug 'dense-analysis/ale'
Plug 'tmhedberg/SimpylFold'

if has('nvim')
  Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
else
  Plug 'Shougo/deoplete.nvim'
  Plug 'roxma/nvim-yarp'
  Plug 'roxma/vim-hug-neovim-rpc'
endif
Plug 'deoplete-plugins/deoplete-jedi'

call plug#end()

"Function definition
"Clear trailing whitespace, save window view before execution
function! StripTrailingWhite()
    let l:winview = winsaveview()
    silent! %s/\s\+$//
    call winrestview(l:winview)
endfunction

function! CheckVIMRCStatus(override)
    if empty(glob(join([g:VIMRCPath, '.git'], g:pathsep))) || (!a:override &&
            \ !empty(glob(join([g:VIMRCPath, '.no_vimrc_update'], g:pathsep))))
        return 0
    endif
    execute 'cd' g:VIMRCPath
    let l:behind = system('git rev-list --count main..origin/main')
    let l:ahead = system('git rev-list --count origin/main..main')
    let l:dirty = !empty(system('git status --porcelain'))
    execute 'cd -'
    if !l:behind && !l:ahead && !l:dirty    "no difference from origin
        return 0
    elseif l:behind && !l:ahead && !l:dirty "origin has an update to pull
        return 1
    else "local changes need to be merged
        return 2
    endif
endfunction

function! UpdateVIMRC()
    if empty(glob(join([g:VIMRCPath, '.git'], g:pathsep)))
        echom 'No .git local repository. Clone'
                    \ 'https://github.com/kazdov/vim-setup-jmv to'
                    \ g:VIMRCPath 'to get started'
        return
    endif
    if !empty(glob(join([g:VIMRCPath, '.no_vimrc_update'], g:pathsep)))
        let l:update_choice = confirm('Override and update vimrc?',
                    \ "&No\n&Once\n&Always Update")
        if l:update_choice <= 1
            echom 'Aborted VIMRC update'
            return
        elseif l:update_choice == 3
            let l:del = delete(join([g:VIMRCPath, '.no_vimrc_update'], g:pathsep))
            echom 'Re-enabled VIMRC update'
        endif
    endif
    let l:vimrc_status = CheckVIMRCStatus(v:true)
    if !l:vimrc_status
        echom 'VIMRC is already synced'
        return
    elseif l:vimrc_status == 2
        echom 'VIMRC is locally updated - use Git to resolve and sync to origin'
        return
    else
        echom 'Updating VIMRC and sourcing again'
        return | source $MYVIMRC
    endif
endfunction

"If our first run, don't bother setting anything that requires the plugins
if s:initfirstrun
    let g:initmsgs += ['Init Duration = ' ..
                \ reltimestr(reltime(g:initstart)) .. ' seconds']
    finish
endif

"Vim settings: reiterates default in many cases, but ensure consistency
filetype plugin indent on "ensure that filetypes trigger contextual behavior
syntax on  "ensure syntax highlighting is on
set title  "Set the title of the window to filename
set number "Turn on line numbers
"Set sane tab behavior for python
set tabstop=8 softtabstop=4 shiftwidth=4 expandtab smarttab
set autoindent "Indent to the same as the previous line
set colorcolumn=80 "color the 80th column
set encoding=utf-8 "explicit utf-8 encoding
set list listchars=trail:??,tab:??- "viusally depict trailing space and tabs
set belloff="" "turn the bell on for all default events
set visualbell "but make it a visual bell - a screen flash
set hlsearch incsearch "searches should highlight, be incremental
set wildmenu  "provide a completion menu when tabbing in command window
set modeline "allow modelines to set file specific options
if has('clipboard')
    set clipboard=unnamed "use the system clipboard as the default register
    let g:initmsgs += ['CLIPBOARD supported, set to "unnamed" register']
else
    let g:initmsgs += ['No CLIPBOARD support']
endif

"Aesthetic settings
set termguicolors
color molokai

" Plugin settings
" NERDTree
let NerdTreeShowHidden=1

" Deoplete settings
let g:deoplete#enable_at_startup = 1
" deoplete tab-complete
inoremap <expr><tab> pumvisible() ? "\<c-n>" : "\<tab>"

"General User Mappings
let mapleader=',' "use comma to start user key mappings

"open and close NERDTree window
nmap <leader>d :NERDTreeToggle<CR>
nmap \ <leader>d

"open and close individual, and all folds with space combos
nnoremap <space> za
nnoremap <C-space> zi

"toggle line numbers
nnoremap <leader>n :set number!<CR>

"clear search highlights
nnoremap <leader>h :noh<CR>

"clear trailing whitespace
nnoremap <leader>w :call StripTrailingWhite()<CR>


"map kj for insert mode to go to Normal
inoremap kj <Esc>

"map Esc for terminal mode to go to Normal
tmap <Esc> <C-\><C-n>
tmap kj <Esc>

"Check whether there are updates to VIMRC
let s:vimrcsync = CheckVIMRCStatus(0)

"capture the initialization duration
let g:initmsgs += ['Init Duration = ' .. reltimestr(reltime(g:initstart)) .. ' seconds']
let g:initmsgs += s:vimrcsync ? ['VIMRC out of sync, use :UpdateVIMRC to update'] : []
