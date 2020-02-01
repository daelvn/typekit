# Technical specification for `typekit.debug`

This explains how debugging works in typekit and what is the
preferred procedure.

## `DEBUG` flag

A flag in `typekit.config` named `DEBUG` will determine if anything
is printed out or not. The module is still dependent on `inspect`.
This may change in the future.

## STDOUT virtual buffer

The virtual buffer of STDOUT is set to `"no"`. Lua holds in text
in a virtual buffer and then prints it. This means that Lua can
error in between and get a message that never prints. This makes
Lua print whatever it has been commanded "immediately".

## Debugging library

The debugging is provided by [debugkit][1] and the coloring is
provided by [ansikit][2].

### Exclude

Loggers from [debugkit][1] provide an `exclude` table which will
filter out any message that is tagged with any of the tags in this
table. If a log message is sent with tag "noprint" and `exclude`
contains "noprint", it will not print. Tags follow the format
`<path.to.module>.<function> [#part]`, so `type.typeof.resolve #got`
is a valid formatting. Generally, log lines that report arguments
are tagged with part `#got`, returns with `#ret`, and generic
log lines have no part.

### Processors

Processors are [inspect][3] option tables with a `process` function
only that are prepared to exclude some of the tables from
inspection.

#### `typekit.debug.processor.sign`

This one removes all metatables and values with key `type` and
`call` from the end result.

#### `typekit.debug.processor.match`

This one removes all values with key `__parent` and `parent`.

[1]: https://github.com/daelvn/debugkit
[2]: https://github.com/daelvn/ansikit
[3]: https://github.com/kikito/inspect.lua