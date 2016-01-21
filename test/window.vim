scriptencoding utf-8

let s:save_cpo = &cpo
set cpo&vim

let s:suite = themis#suite('window')
let s:assert = themis#helper('assert')
let s:scope = themis#helper('scope')
let s:f = s:scope.funcs('autoload/bluemoon.vim')

function! s:suite.before() " {{{
highlight BM_red    gui=bold ctermfg=red   ctermbg=gray
highlight BM_brown  gui=bold ctermfg=brown ctermbg=gray
highlight BM_blue   gui=bold ctermfg=blue  ctermbg=gray
highlight BM_cyan   gui=bold ctermfg=cyan  ctermbg=gray
highlight BM_green  gui=bold ctermfg=green ctermbg=gray
highlight BM_unused gui=bold ctermfg=magenta ctermbg=gray
let g:bluemoon = {'colors':
\[
\  {'name': 'red', 'group': 'BM_red'},
\  {'name': 'blue', 'group': 'BM_blue'},
\  {'name': 'cyan', 'group': 'BM_cyan'},
\  {'name': 'green', 'group': 'BM_green'},
\  {'name': 'brown', 'group': 'BM_brown'},
\]}
call delete('/tmp/themis.log')
endfunction " }}}

let s:lines = [
      \ 'hoge foo baa hoge foo bar',
      \ 'hogehgoe fofofo',
      \ 'strwidthpart strwidthpart_reverse wcswidth',
      \]

function! s:suite.before_each() " {{{
  let s:winnr = winnr()
  call bluemoon#enable()
  new
  new
  new
  call append(1, s:lines)
  new
  new
  new
  new
endfunction " }}}

function! s:suite.after_each() " {{{
  call bluemoon#disable()
  while winnr() != s:winnr
    wincmd w
  endwhile
  only!
endfunction " }}}

function! s:log(str) abort " {{{
  if type(a:str) == type('')
    call writefile([a:str], "/tmp/themis.log", "a")
  elseif type(a:str) == type([])
    call writefile(a:str, "/tmp/themis.log", "a")
  else
    call writefile(string([a:str]), "/tmp/themis.log", "a")
  endif
endfunction " }}}

function! s:test(dict, msg) abort " {{{
  let NR = winnr()
  let nr = NR - 1
  while nr != NR
    :wincmd w
    let nr = winnr()

    let d = {}
    for v in getmatches()
      if v.group =~# '^BM_'
        call s:assert.has_key(a:dict, v.pattern, a:msg . printf('-%d-%d-%d', s:winnr, nr, NR))
      endif
      let d[v.pattern] = v.group
      unlet v
    endfor
    for v in keys(a:dict)
      call s:assert.has_key(d, v, a:msg . string(bluemoon#debug(0).added_pattn))
      call s:assert.equals(d[v], 'BM_' . a:dict[v], a:msg)
      unlet v
    endfor
  endwhile
endfunction " }}}

function! s:suite.do1() " {{{
  BlueMoon -c
  call s:test({}, 'dodo0')
  BlueMoon hoge red
  call s:test({'hoge': 'red'}, "add hoge")
  BlueMoon foo    0
  call s:test({'hoge': 'red', 'foo': 'red'}, "add foo")
  BlueMoon baa    1
  call s:test({'hoge': 'red', 'foo': 'red', 'baa': 'blue'}, "add bar")
  BlueMoon -d red
  call s:test({'baa': 'blue'}, "del red")
  BlueMoon -d 1
  call s:test({}, "del baa")
endfunction " }}}

function! s:suite.do2() " {{{
  BlueMoon -c
  call s:test({}, 'dodo0')
  BlueMoon hoge red
  call s:test({'hoge': 'red'}, "add hoge")
  BlueMoon foo    0
  call s:test({'hoge': 'red', 'foo': 'red'}, "add foo")
  wincmd w
  call s:test({'hoge': 'red', 'foo': 'red'}, "add foo")
  BlueMoon baa    1
  call s:test({'hoge': 'red', 'foo': 'red', 'baa': 'blue'}, "add bar")
  BlueMoon -d red
  call s:test({'baa': 'blue'}, "del red")
  BlueMoon -d 1
  call s:test({}, "del baa")
endfunction " }}}


let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
