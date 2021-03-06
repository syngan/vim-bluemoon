scriptencoding utf-8

let s:save_cpo = &cpo
set cpo&vim

" BlueMoon /pattern/ {name}
command! -nargs=* -complete=customlist,bluemoon#complete BlueMoon
\ <line1>,<line2>call bluemoon#command(<q-args>)


nnoremap <silent> <Plug>(bluemoon-cword) :<C-u>call bluemoon#cword('n')<CR>
vnoremap <silent> <Plug>(bluemoon-cword) :<C-u>call bluemoon#cword('v')<CR>

nnoremap <silent> <Plug>(bluemoon-clear) :<C-u>call bluemoon#clear()<CR>
vnoremap <silent> <Plug>(bluemoon-clear) :<C-u>call bluemoon#clear()<CR>

try
  call operator#user#define('bluemoon-op', 'bluemoon#op')
catch /E117:/
endtry

if get(g:, 'bluemoon#enable_at_startup', 0)
  call bluemoon#enable()
endif

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
