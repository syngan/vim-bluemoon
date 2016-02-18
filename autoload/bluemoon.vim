scriptencoding utf-8

let s:save_cpo = &cpo
set cpo&vim

let s:stat = {'enabled': 0, 'added_pattn': {}, 'lock': 0}

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
    return s:echoerr('g:bluemoon is not defined')
  endif
  let d = a:0 > 0 ? a:1 : g:bluemoon
  let c = a:0 > 0 ? 'DEF' : 'g:bluemoon'
  if type(d) != type({})
    return s:echoerr(c . ' is not a dictionary')
  endif
  if !has_key(d, 'colors')
    return s:echoerr(c . ' does not have "colors"')
  endif
  if type(d.colors) != type([])
    return s:echoerr(c . '.colors is not a list')
  endif
  if len(d.colors) == 0
    return s:echoerr(c . '.colors does not have a member')
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
    if !hlexists(d.colors[i].group)
      call s:echoerr(c . '.colors[' . i . '].group does not exist. see :highlight')
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
    if str !~# '^[A-Za-z]'
      call s:echoerr(c . '.colors[' . i . '].name does not start with letters "[a-zA-Z]"')
      let ret = 0
      continue
    endif
    if has_key(name, tolower(str))
      call s:echoerr(c . '.colors[' . name[tolower(str)] . '] and colors[' . i . '] have same "name"')
      let ret = 0
    endif
    let name[tolower(str)] = i

    if has_key(d.colors[i], 'priority') && type(d.colors[i].priority) != type(0)
      call s:echoerr(c . '.colors[' . i . '].priority is not a number')
      let ret = 0
    endif
  endfor

  if has_key(d, 'keywords')
    if type(d.keywords) != type([])
      return s:echoerr(c . '.keywords is not a list')
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
      if !hlexists(d.keywords[i].group)
        call s:echoerr(c . '.keywords[' . i . '].group does not exist. see :highlight')
        let ret = 0
        continue
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
    if !s:stat.lock
      try
        let s:reflesh_flag = 0
        call s:hl.as_windo().enable_all()
      finally
        let s:reflesh_flag = 1
      endtry
    endif
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
  return 0
endfunction " }}}

function! s:parse_pattern(str, index) abort " {{{
  let index = match(a:str, '^\s*\zs.*$', a:index)
  if index < 0
    return ['', -1]
  elseif match(a:str, '^\i\S\+$', index) >= 0
    return [a:str[index : ], len(a:str)]
  elseif a:str[index] =~# '\i'
    " 次の空白までが pattern
    let idx = match(a:str, '\s', index)
    let pattern = a:str[index : idx-1]
    return [pattern, idx]
  else
    let delim = a:str[index]
    let idx = index  + 1
    let pattern = ''
    while idx < len(a:str)
      if a:str[idx] ==# delim
        break
      elseif a:str[idx] == '\'
        if a:str[idx+1] ==# delim
          let pattern .= delim
        else
          let pattern .= a:str[idx : idx+1]
        endif
        let idx += 2
      else
        let pattern .= a:str[idx]
        let idx += 1
      endif
    endwhile
    return [pattern, idx + 1]
  endif
endfunction " }}}

function! s:getopt(str, prm) abort " {{{
  let a = s:parse_args(a:str)
  let args = []
  let i = 0
  while i < len(a)
    if a[i][1] ==# '-'
      let idx = match(a:prm, a[i][0])
      if idx < 0
        throw printf('getopt: option -%s not recognized', a[i][0])
      elseif idx != match(a:prm, a[i][0] . ':', idx)
        call add(args, [a[i][0], ''])
        let i += 1
      elseif i + 1 == len(a) || a[i+1][1][0] ==# '-'
        throw printf('getopt: option -%s requires argument', a[i][0])
      else
        call add(args, [a[i][0], a[i+1][0]])
        let i += 2
      endif
    elseif a[i][1] ==# '--'
      let i += 1
      break
    else
      break
    endif
  endwhile

  return [args, map(a[i : ], 'v:val[0]')]
endfunction " }}}

