scriptencoding utf-8

let s:save_cpo = &cpo
set cpo&vim

let s:stat = {'enabled': 0, 'added_pattn': {}}

let s:hl = vital#of('bluemoon').import('Coaster.Highlight')

function! s:dprintf(...) abort " {{{
  if exists('g:bluemoon') && get(g:bluemoon, 'verbose', 0)
    if a:0 > 1
      echomsg 'bluemoon: ' . call('printf', a:000)
    elseif a:0 == 1
      echomsg 'bluemoon: ' . a:1
    endif
  endif
endfunction " }}}

function! bluemoon#check(...) abort " {{{
  if a:0 == 0 && !exists('g:bluemoon')
    call s:echoerr('g:bluemoon is not defined')
    return 1
  endif
  let d = a:0 > 0 ? a:1 : g:bluemoon
  let c = a:0 > 0 ? 'DEF' : 'g:bluemoon'
  if type(d) != type({})
    call s:echoerr(c . ' is not a dictionary')
    return 0
  endif
  if !has_key(d, 'colors')
    call s:echoerr(c . ' does not have "colors"')
    return 0
  endif
  if type(d.colors) != type([])
    call s:echoerr(c . '.colors is not a list')
    return 0
  endif
  if len(d.colors) == 0
    call s:echoerr(c . '.colors does not have a member')
    return 0
  endif
  let ret = 1
  let name = {}
  for i in range(len(d.colors))
    if type(d.colors[i]) != type({})
      call s:echoerr(c . '.colors[' . i . '] is not a dictionary')
      let ret = 0
      continue
    endif
    if !has_key(d.colors[i], 'group')
      call s:echoerr(c . '.colors[' . i . '] does not have "group"')
      let ret = 0
      continue
    endif
    if type(d.colors[i].group) != type('') || d.colors[i].group !~# '^[A-Za-z0-9_]\+$'
      call s:echoerr(c . '.colors[' . i . '].group does not consist of "[a-zA-Z0-9_]\+"')
      let ret = 0
      continue
    endif
    if type(get(d.colors[i], 'name', '')) != type('')
      call s:echoerr(c . '.colors[' . i . '].name is not a String')
      let ret = 0
      continue
    endif
    let str = get(d.colors[i], 'name', d.colors[i].group)
    if str !~# '^[A-Za-z0-9_]\+$'
      call s:echoerr(c . '.colors[' . i . '].name does not consist of "[a-zA-Z0-9_]\+"')
      let ret = 0
      continue
    endif
    if has_key(name, str)
      call s:echoerr(c . '.colors[' . name[str] . '] and colors[' . i . '] have same "name"')
      let ret = 0
    endif
    let name[str] = i

    if has_key(d.colors[i], 'priority') && type(d.colors[i].priority) != type(0)
      call s:echoerr(c . '.colors[' . i . '].priority is not a number')
      let ret = 0
    endif
  endfor

  if has_key(d, 'keywords')
    if type(d.keywords) != type([])
      call s:echoerr(c . '.keywords is not a list')
      return 0
    endif

    for i in range(len(d.keywords))
      if type(d.keywords[i]) != type({})
        call s:echoerr(c . '.keywords[' . i . '] is not a dictionary')
        let ret = 0
        continue
      endif
      if !has_key(d.keywords[i], 'pattern')
        call s:echoerr(c . '.keywords[' . i . '] does not have "pattern"')
        let ret = 0
        continue
      endif
      if type(d.keywords[i].pattern) != type('')
        call s:echoerr(c . '.keywords[' . i . '].pattern is not a string')
        let ret = 0
      endif
      if !has_key(d.keywords[i], 'group')
        call s:echoerr(c . '.keywords[' . i . '] does not have "group"')
        let ret = 0
        continue
      endif
      if type(d.keywords[i].group) != type('') || d.keywords[i].group !~# '^[A-Za-z0-9_]\+$'
        call s:echoerr(c . '.keywords[' . i . '].group does not consist of "[a-zA-Z0-9_]\+"')
        let ret = 0
      endif
      if has_key(d.keywords[i], 'priority') && type(d.keywords[i].priority) != type(0)
        call s:echoerr(c . '.keywords[' . i . '].priority is not a number')
        let ret = 0
      endif
    endfor
  endif

  return ret
