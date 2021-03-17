" init.vim/vimrc
"time the init script
let g:initstart = reltime()
let g:initfirstrun = v:false
set nocompatible "don't try to be compatible with vi, use vim features

let using_windows = has('win32') || has('win64')

"Get the path prefix depending on the install
if has('nvim')
    let pathprefix = stdpath('data')
elseif using_windows
    let pathprefix = expand('~/vimfiles')
else
    let pathprefix = expand('~/.vim')
endif

"build a string to describe the environment
let env_desc_str = join([
            \ has('nvim') ? 'Running NVIM' : 'Running VIM',
            \ "in",
            \ using_windows ? 'WINDOWS' : '*NIX',
            \ has('gui_running') ? 'GUI' : 'CONSOLE',
            \ ], ' ')

"echo some useful env info into messages - add more by adding to list g:initmsgs
let g:initmsgs = [
            \ env_desc_str,
            \ 'Path Prefix = ' .. pathprefix,
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
    let vp_local = pathprefix .. '/site/autoload/plug.vim'
else
    let vp_local = pathprefix .. '/autoload/plug.vim'
endif

"where to get vim-plug
let vp_url = 'https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'

"install vim-plug if it isn't already installed in the expected place
if empty(glob(vp_local))
    if using_windows
        silent execute '!powershell -command "iwr -useb' vp_url '| ni' vp_local '-Force"'
    else
        silent execute '!curl -fLo' vp_local '--create-dirs' vp_url
    endif
    autocmd VimEnter * PlugInstall --sync | source $MYVIMRC |
                \ echom ':source' $MYVIMRC |
                \ for msg in g:initmsgs | echom '  '..msg | endfor |
                \ redraw | AirlineRefresh
    let g:initmsgs += ['Installed vim-plug to '.. vp_local]
    let g:initfirstrun = v:true
endif
"==============================================================================

"Determine if we have a virtual environment for python, and ask user to create
"==============================================================================
let pyvenv_disabled_flag = pathprefix..'NO_PYTHON_VENV'
let pyvenv_disabled = !empty(glob(pyvenv_disabled_flag))
let python3_in_path = v:false
let python3_cmd = 'python'
let pythonver = system(python3_cmd .. ' -c "import sys; print(sys.version_info.major)"')
if pythonver >= 3
    let python3_in_path = v:true
else
    let python3_cmd = 'python3'
    let pythonver = system(python3_cmd .. ' -c "import sys; print(sys.version_info.major)"')
    if pythonver >= 3
        let python3_in_path = v:true
    endif
endif

if has('nvim') && !pyvenv_disabled && python3_in_path
    let pyvenv = pathprefix .. '/vim_python_venv'
    if empty(glob(pyvenv..'/pyvenv.cfg'))
        let create_venv = confirm("Python venv doesn't exist, do you want to create?",
                    \ "&Yes\n&No\n\&Don't Ask Again", 1)
        if create_venv == 0 || create_venv == 2
            let initmsgs += ["No venv"]
        elseif create_venv == 3
            let initmsgs += ["No venv, won't ask again"]
            silent !touch pyvenv_disabled_flag
        else
            let initmsgs += ["Creating python venv"]
            let venv_output = system(python3_cmd..' -m venv --upgrade-deps '
                        \ .. shellescape(pyvenv))
            if using_windows
                let pip_output = system(pyvenv..'/Scripts/activate.bat '
                            \ .. '&& pip install pynvim jedi flake8 yapf')
            else
                let pip_output = system('source '.. pyvenv ..'/bin/activate '
                            \ .. '&& pip install pynvim jedi flake8 yapf')
            endif
            let initmsgs += ["See variable venv_output and pip_output for details"]
        endif
    endif
    if !empty(glob(pyvenv..'/pyvenv.cfg'))
        let initmsgs += ["Python venv exists at: " .. pyvenv]
        let g:python3_host_prog = pyvenv..'/Scripts/python'
    endif
elseif pyvenv_disabled
    let initmsgs += ["Python VENV Disabled.  Delete" pyvenv_disabled_flag "to enable"]
endif
let initmsgs += [has('python3') ? 'PYTHON3 enabled' : 'PYTHON3 _NOT_ enabled']
"==============================================================================

call plug#begin(pathprefix .. '/plugged')

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

"If our first run, don't bother setting anything that requires the plugins
if g:initfirstrun
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
set list listchars=trail:»,tab:»- "viusally depict trailing space and tabs
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
end


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

"capture the initialization duration
let g:initmsgs += ['Init Duration = ' .. reltimestr(reltime(g:initstart)) .. ' seconds']
