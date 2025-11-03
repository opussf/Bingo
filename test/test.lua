#!/usr/bin/env lua
require "wowTest"

test.outFileName = "testOut.xml"
test.coberturaFileName = "../coverage.xml"

ParseTOC( "../src/Bingo.toc" )

test.run()