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
  let bm = {'colors' : [{'group': 'todo'}]}
  call s:assert.equals(bluemoon#check(bm), 1)
  let bm = {'colors' : [{'group': 'todo@'}]}
  call s:assert.equals(bluemoon#check(bm), 0)
  let bm = {'colors' : [{'group': 'todo-'}]}
  call s:assert.equals(bluemoon#check(bm), 0)
  let bm = {'colors' : [{'group': 'todo', 'name': []}]}
  call s:assert.equals(bluemoon#check(bm), 0)
  let bm = {'colors' : [{'group': 'todo', 'name': 'foo_0'}]}
  call s:assert.equals(bluemoon#check(bm), 1)
  let bm = {'colors' : [{'group': 'todo', 'name': 'foo-0'}]}
  call s:assert.equals(bluemoon#check(bm), 0)
  let bm = {'colors' : [{'group': 'todo'}, {'group': 'todo'}]}
  call s:assert.equals(bluemoon#check(bm), 0, 'same grp1')
  let bm = {'colors' : [{'group': 'todo'}, {'group': 'toDO'}]}
  call s:assert.equals(bluemoon#check(bm), 0, 'same grp2')
endfunction " }}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
"
