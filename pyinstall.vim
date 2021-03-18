
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
"==============================================================================
