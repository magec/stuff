"http://www.vim.org/htmldoc/options.html
"http://rayninfo.co.uk/vimtips.html
set nocompatible "Usa config por defecto de vim
syntax on "Muchos colores
set paste "No indentar codigo 'pasteado'
set pdev=HP4250IN3b "Impresora a usar
set nobackup "No crea ficheros de backup *~
set showcmd "Muestra comandos incompletos
set ignorecase "ignorar case en búsquedas
set ruler "Mestra siempre la pos. del cursor
set number "Muestra nº de líneas
set mouse=a "No quiero que el mouse copie el nº de lineas.
set tabstop=4 "Tabs de 4 espacios
set expandtab "Inserta espacios en vez de Tabs
set encoding=utf-8 "Encoding
set foldmethod=marker "folding manual
"Espacios redundantes y Tabs
highlight RedundantSpaces ctermbg=blue guibg=blue
match RedundantSpaces /\s\+$\| \+\ze\t\|\t/
"Set up the status line
fun! <SID>SetStatusLine()
    let l:s1="%-3.3n\\ %f\\ %h%m%r%w"
    let l:s2="[%{strlen(&filetype)?&filetype:'?'},%{&encoding},%{&fileformat}]"
    let l:s3="%=\\ 0x%-8B\\ \\ %-14.(%l,%c%V%)\\ %<%P"
    execute "set statusline=" . l:s1 . l:s2 . l:s3
endfun
set laststatus=2 "Always show this status line
call <SID>SetStatusLine()
"Volver a 'tabear' al leer buffer, puede ser destructivo.
"autocmd BufRead * retab

