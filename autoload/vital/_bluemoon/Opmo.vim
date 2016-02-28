scriptencoding utf-8

let s:save_cpo = &cpo
set cpo&vim

let s:_funcs = {'char' : {'v':'v'}, 'line': {'v':'V'}, 'block': {'v':"\<C-v>"}}

function! s:_knormal(s) abort " {{{
  execute 'keepjumps' 'silent' 'normal!' a:s
endfunction " }}}

function! s:_get_default_reg() abort " {{{
  return &clipboard =~# 'unnamedplus' ? '+'
     \ : &clipboard =~# 'unnamed'     ? '*'
     \ :                                '"'
endfunction " }}}

function! s:_reg_save() abort " {{{
  let reg = s:_get_default_reg()
  let regdic = {}
  for r in [reg]
    let regdic[r] = [getreg(r), getregtype(r)]
  endfor

  return [reg, regdic]
endfunction " }}}

function! s:_reg_restore(regdic) abort " {{{
  for [reg, val] in items(a:regdic)
    call setreg(reg, val[0], val[1])
  endfor
endfunction " }}}

function! s:_funcs.char.gettext(reg) abort " {{{
  call s:_knormal(printf('`[v`]"%sy', a:reg))
  return getreg(a:reg)
endfunction " }}}

function! s:_funcs.line.gettext(reg) abort " {{{
  call s:_knormal(printf('`[V`]"%sy', a:reg))
  return getreg(a:reg)
endfunction " }}}

function! s:_funcs.block.gettext(reg) abort " {{{
  call s:_knormal(printf('gv"%sy', a:reg))
  return getreg(a:reg)
endfunction " }}}

function! s:_funcs.char.highlight(begin, end, hlgroup) abort " {{{
  if a:begin[1] == a:end[1]
    return [matchadd(a:hlgroup,
    \ printf('\%%%dl\%%>%dc\%%<%dc', a:begin[1], a:begin[2]-1, a:end[2]+1))]
  else
    return [
    \ matchadd(a:hlgroup, printf('\%%%dl\%%>%dc', a:begin[1], a:begin[2]-1)),
    \ matchadd(a:hlgroup, printf('\%%%dl\%%<%dc', a:end[1], a:end[2]+1)),
    \ matchadd(a:hlgroup, printf('\%%>%dl\%%<%dl', a:begin[1], a:end[1]))]
  endif
endfunction " }}}

function! s:_funcs.line.highlight(begin, end, hlgroup) abort " {{{
  return [matchadd(a:hlgroup, printf('\%%>%dl\%%<%dl', a:begin[1]-1, a:end[1]+1))]
endfunction " }}}

function! s:_funcs.block.highlight(begin, end, hlgroup) abort " {{{
  return [matchadd(a:hlgroup,
        \ printf('\%%>%dl\%%<%dl\%%>%dc\%%<%dc',
        \ a:begin[1]-1, a:end[1]+1, a:begin[2]-1, a:end[2]+1))]
endfunction " }}}

function! s:gettext(motion) abort " {{{
  let fdic = s:_funcs[a:motion]
  let [reg, regdic] = s:_reg_save()
  try
    return fdic.gettext(reg)
  finally
    call s:_reg_restore(regdic)
  endtry
endfunction " }}}

function! s:highlight(motion, hlgroup) abort " {{{
  let fdic = s:_funcs[a:motion]
  let [reg, regdic] = s:_reg_save()

  try
    call s:_knormal(printf('`[%s`]"%sy', fdic.v, reg))
    let mids = fdic.highlight(getpos("'["), getpos("']"), a:hlgroup)
    return mids
  finally
    call s:_reg_restore(regdic)
  endtry
"   for m in mids
"     silent! call matchdelete(m)
"   endfor
endfunction " }}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