function! s:parse_args(str) abort " {{{
  let str = a:str
  lockvar str
  let args = []
  " opt[0] = 1 if option_end
  " opt[1] = 1 if option_in
  let opt = [0, 0]
  let index = 0
  let slen = strlen(str)
  while index < slen
    let index = match(str, '^\s*\zs\S', index)
    if index < 0
      break
    elseif str[index] =~# '^[''"]'
      let s = matchstr(str, printf('.*\ze\\\@<!%s', str[index]), index + 1)
      let arg = [s, '"', index, index + strlen(s) + 2]
      let opt[opt[1]] = 1 - opt[1]
      " spece....?
    elseif match(str,'^`=.*`', index) >= 0
      let s = matchstr(str, '.*\ze`', index + 2)
      let arg = [s, '`', index, index + strlen(s) + 3]
      let opt[opt[1]] = 1 - opt[1]
    elseif str[index] ==# '-' && !opt[0]
      " option.
      if index + 1 == slen
        let arg = ['-', '-', index, index + 1]
      elseif str[index + 1] !=# '-'
        let arg = [str[index + 1], '-', index, index + 2]
        let opt[1] = 1
      else
        let arg = ['--', '--', index, index + 2]
        let opt[opt[1]] = 1 - opt[1]
      endif
    elseif str[index] !~# '\i'
      " pattern
      let [arg_, idx] = s:parse_pattern(a:str, index) " @TODO
      let arg = [arg_, '/', index, idx]
      let opt[opt[1]] = 1 - opt[1]
    else
      let s = matchstr(str, '\S\+', index)
      let arg = [s, 'v', index, index + strlen(s)]
      let index = arg[3]
    endif
    let index = arg[3]
    call add(args, arg)
  endwhile

  unlock str
  return args
endfunction " }}}

function! s:get_name(arglist) abort " {{{
  return a:arglist[0]
endfunction " }}}

function! s:rotation() abort " {{{
  return s:stat.counter % len(s:stat.colors)
endfunction " }}}

function! s:coasterhl_add_enable(rname, group, pattern, priority) abort " {{{
  try
    let s:reflesh_flag = 0
    call s:hl.add(a:rname, a:group, a:pattern, a:priority)
    if !s:stat.lock
      call s:hl.as_windo().enable(a:rname)
    endif
  finally
    let s:reflesh_flag = 1
  endtry
endfunction " }}}

function! s:coasterhl_del_disable(rname) abort " {{{
  try
    let s:reflesh_flag = 0
    call s:hl.as_windo().disable(a:rname)
    call s:hl.delete(a:rname)
  finally
    let s:reflesh_flag = 1
  endtry
endfunction " }}}

function! s:hl_add(pattern, ...) abort " {{{
  if has_key(s:stat.added_pattn, a:pattern)
    " s:hl_del...?
    let c = s:stat.added_pattn[a:pattern]
    let rname = c.rname
    call s:coasterhl_del_disable(rname)
    unlet s:stat.added_pattn[a:pattern]
    call filter(s:stat.added_rname[c.name], 'v:val.rname !=# rname')
    if a:0 == 0 || tolower(a:1) ==# c.name || a:1 ==# c.index
      call s:dprintf("del rname=%s, pattern=/%s/", rname, a:pattern)
      return
    endif
    let cmd = 'upd'
  else
    let cmd = 'add'
  endif

  if a:pattern ==# ''
    return s:echoerr('invalid argument: empty pattern')
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
  call s:dprintf('%s rname=%s, pattern=/%s/', cmd, rname, a:pattern)
endfunction " }}}

function! s:hl_del(...) abort " {{{
  let pm = ''
  for name in a:000
    let name = tolower(name)
    if name =~# '^[0-9]\+$'
      if !has_key(s:stat.colorsdict, name)
        continue
      endif
      let name = s:stat.colorsdict[name].name
    endif
    if has_key(s:stat.added_rname, name)
      let index = -1
      for c in s:stat.added_rname[name]
        call s:coasterhl_del_disable(c.rname)
        unlet s:stat.added_pattn[c.pattern]
        let index = c.index
      endfor
      let pm .= printf('%s[%d] ', name, index)
      unlet s:stat.added_rname[name]
    endif
  endfor
  if pm ==# ''
    call s:dprintf('del nothing')
  else
    call s:dprintf('del name=%s', pm)
  endif
endfunction " }}}

