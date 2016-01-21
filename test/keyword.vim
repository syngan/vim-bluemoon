scriptencoding utf-8

let s:save_cpo = &cpo
set cpo&vim

let s:suite = themis#suite('keywords')
let s:assert = themis#helper('assert')
let s:scope = themis#helper('scope')
let s:f = s:scope.funcs('autoload/bluemoon.vim')

function! s:suite.before() " {{{
highlight BM_red    gui=bold ctermfg=red   ctermbg=gray
highlight BM_blue   gui=bold ctermfg=blue  ctermbg=gray
highlight BM_cyan   gui=bold ctermfg=cyan  ctermbg=gray
highlight BM_brown  gui=bold ctermfg=brown ctermbg=gray
highlight BM_green  gui=bold ctermfg=green ctermbg=gray
highlight BM_unused gui=bold ctermfg=magenta ctermbg=gray
let g:bluemoon = {'colors': [
\  {'name': 'red', 'group': 'BM_red'},
\  {'name': 'blue', 'group': 'BM_blue'},
\  {'name': 'cyan', 'group': 'BM_cyan'},
\], 'keywords': [
\  {'group': 'BM_brown', 'pattern': 'paa'},
\  {'group': 'BM_green', 'pattern': 'doo'},
\  {'group': 'BM_brown', 'pattern': 'poo'},
\]}
call delete('/tmp/themis.log')
endfunction " }}}

function! s:suite.after() abort " {{{
  highlight clear BM_red
  highlight clear BM_brown
  highlight clear BM_blue
  highlight clear BM_cyan
  highlight clear BM_green
  highlight clear BM_unused
endfunction " }}}

let s:lines = [
      \ 'hoge foo baa hoge foo bar',
      \ 'hogehgoe fofofo',
      \ 'strwidthpart strwidthpart_reverse wcswidth',
      \]

function! s:suite.before_each() " {{{
  call bluemoon#enable()
  new
  call append(1, s:lines)
endfunction " }}}

function! s:suite.after_each() " {{{
  call bluemoon#disable()
  quit!
endfunction " }}}

function! s:log(str) abort " {{{
  if type(a:str) == type('')
    call writefile([a:str], "/tmp/themis.log", "a")
  elseif type(a:str) == type([])
    call writefile(a:str, "/tmp/themis.log", "a")
  else
    call writefile([string([a:str])], "/tmp/themis.log", "a")
  endif
endfunction " }}}

function! s:test(dict, msg, boo) abort " {{{
  if a:boo
    call extend(a:dict, {'paa': 'brown', 'doo': 'green', 'poo': 'brown'})
  endif
  let d = {}
  for v in getmatches()
    if v.group =~# '^BM_'
      call s:assert.has_key(a:dict, v.pattern, a:msg)
    endif
    let d[v.pattern] = v.group
    unlet v
  endfor
  for v in keys(a:dict)
    call s:assert.has_key(d, v, a:msg . string(bluemoon#debug(0).added_pattn) . string(getmatches()))
    call s:assert.equals(d[v], 'BM_' . a:dict[v], a:msg)
  endfor
endfunction " }}}

function! s:suite.do1() " {{{
  call s:assert.equals(bluemoon#check(), 1)
  call s:assert.has_key(g:bluemoon, 'keywords')
  call s:test({}, 'do1-0', 1)
  call bluemoon#enable()
  BlueMoon hoge red
  call s:test({'hoge': 'red'}, "add hoge", 1)
  BlueMoon foo    0
  call s:test({'hoge': 'red', 'foo': 'red'}, "add foo", 1)
  BlueMoon baa    1
  call s:test({'hoge': 'red', 'foo': 'red', 'baa': 'blue'}, "add bar", 1)
  BlueMoon -d red
  call s:test({'baa': 'blue'}, "del red", 1)
  BlueMoon baa
  call s:test({}, "del baa", 1)
endfunction " }}}

function! s:suite.delall() " {{{
  call s:test({}, 'dodo0', 1)
  BlueMoon hoge red
  call s:test({'hoge': 'red'}, 'dodo1', 1)
  BlueMoon hoge red
  call s:test({}, 'dodo2', 1)
  BlueMoon hoge red
  call s:test({'hoge': 'red'}, 'dodo3', 1)
  BlueMoon hoge red
  call s:test({}, 'dodo4', 1)
  BlueMoon hoge red
  call s:test({'hoge': 'red'}, 'dodo5', 1)
  BlueMoon -D
  call s:test({}, 'dodo6', 1)
  BlueMoon hoge red
  call s:test({'hoge': 'red'}, 'dodo7', 1)
  BlueMoon hoge red
  call s:test({}, 'dodo8', 1)
  BlueMoon hoge red
  call s:test({'hoge': 'red'}, 'dodo9', 1)
  BlueMoon hoge red
  call s:test({}, 'dodo10', 1)
  BlueMoon hoge red
  call s:test({'hoge': 'red'}, 'dodo11', 1)
endfunction " }}}

function! s:suite.nondef_color() " {{{
  call s:test({}, 'dodo0', 1)
  BlueMoon hoge BM_unused
  call s:test({'hoge': 'unused'}, "add hoge", 1)
  BlueMoon -d BM_unused
  call s:test({}, 'del unused', 1)
  BlueMoon hoge BM_unused
  call s:test({'hoge': 'unused'}, "add hoge2", 1)
  BlueMoon hoge BM_unused
  call s:test({}, 'del hoge2', 1)
  BlueMoon -D
  call s:test({}, 'delall', 1)
endfunction " }}}

function! s:suite.disable() " {{{
  call s:test({}, 'dodo0', 1)
  BlueMoon hoge BM_unused
  call s:test({'hoge': 'unused'}, "add hoge", 1)
  BlueMoon baa red
  call s:test({'hoge': 'unused', 'baa': 'red'}, "add baa", 1)
  call bluemoon#disable()
  call s:test({}, "disable", 0)
  call bluemoon#enable()
  call s:test({}, "enable", 1)
endfunction " }}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
