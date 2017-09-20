Definitions.

COMMENT    = \(\*([^\*]|\*+[^\)*])*\*\)
INT        = [-+]?[0-9]+
FLOAT      = [-+]?[0-9]+\.[0-9]+
TRUE       = true
FALSE      = false
CHAR       = '[0-9a-zA-Z_\-\:]
STRING     = \".*\"
ATOM       = [0-9a-zA-Z_\-\:]+
OP         = [^0-9a-zA-Z\s\t\n\r\[\]\(\)\"\']+
WHITESPACE = [\s\t\n\r]

% ^ Period is counted as an OP!

Rules.

{COMMENT}     : skip_token.
{INT}         : {token, {int,    TokenLine, list_to_integer(TokenChars)}}.
{FLOAT}       : {token, {float,  TokenLine, list_to_float(TokenChars)}}.
{TRUE}        : {token, {bool,   TokenLine, true}}.
{FALSE}       : {token, {bool,   TokenLine, false}}.
{CHAR}        : {token, {char,   TokenLine, unquote(TokenChars)}}.
{STRING}      : {token, {string, TokenLine, unquote(TokenChars)}}.
{ATOM}        : {token, {atom,   TokenLine, list_to_atom(atomize(TokenChars))}}.
{OP}          : {token, {atom,   TokenLine, list_to_atom(TokenChars)}}. % this is 'atom' on purpose
\[            : {token, {'[',    TokenLine}}.
\]            : {token, {']',    TokenLine}}.
\(            : skip_token.
\)            : skip_token.
{WHITESPACE}+ : skip_token.

Erlang code.

atomize(Chars) ->
  [case X of $: -> $.; _ -> X end || X <- Chars].

unquote([$',Char]) ->
  <<Char>>;
unquote([$"|Chars]) ->
	list_to_binary(lists:droplast(Chars)).
