scriptencoding utf-8

let s:save_cpo = &cpo
set cpo&vim

let s:stat = {'enabled': 0, 'status': {}}

let s:hl = vital#of('bluemoon').import('Coaster.Highlight')

" g:bluemoon = {
"     'colors': [
"       {
"         'name': label,
"         'group': {group} of matchadd()
"         'priority': {priority} of matchadd()
"       }, args_of_:hi, ...],
" }
function! s:init_def() abort " {{{
  if exists('g:bluemoon') && has_key(g:bluemoon, 'colors')
    let s:stat.colors = g:bluemoon.colors
  else
    if type(s:stat.colors) != type([])
        call s:echoerr('invalid definition: colors not found')
        return
    endif
  endif

  if type(s:stat.colors) != type([])
      call s:echoerr('invalid definition: colors is not a List')
      return
  endif
  " @TODO hlexists()
  let s:stat.colorsdict = {}
  for i in range(len(s:stat.colors))
    let s:stat.colors[i] = s:colors_normalize(s:stat.colors[i], i)
    let s:stat.colorsdict[i] = s:stat.colors[i]
    let s:stat.colorsdict[s:stat.colors[i].name] = s:stat.colors[i]
  endfor
  let s:stat.added = {}
  let s:stat.status = {}
  let s:stat.index = 0
endfunction " }}}

function! s:colors_normalize(c, idx) abort " {{{
  if type(a:c) == type({})
    if !has_key(a:c, 'group')
      call s:echoerr('invalid definition colors[' . a:idx . '] does not have group member')
      return
    endif
     return extend(a:c, {'name': a:c.group, 'priority': 10, 'index': a:idx}, 'keep')
  else
    call s:echoerr('invalid definition colors[' . a:idx . ']')
  endif
endfunction " }}}

function! s:init() abort " {{{
  " :hi 実行
  call s:init_def()
endfunction " }}}

function! s:echoerr(msg) abort " {{{
  echohl ErrorMsg
  echomsg 'bluemoon: ' . a:msg
  echohl None
endfunction " }}}

function! s:parse_pattern(str) abort " {{{
  let str = matchstr(a:str, '^\s*\zs.*$')
  if str ==# ''
    return ['', '']
  elseif str =~# '^\i\S\+$'
    return [str, '']
  elseif str =~# '^\i'
    " 次の空白までが pattern
    let idx = match(str, '\s')
    let pattern = str[: idx-1]
    let str = matchstr(str[idx : ], '^\s*\zs.*$')
    return [pattern, str]
  else
    let delim = str[0]
    let idx = 1
    let pattern = ''
    while idx < len(str)
      if str[idx] ==# delim
        break
      elseif str[idx] == '\'
        if str[idx+1] ==# delim
          let pattern .= delim
        else
          let pattern .= str[idx : idx+1]
        endif
        let idx = idx + 2
      else
        let pattern .= str[idx]
        let idx = idx + 1
      endif
    endwhile
    let str = matchstr(str[idx+1: ], '^\s*\zs.*$')
    return [pattern, str]
  endif
endfunction " }}}

function! s:getopt(str) abort " {{{
  let str = a:str
  let args = []
  " opt[0] = 1 if option_end
  " opt[1] = 1 if option_in
  let opt = [0, 0]
  while str !~# '^\s*$'
    let str = matchstr(str, '^\s*\zs.*$')
    if str =~# '^[''"]'
      let typ = 1
      let arg = matchstr(str, printf('.*\ze\\@<!%s', str[0]), 1)
      let str = str[strlen(arg) + 2 :]
      let opt[opt[1]] = 1 - opt[1]
      " spece....?
    elseif str =~# '^`='
      let typ = 0
      let arg = matchstr(str, '.*\ze`', 2)
      let str = str[strlen(arg) + 3 :]
      let opt[opt[1]] = 1 - opt[1]
    elseif str[0] ==# '-' && !opt[0]
      " option.
      let typ = 1
      if str ==# '-'
        let arg = str
        let str = ''
      elseif str[1] !=# '-'
        let arg = str[: 1]
        let str = str[2 :]
        let opt[1] = 1
      else
        " @TODO
      endif
    elseif str[0] !~# '\i'
      " pattern
      let [arg, str] = s:parse_pattern(str)
      let typ = 1
      let opt[opt[1]] = 1 - opt[1]
    else
      let typ = 2
      let arg = matchstr(str, '\S\+')
      let str = str[strlen(arg) :]
    endif
    if typ != 0
      call add(args, arg)
    else
      let e = eval(arg)
      if type(e) == type([])
        let args += e
      else
        call add(args, e)
      endif
      unlet e
    endif
  endwhile

  return args
