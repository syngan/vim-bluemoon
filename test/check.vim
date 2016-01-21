scriptencoding utf-8

let s:save_cpo = &cpo
set cpo&vim

let s:suite = themis#suite('check')
let s:assert = themis#helper('assert')
let s:scope = themis#helper('scope')
let s:f = s:scope.funcs('autoload/bluemoon.vim')

function! s:suite.body() " {{{
  call s:assert.equals(bluemoon#check([1]), 0)
  call s:assert.equals(bluemoon#check(3), 0)
endfunction " }}}

function! s:suite.before() " {{{
highlight BM_red    gui=bold ctermfg=red   ctermbg=gray
endfunction " }}}

function! s:suite.after() " {{{
highlight clear BM_red
endfunction " }}}

function! s:suite.colors() " {{{
  let bm = {}
  call s:assert.equals(bluemoon#check(bm), 0)
  let bm = {'colors' : 3}
  call s:assert.equals(bluemoon#check(bm), 0)
  let bm = {'colors' : []}
  call s:assert.equals(bluemoon#check(bm), 0)
  let bm = {'colors' : [3]}
  call s:assert.equals(bluemoon#check(bm), 0)
  let bm = {'colors' : ['h']}
  call s:assert.equals(bluemoon#check(bm), 0)
  let bm = {'colors' : {}}
  call s:assert.equals(bluemoon#check(bm), 0)
  let bm = {'colors' : [{'group': []}]}
  call s:assert.equals(bluemoon#check(bm), 0)
  let bm = {'colors' : [{'group': 'BM_red'}]}
  call s:assert.equals(bluemoon#check(bm), 1, 'ok?' . hlexists('todo') . string(getmatches()))
  let bm = {'colors' : [{'group': 'todo@'}]}
  call s:assert.equals(bluemoon#check(bm), 0)
  let bm = {'colors' : [{'group': 'todo-'}]}
  call s:assert.equals(bluemoon#check(bm), 0)
  let bm = {'colors' : [{'group': 'BM_red', 'name': []}]}
  call s:assert.equals(bluemoon#check(bm), 0)
  let bm = {'colors' : [{'group': 'BM_red', 'name': 'foo_0'}]}
  call s:assert.equals(bluemoon#check(bm), 1)
  let bm = {'colors' : [{'group': 'BM_red', 'name': '1'}]}
  call s:assert.equals(bluemoon#check(bm), 0)
  let bm = {'colors' : [{'group': 'BM_red', 'name': 'foo-0'}]}
  call s:assert.equals(bluemoon#check(bm), 0)
  let bm = {'colors' : [{'group': 'BM_red'}, {'group': 'BM_red'}]}
  call s:assert.equals(bluemoon#check(bm), 0, 'same grp1')
  let bm = {'colors' : [{'group': 'BM_RED'}, {'group': 'BM_red'}]}
  call s:assert.equals(bluemoon#check(bm), 0, 'same grp2')
endfunction " }}}

function! s:suite.keywords() " {{{
  let b = {'colors' : [{'group': 'bm_red'}]}
  let bm = extend(copy(b), {'keywords': 1})
  call s:assert.equals(bluemoon#check(bm), 0)
  let bm = extend(copy(b), {'keywords': {}})
  call s:assert.equals(bluemoon#check(bm), 0)
  let bm = extend(copy(b), {'keywords': [3]})
  call s:assert.equals(bluemoon#check(bm), 0)
  let bm = extend(copy(b), {'keywords': [{}]})
  call s:assert.equals(bluemoon#check(bm), 0)
  let bm = extend(copy(b), {'keywords': [{'group': 'BM_red', 'pattern': 'key'}]})
  call s:assert.equals(bluemoon#check(bm), 1, 'ok1' . string(bm))
  let bm = extend(copy(b), {'keywords': [{'pattern': 'key'}]})
  call s:assert.equals(bluemoon#check(bm), 0, 'ng1')
  let bm = extend(copy(b), {'keywords': [{'group': 'BM_red'}]})
  call s:assert.equals(bluemoon#check(bm), 0, 'ng2')
  let bm = extend(copy(b), {'keywords': [{'group': 't_not_exist_h'}]})
  call s:assert.equals(bluemoon#check(bm), 0, 'ng3')
endfunction " }}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
"
