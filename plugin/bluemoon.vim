scriptencoding utf-8
" 日本語ファイル

let s:save_cpo = &cpo
set cpo&vim

" BlueMoon /pattern/ {name}
command! -range -nargs=+ BlueMoon
\ <line1>,<line2>call bluemoon#command(<q-args>)


let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
