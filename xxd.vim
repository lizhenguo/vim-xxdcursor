" Vim filetype plugin file
" Language:    XXD
" Maintainer:  Lech Lorens <lech.lorens@gmail.com>
" Last Change: 2014 Feb 4

" When the cursor is in the hexadecimal data representation, highlights the
" corresponding character in the ASCII column.
" When the cursor is in the ASCII column, highlights the corresponding two
" hexadecimal digits in the hex data area.

" Only do this when not done yet for this buffer
if exists("b:did_ftplugin")
	finish
endif

" Don't load another plugin for this buffer
let b:did_ftplugin = 1

" Line continuations...
let s:cpo_save = &cpo
set cpo-=C

augroup xxdhighlight
	autocmd! CursorMoved,CursorMovedI,WinEnter <buffer> call XxdHighlightMatching()
augroup END

function! XxdHighlightMatching()
	let [buf,c_lnum,col,off] = getpos('.')
	let line = substitute(getline('.'), '\v\s', ' ', 'g')

	let addr = substitute(line, '\v(^\x+:\s+).*', '\1', '')
	let addrLen = strlen(substitute(addr, '.', 'x', 'g'))

	let col -= addrLen

	3match none

	if col <= 0
		return
	endif

	let rest = substitute(line, '\v^\x+: +(.*)', '\1', '')

	" Let's check whether the cursor is in the hex representation part or in
	" the ASCII representation part of the line.

	let hexPairs = substitute(rest, '\v^(%(\x+ ?)+).*', '\1', '')
	let onlyHex = substitute(hexPairs, ' ', '', 'g')
	let hexBytes = strlen(onlyHex) / 2
	let hexPart = substitute(rest, '\v^(.*).{' . hexBytes . '}$', '\1', '')
	let hexLen = strlen(substitute(hexPart, '.', 'x', 'g'))

	if col <= hexLen
		" The cursor's in the hex part.
		let chars = split(hexPart, '\zs')
		if chars[col - 1] == ' '
			return
		endif

		let charIdx = 0
		if col > 1
			let hexBefore = substitute(hexPart, '\v^(.{' . (col - 1) . '}).*',
			            \ '\1', '')
			let onlyHex = substitute(hexBefore, ' ', '', 'g')
			let charIdx = strlen(onlyHex) / 2
		endif
		let c_col = addrLen + hexLen + charIdx + 1
		let c_after = c_col + 1
	else
		" The cursor's in the ASCII part.
		let matchOffset = 0

		let charIdx = col - hexLen - 1
		if charIdx > 0
			let hexBefore = substitute(hexPart,
			            \ '\v^(%(\x\x ?){' . charIdx . '}).*',
			            \ '\1', '')
			let matchOffset += strlen(hexBefore)
		endif
		let c_col = addrLen + matchOffset + 1
		let c_after = c_col + 2
	endif

	exe '3match MatchParen /\v%' . c_lnum . 'l%' . c_col . 'c.*\ze%' . c_after . 'c/'
endfunction

let &cpo = s:cpo_save
unlet s:cpo_save
