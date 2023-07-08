#!/bin/bash

# Some experiments with bash script variables
# Usage: ./test.sh arg

foo="echo"
bar=2

echo this.is.$((foo)).$((bar)).$((1)) # output: this.is.0.2.1
echo this.is.$foo.$bar.$1             # output: this.is.echo.2.arg
echo this.is.${foo}.${bar}.${1}       # output: this.is.echo.2.arg       


echo this.is.$((foo-1)).$((bar-1)).$((1)) # output: this.is.-1.1.1
echo this.is.$foo-1.$bar-1.$1-1           # output: this.is.echo-1.2-1.arg-1
echo this.is.${foo-1}.${bar-1}.${1-1}     # output: this.is.echo.2.arg