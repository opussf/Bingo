#!/usr/bin/env lua
require "wowTest"

test.outFileName = "testOut.xml"
test.coberturaFileName = "../coverage.xml"

ParseTOC( "../src/Bingo.toc" )

function test.before()
end
function test.after()
end

----------
-- Tests
function test.test_01()
end

test.run()