function! s:hl_clearall(hl) abort " {{{
  if s:stat.lock
    return
  endif
  try
    let s:reflesh_flag = 0
    call a:hl.as_windo().disable_all()
    call a:hl.disable_all()
    call a:hl.delete_all()
    call s:dprintf("delete all")
  finally
    let s:reflesh_flag = 1
  endtry
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
  let str = a:str
  let str = escape(str, '~"/\.^$[]*')
  let str = substitute(str, "\n", '\\n', 'g')
  return str
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
  let pattern =
        \ a:mode == 'n' ? printf('\<%s\>', expand('<cword>')) :
        \ a:mode == 'v' ? s:escape_pattern(s:get_selected_text()) : ''
  if v:count == 0
    call s:hl_add(pattern)
  else
    call s:hl_add(pattern, v:count)
  endif
endfunction " }}}

function! bluemoon#debug(p) abort " {{{
  if a:p == 0
    return s:stat
  endif
endfunction " }}}

function! s:show() abort " {{{
  if !s:stat.enabled
    return
  endif
  for c in keys(s:stat.added_pattn)
    let v = s:stat.added_pattn[c]
    execute 'echohl' v.group
    echo printf("%3d", v.index)
    echohl None
    echon printf(" %-18s %-18s %-13s %d", v.name, v.group, c, v.priority)
  endfor
  for v in s:stat.keywords
    execute 'echohl' v.group
    echo 'key'
    echohl None
    let c = v.pattern
    let v.priority = get(v, 'priority', 10)
    echon printf(" %-18s %-18s %-13s %d", '', v.group, c, v.priority)
  endfor
endfunction " }}}

function! bluemoon#lock() abort " {{{
  let s:reflesh_flag = 0
  if s:stat.lock
    call s:hl.as_windo().enable_all()
    call s:dprintf('unlock: enable all highlight')
  else
    call s:hl.as_windo().disable_all()
    call s:dprintf('lock:  disable all highlight')
  endif
  let s:reflesh_flag = 1
  let s:stat.lock = 1 - s:stat.lock
endfunction " }}}

function! s:complete_func(arg, cmd, pos, prm, compf) abort " {{{
  " @return [ [ comp1, comp2, ...], j ]
  " @return j: index of argument
  let a = s:parse_args(a:cmd)
  let i = 1
  let rest = '*'
  let j = 0
  while i < len(a) && a[i][2] <= a:pos
    if a[i][1] ==# '-'
      let idx = match(a:prm, a[i][0])
      if idx < 0
        " unknown option
        let i += 1
        continue
      endif
      if has_key(a:compf, a[i][0] . '*')
        let rest = a[i][0] . '*'
      endif
      if idx != match(a:prm, a[i][0] . ':', idx)
        " 引数を取らないオプション
        let i += 1
        continue
      elseif i+1 == len(a) || a:pos <= a[i+1][3]
        " @NOTEST
        return [[get(a:compf, '*', [])], -1, a[i][0]]
      endif
    elseif a[i][1] ==# '--'
      let j = 1
      break
    else
      break
    endif
  endwhile

  while i+j < len(a) && a[i+j][3] < a:pos
    let j += 1
  endwhile

  let l:Argf = get(a:compf, rest, [])
  if j == 0 && a:arg ==# '' && (i == len(a) || a[i][1] !=# '--')
    return [['option', l:Argf], j, '']
  else
    return [[l:Argf], j, '']
  endif
endfunction " }}}

function! s:complete(arg, cmd, pos, prm, compf) abort " {{{
  if a:arg =~# '^-\k\?'
    return map(filter(split(a:prm, '\zs'), 'v:val =~# ''\k'''), '"-" . v:val')
  endif
  let [cmpl, j, a] = s:complete_func(a:arg, a:cmd, a:pos, a:prm, a:compf)
  let candy = []
  for l:C in cmpl
    if type(C) == type([])
      let candy += C
    elseif type(C) == type(function('tr'))
      " 第 j 引数の補完
      " 引数 -$a の補完
      let candy += C(a, j)
    elseif C ==# 'option'
      let candy += map(filter(split(a:prm, '\zs'), 'v:val =~# ''\k'''), '"-" . v:val')
    else
      " @FIXME :command-complete*
    endif
    unlet C
  endfor
  return filter(candy, 'v:val =~# ''^' . a:arg . "'")
endfunction " }}}

function! s:complete_d(...) " {{{
  return keys(s:stat.added_rname)
endfunction " }}}

" @vimlint(EVL103, 1, a:_)
function! s:complete_add(a, j) " {{{
  if a:j == 0
    return map(keys(s:stat.added_pattn), '"/" . v:val . "/"')
  elseif a:j == 1
    return map(copy(g:bluemoon.colors), 'v:val["group"]')
  else
    return []
  endif
