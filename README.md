# Pyret Lambda Calculus Parser

This library is a simple implementation of a lambda calculus parser,
but it is primarily meant to serve two other purposes:

1. Provide a stubbed version of Pyret's real `trove/ast.arr` file to
test on compiler development (such as register allocation)
2. Illustrate how self-contained Pyret projects can be built 
using `make` and a symbolic link to the 
[pyret-lang](https://github.com/brownplt/pyret-lang) repository*. 
Check out the `Makefile` to see how.

*Note that the [CPO](https://github.com/brownplt/code.pyret.org) 
repository does this to an extent as well, but the intention here
is to provide a demonstration for projects which live entirely
outside of the browser, so certain steps (such as a custom 
standalone file) which CPO takes are ommitted here for clarity.

## Usage
To build the project, make sure that you have created the 
`pyret-lang` symbolic link and run `make PHASE`, where `PHASE` is
the Pyret compiler phase you would like to use to compile the
project.

For logistical reasons, this repository does not support Windows
(Cygwin/MSYS2 may work, but they are untested).

See `LICENSE` for license information.