endfunction " }}}

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
    let s:stat.colors[i] = s:colordef_normalize(s:stat.colors[i], i)
    let s:stat.colorsdict[i] = s:stat.colors[i]
    let s:stat.colorsdict[s:stat.colors[i].name] = s:stat.colors[i]
  endfor
  let s:stat.added_rname = {}
  let s:stat.added_pattn = {}
  let s:stat.counter = 0
endfunction " }}}

function! s:colordef_normalize(c, idx) abort " {{{
  if type(a:c) == type({})
    if !has_key(a:c, 'group')
      call s:echoerr('invalid definition colors[' . a:idx . '] does not have group member')
      return
    endif
    let a:c.index = a:idx
    let d = extend(a:c, {'name': a:c.group, 'priority': 10}, 'keep')
    let d.name = tolower(d.name)
    let d.group = tolower(d.group)
    return d
  else
    call s:echoerr('invalid definition colors[' . a:idx . ']')
  endif
endfunction " }}}

function! s:keywords() abort " {{{
  if exists('g:bluemoon') && has_key(g:bluemoon, 'keywords')
    for i in range(len(g:bluemoon.keywords))
      let k = g:bluemoon.keywords[i]
      let rname = printf('%s-keyword-%d', k.group, i)
      let priority = get(k, 'priority', 10)
      call s:hl.add(rname, k.group, k.pattern, priority)
    endfor
    call s:hl.as_windo().enable_all()
    let s:stat.keywords = copy(g:bluemoon.keywords)
    let s:stat.keywordsm = getmatches()
  endif
endfunction " }}}

function! s:init() abort " {{{
  " :hi 実行
  call s:init_def()
  call s:keywords()
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
  return s:stat.counter % len(s:stat.colors)
endfunction " }}}

function! s:coasterhl_add_enable(rname, group, pattern, priority) abort " {{{
  call s:hl.add(a:rname, a:group, a:pattern, a:priority)
  call s:hl.as_windo().enable(a:rname)
endfunction " }}}

function! s:coasterhl_del_disable(rname) abort " {{{
  call s:hl.as_windo().disable(a:rname)
  call s:hl.disable(a:rname)
  call s:hl.delete(a:rname)
endfunction " }}}

function! s:hl_add(pattern, ...) abort " {{{
  if has_key(s:stat.added_pattn, a:pattern)
    " s:hl_del...?
    let c = s:stat.added_pattn[a:pattern]
    let rname = c.rname
    call s:coasterhl_del_disable(rname)
    unlet s:stat.added_pattn[a:pattern]
    call s:dprintf("del rname=%s, pattern=%s", rname, a:pattern)
    " @TODO added_rname. see s:hl_del()
    return
  endif

  let name = (a:0 > 0) ? tolower(a:1) : s:rotation()
  let priority = (a:0 > 1) ? a:2 : 10
  if has_key(s:stat.colorsdict, name)
    let group = s:stat.colorsdict[name].group
    let name = s:stat.colorsdict[name].name
    let index = s:stat.colorsdict[name].index
  else
    let group = name
    let index = -1
  endif
  let rname = printf('%s-%d', name, s:stat.counter)
  call s:coasterhl_add_enable(rname, group, a:pattern, priority)
  let d = {'rname': rname, 'pattern': a:pattern, 'index': index,
        \ 'name': name, 'cnt': s:stat.counter, 'group': group, 'priority': priority}
  if !has_key(s:stat.added_rname, name)
    let s:stat.added_rname[name] = [d]
  else
    call add(s:stat.added_rname[name], d)
  endif
  let s:stat.added_pattn[a:pattern] = d
  let s:stat.counter += 1
  call s:dprintf('add rname=%s, pattern=[%s]', rname, a:pattern)
endfunction " }}}