endfunction " }}}
" @vimlint(EVL103, 0, a:_)

let s:cmpf = {
\ 'd*': function('s:complete_d'),
\ '*': function('s:complete_add'),
\}
for s:u in ['D', 'l', 'c']
  let s:cmpf[s:u] = []
endfor
unlet s:u

function! bluemoon#complete(arg, cmd, pos) abort " {{{
  let v = s:complete(a:arg, a:cmd, a:pos, 'dDlc', s:cmpf)
  if type(v) == type([])
    return v
  endif

  let opts = ['-d', '-D', '-l', '-c']
  let args = s:parse_args(a:cmd)[1 :]
  let args = map(args, 'v:val[0]')
  if len(args) == 0
    return opts + map(keys(s:stat.added_pattn), '"/" . v:val . "/"')
  elseif a:arg =~# '^-'
    return opts
  elseif len(args) == 1
    if a:arg ==# '-d'
      if a:pos == len(a:cmd)
        return opts
      endif
      return keys(s:stat.added_rname)
    else
      " pattern
      if a:arg == '' && a:pos == len(a:cmd)
        " @TODO copy??
        return map(deepcopy(s:stat.colors), 'v:val.name')
      endif
    endif
  elseif len(args) == 2 && args[0] !~# '^-' && a:arg !=# ''
    if len(a:cmd) - a:pos < len(args[1])
      " @TODO copy??
      return filter(map(deepcopy(s:stat.colors), 'v:val.name'), 'v:val =~# "^" . a:arg')
    endif
  endif

  return []
endfunction " }}}

" BlueMoon {pattern} [name] [priority]  " add / del pattern
" BlueMoon -d {name}                    " delete {name}
" BlueMoon -D                           " delete all
" BlueMoon                              " show hl
" @vimlint(EVL102, 1, l:_)
function! bluemoon#command(arg) abort " {{{
  if !s:stat.enabled
    return
  endif
  try
    let [opts, args] = s:getopt(a:arg, 'dDplc')
  catch /getopt/
    call s:echoerr(substitute(v:exception, '^.*getopt: ', '', ''))
    return
  endtry
  let mode = 'add_or_show'
  for [o,_] in opts
    if o ==# 'd'
      let mode = 'del'
    elseif o ==# 'D'
      let mode = 'delall'
    elseif o ==# 'p'
      PP s:stat
    elseif o ==# 'l'
      let mode = 'lock'
    elseif o ==# 'c'
      let mode = 'check'
    else
      break
    endif
  endfor

  if mode ==# 'add_or_show'
    if len(args) == 0
      call s:show()
    else
      call call('s:hl_add', args)
    endif
  elseif mode ==# 'del'
    if len(args) == 0
      return s:echoerr('Usage: Bluemoon -d {name} ...')
    endif
    call call('s:hl_del', args)
  elseif mode ==# 'delall'
    if len(args) != 0
      return s:echoerr('Usage: Bluemoon -D')
    endif
    call bluemoon#clear()
  elseif mode ==# 'lock'
    if len(args) != 0
      return s:echoerr('Usage: Bluemoon -l')
    endif
    call bluemoon#lock()
  elseif mode ==# 'check'
    if len(args) != 0
      return s:echoerr('Usage: Bluemoon -c')
    endif
    if bluemoon#check()
      echo printf('bluemon: ok, %d colors and %d keywords are defined.',
            \ len(g:bluemoon.colors), len(get(g:bluemoon, 'keywords', 0)))
    endif
  endif

  return 1
endfunction " }}}
" @vimlint(EVL102, 0, l:_)

function! s:hl_reflesh() abort " {{{
  if s:reflesh_flag && !s:stat.lock
    call s:hl.as_windo().enable_all()
  endif
endfunction " }}}

function! bluemoon#enable() abort " {{{
  if !bluemoon#check()
    return
  endif
  augroup BlueMoon
    autocmd!
    autocmd VimEnter,WinEnter * call s:hl_reflesh()
  augroup END
  call s:init()
  let s:stat.enabled = 1
  let s:stat.lock = 0
endfunction " }}}

function! bluemoon#disable() abort " {{{
  if s:stat.enabled
    let s:stat.enabled = 0
    call bluemoon#clear()

    augroup BlueMoon
      autocmd!
    augroup END

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
