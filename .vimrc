"http://www.vim.org/htmldoc/options.html
"http://rayninfo.co.uk/vimtips.html
"http://github.com/gigamo/
"
"{{{   General
"-------------------------------------------------------------------------------
set nocompatible        "Usa config por defecto de vim
syntax on               "Muchos colores
set paste               "No indentar codigo 'pasteado'
set pdev=HP4250IN3b     "Impresora a usar
set nobackup            "No crea ficheros de backup *~
set ignorecase          "ignorar case en búsquedas (usando minúsculas)
set smartcase           "case sensitive si se usan mayúsculas
set number              "muetra nº de lineas
set encoding=utf-8      "Encoding
set termencoding=utf-8
set cursorline          "Resalta la línea del cursor
set listchars=tab:»·,trail:·,extends:~,nbsp:.,eol:$
set mouse=a             "selecciones no incluyen el nº de lineas.
set tabstop=4           "Tabs de 4 espacios
set expandtab           "Inserta espacios en vez de Tabs
set ttyfast             "Mejoras para terminales rápidas
set foldmethod=marker   "folding manual con {{{ }}}
set hlsearch            "Subraya las búsquedas
set showcmd             "Muestra comandos incompletos
set wildmenu            "Muestra menú con opciones de autocompletado
set visualbell          "Desactiva el beep (pero activa visualbell)
set t_vb=               "Anulamos la propia visualbell
"}}}
"{{{   Temas
"-------------------------------------------------------------------------------
if has('gui_running')
    set cursorline
    colorscheme zenburn     "Tema para gVim
elseif (&term =~ 'linux')
    colorscheme desert      "Tema para tty.
else
    set t_Co=256
    colorscheme gardener    "Tema para el resto
endif
"}}}
"{{{   Eventos
"-------------------------------------------------------------------------------
if has("autocmd")
    "Volver a 'tabear' al leer buffer.
    autocmd BufRead * retab
    "Mapeos a F6 para compilar.
    autocmd FileType sh       map <F6> :!sh & %<CR>
    autocmd FileType php      map <F6> :!php & %<CR>
    autocmd FileType python   map <F6> :!python %<CR>
    autocmd FileType perl     map <F6> :!perl %<CR>
    autocmd FileType ruby     map <F6> :!ruby %<CR>
    autocmd FileType lua      map <F6> :!lua %<CR>
    autocmd FileType htm,html map <F6> :!firefox %<CR>
    "Releer vimrc al guardar cambios.
    autocmd! BufWritePost .vimrc source %
endif
"}}}
"{{{   Funciones
"-------------------------------------------------------------------------------
if has("eval")
    "Línea de estados
    fun! <SID>SetStatusLine()
        let l:s1="%-3.3n\\ %f\\ %h%m%r%w"
        let l:s2="[%{strlen(&filetype)?&filetype:'?'},%{&encoding},%{&fileformat}]"
        let l:s3="%=\\ 0x%-8B\\ \\ %-14.(%l,%c%V%)\\ %<%P"
        execute "set statusline=" . l:s1 . l:s2 . l:s3
    endfun
    set laststatus=2          "Muestra siempre la línea de estado.
    call <SID>SetStatusLine() "La mostramos.
    "Eliminar espacios redundantes.
    fun! StripWhite()
        %s/[ \t]\+$//ge
        %s!^\( \+\)\t!\=StrRepeat("\t", 1 + strlen(submatch(1)) / 8)!ge
    endfun
    "Eliminar líneas en blanco.
    fun! RemoveBlankLines()
        %s/^[\ \t]*\n//g
    endfun
    "Marca en rojo los espacios redundantes.
    highlight RedundantSpaces ctermbg=red guibg=red
    match RedundantSpaces /\s\+$\| \+\ze\t\|\t/
endif
"}}}