function! s:hl_del(args) abort " {{{
  let i = 0
  if i >= len(a:args)
   throw 'name not found'
  endif
  let name = tolower(a:args[i])
  let i += 1
  if has_key(s:stat.added_rname, name)
    for c in s:stat.added_rname[name]
      call s:coasterhl_del_disable(c.rname)
      unlet s:stat.added_pattn[c.pattern]
    endfor
    unlet s:stat.added_rname[name]
  endif
  call s:dprintf("del name=%s", name)
endfunction " }}}

function! s:hl_clearall(hl) abort " {{{
  call a:hl.as_windo().disable_all()
  call a:hl.disable_all()
  call a:hl.delete_all()
endfunction " }}}

function! bluemoon#clear() abort " {{{
  call s:hl_clearall(s:hl)
  let s:stat.added_rname = {}
  let s:stat.added_pattn = {}
  let s:stat.counter = 0
  if s:stat.enabled
    call s:keywords()
  endif
endfunction " }}}

function! s:escape_pattern(str) abort " {{{
  return escape(a:str, '~"/\.^$[]*')
endfunction " }}}

function! s:get_selected_text() abort " {{{
  let reg = '"'
  let regdic = {}
  for r in [reg]
    let regdic[r] = [getreg(r), getregtype(r)]
  endfor
  try
    keepjumps silent normal! gv""y
    return getreg('"')
  finally
    for r in [reg]
      call setreg(r, regdic[r][0], regdic[r][1])
    endfor
  endtry
endfunction " }}}

function! bluemoon#cword(mode) abort " {{{
  let idx = v:count
  let pattern =
        \ a:mode == 'n' ? printf('\<%s\>', expand('<cword>')) :
        \ a:mode == 'v' ? s:escape_pattern(s:get_selected_text()) : ''
  return bluemoon#command(printf('/%s/ %d', pattern, idx))
endfunction " }}}

function! bluemoon#debug(p) abort " {{{
  if a:p == 0
    return s:stat
  endif
endfunction " }}}

function! s:show() abort " {{{
  for c in keys(s:stat.added_pattn)
    let v = s:stat.added_pattn[c]
    echo printf("%2d:%s\t", v.index, v.name)
    execute 'echohl' v.group
    echon printf("%s", v.group)
    echohl None
    echon printf("\t%s\t%d", c, v.priority)
  endfor
endfunction " }}}

" BlueMoon {pattern} [name] [priority]  " add / del pattern
" BlueMoon -d {name}                    " delete {name}
" BlueMoon -D                           " delete all
" BlueMoon                              " show hl
function! bluemoon#command(arg) abort " {{{
  if !s:stat.enabled
    return
  endif
  let args = s:getopt(a:arg)
  let i = 0
  let mode = 'add_or_show'
  while i < len(args)
    if args[i] == '-d'
      let mode = 'del'
      let i += 1
    elseif args[i] == '-D'
      let mode = 'delall'
      let i += 1
    elseif args[i] == '-p'
      PP s:stat
    elseif args[i] == '-c'
      let mode = 'check'
      let i += 1
    else
      break
    endif
  endwhile

  if mode ==# 'add_or_show'
    if len(args) == 0
      call s:show()
    else
      call call('s:hl_add', args[i :])
    endif
  elseif mode ==# 'del'
    call s:hl_del(args[i :])
  elseif mode ==# 'delall'
    call bluemoon#clear()
  elseif mode ==# 'check'
    call bluemoon#check()
  endif

  return args
endfunction " }}}

function! bluemoon#enable() abort " {{{
  if !bluemoon#check()
    return
  endif
  augroup BlueMoon
    autocmd!
    autocmd VimEnter,WinEnter * call s:hl.as_windo().enable_all()
  augroup END
  call s:init()
  let s:stat.enabled = 1
endfunction " }}}

function! bluemoon#disable() abort " {{{
  if s:stat.enabled
    let s:stat.enabled = 0
    call bluemoon#clear()
  endif
endfunction " }}}

let g:bluemoon#__hl__ = get(g:, 'bluemoon#__hl__', [])
call map(g:bluemoon#__hl__, 's:hl_clearall(v:val)')
let g:bluemoon#__hl__ = [s:hl]

if get(g:, 'bluemoon#enable_at_startup', 0)
  call bluemoon#enable()
endif

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