endfunction " }}}

function! s:get_name(arglist) abort " {{{
  return a:arglist[0]
endfunction " }}}

function! s:rotation() abort " {{{
  return s:stat.index % len(s:stat.colors)
endfunction " }}}

function! s:hl_add(pattern, ...) abort " {{{

  if has_key(s:stat.status, a:pattern)
    " s:hl_del...?
    let c = s:stat.status[a:pattern]
    let rname = printf('%s-%d', c.name, c.idx)
    echo printf("delete rname %s", rname)
    call s:hl.disable(rname)
    call s:hl.delete(rname)
    unlet s:stat.status[a:pattern]
    return
  endif

  let name = (a:0 > 0) ? a:1 : s:rotation()
  let priority = (a:0 > 1) ? a:2 : 10
  if has_key(s:stat.colorsdict, name)
    let group = s:stat.colorsdict[name].group
    let name = s:stat.colorsdict[name].name
  else
    let group = name
  endif
  let rname = printf('%s-%d', name, s:stat.index)
  call s:hl.add(rname, group, a:pattern, priority)
  call s:hl.enable(rname)
  if !has_key(s:stat.added, name)
    let s:stat.added[name] = [rname]
  else
    call add(s:stat.added[name], rname)
  endif
  let s:stat.status[a:pattern] = {'name': name, 'idx': s:stat.index, 'group': group, 'priority': priority}
  let s:stat.index += 1
  echo printf("add rname %s", rname)
endfunction " }}}

function! s:hl_del(args) abort " {{{
  let i = 0
  if i >= len(a:args)
   throw 'name not found'
  endif
  let name = a:args[i]
  let i += 1
  if has_key(s:stat.added, name)
    for c in s:stat.added[name]
      call s:hl.disable(c)
      call s:hl.delete(c)
    endfor
    unlet s:stat.added[name]
  endif
endfunction " }}}

function! s:hl_delall() abort " {{{
  call s:hl.delete_all()
  call s:hl.disable_all()
  let s:stat.added = {}
  let s:stat.status = {}
  let s:stat.index = 0
endfunction " }}}

function! bluemoon#show() abort " {{{
  return s:stat
endfunction " }}}

function! s:show() abort " {{{
  for c in keys(s:stat.status)
    let v = s:stat.status[c]
    echo printf("%2d:%s\t%s\t%s\t%d", v.idx, v.name, c, v.group, v.priority)
  endfor
endfunction " }}}

" BlueMoon [-a] {pattern} [name] [priority]  " add
" BlueMoon -d {name}                    " delete {name}
" BlueMoon -d {pattern}                 " delete {name}
" BlueMoon -D                           " delete all
" BlueMoon -s                           " show hl
function! bluemoon#command(arg) abort " {{{
  if !s:stat.enabled
    return
  endif
  let args = s:getopt(a:arg)
  let i = 0
  let mode = 'add'
  while i < len(args)
    if args[i] == '-d'
      let mode = 'del'
      let i += 1
    elseif args[i] == '-D'
      let mode = 'delall'
      let i += 1
    elseif args[i] == '-s'
      let mode = 'show'
      let i += 1
    elseif args[i] == '-a'
      let mode = 'add'
      let i += 1
    elseif args[i] == '-p'
      PP s:stat
    else
      break
    endif
  endwhile
  if mode ==# 'add'
    call call('s:hl_add', args[i :])
  elseif mode ==# 'del'
    call s:hl_del(args[i :])
  elseif mode ==# 'delall'
    call s:hl_delall()
  elseif mode ==# 'show'
    call s:show()
  endif

  return args
endfunction " }}}

function! bluemoon#enable() abort " {{{
  call s:init()
  let s:stat.enabled = 1
endfunction " }}}

function! bluemoon#disable() abort " {{{
  if s:stat.enabled
    call s:hl_delall()
    let s:stat.enabled = 0
  endif
endfunction " }}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
