This version uses less elixir/erlang based infrastructure and is a test to see if a multi-stack architecture leads to simplified code.

The architecture is based on 4 stacks:

2 main stacks

- data stack (i.e. a list of compiled, internal representations)
- input stack (i.e. a stream of input characters)

2 secondary stacks

- dictionary stack (i.e. a list of definitions)
- output stack (i.e. a stack of output characters)
