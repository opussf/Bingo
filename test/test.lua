#!/usr/bin/env lua
require "wowTest"

test.outFileName = "testOut.xml"
test.coberturaFileName = "../coverage.xml"
test.coverageReportPercent = true

ParseTOC( "../src/Bingo.toc" )

function test.before()
    chatLog = {}
    Bingo.OnLoad()
    Bingo.PLAYER_ENTERING_WORLD()
end
function test.after()
end

----------
-- Tests
function test.test_helpFunction()
    Bingo.Command("help")
    test.dump(chatLog)
end

test.run()