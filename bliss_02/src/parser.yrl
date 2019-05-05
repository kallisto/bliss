Nonterminals list elems elem.
Terminals '[' ']' int float bool char atom string.
Rootsymbol elems.

list -> '[' ']'       : [].
list -> '[' elems ']' : '$2'.

elems -> elem       : ['$1'].
elems -> elem elems : ['$1'|'$2'].

elem -> int    : extract_token('$1').
elem -> float  : extract_token('$1').
elem -> bool   : extract_token('$1').
elem -> char   : extract_token('$1').
elem -> string : extract_token('$1').
elem -> atom   : extract_token('$1').
elem -> list   : '$1'.

Erlang code.

extract_token({_Token, _Line, Value}) -> Value.
