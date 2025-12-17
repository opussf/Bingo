#!/usr/bin/env lua
require "wowTest"

test.outFileName = "testOut.xml"
test.coberturaFileName = "../coverage.xml"
test.coverageReportPercent = true

ParseTOC( "../src/Bingo.toc" )

function test.before()
	chatLog = {}
	Bingo_PlayerCards = {}
	Bingo_CurrentGame = {}
	Bingo.messageQueue = {}
	Bingo.OnLoad()
	Bingo.PLAYER_ENTERING_WORLD()
end
function test.after()
end

----------
-- Tests
function test.test_helpFunction()
    Bingo.Command("help")
end
function test.test_start_NewGame_sets_channel()
	Bingo.Command("guild")
	assertEquals( "guild", Bingo_CurrentGame.channel )
end
function test.test_start_NewGame_sets_startedAt()
	Bingo.Command("guild")
	assertAlmostEquals(time(), Bingo_CurrentGame.initAt)
end
function test.test_start_NewGame_sets_picked()
	Bingo.Command("guild")
	assertTrue( Bingo_CurrentGame.picked )
	assertIsNil( next( Bingo_CurrentGame.picked ) )
end

function test.test_start_GameStillRunning()
	Bingo_CurrentGame.channel = "party"
	Bingo_CurrentGame.initAt = time()-60
	Bingo.Command("guild")
	assertEquals( "party", Bingo_CurrentGame.channel )
end
function test.test_SendMessage_sent_str()
	Bingo_CurrentGame.channel = "say"
	-- SendMessages uses the choosen game channel
	Bingo.SendMessage( "Hello there" )
	assertEquals( "Hello there", chatLog[1].msg )
	assertEquals( "SAY", chatLog[1].chatType )
end
function test.test_queueMessage_goesIntoQueue()
	Bingo.QueueMessage( "Plushie", "say" )
	assertEquals( "Plushie", Bingo.messageQueue["say"].queue[1] )
	assertAlmostEquals( time()-1, Bingo.messageQueue["say"].last )
end
function test.test_queueMessage_isPosted()
	Bingo.messageQueue["say"] = { queue = {"kindle"}, last = time()-5 }
	Bingo.OnUpdate()
	assertEquals( "kindle", chatLog[1].msg )
end
function test.test_queueMessage_isPosted_toSay()
	Bingo.messageQueue["say"] = { queue = {"kindle"}, last = time()-5 }
	Bingo.OnUpdate()
	assertEquals( "SAY", chatLog[1].chatType )
end
function test.test_queueMessage_isPosted_isCleared()
	Bingo.messageQueue["say"] = { queue = {"kindle"}, last = time()-5 }
	Bingo.OnUpdate()
	assertIsNil( Bingo.messageQueue["say"] )
end
function test.test_bangCommands_help_toPlayer()
	Bingo.CHAT_MSG_WHISPER( {}, "!help", "Otherplayer-Other Realm" )
	assertTrue( Bingo.messageQueue["Otherplayer-Other Realm"] )
end
function test.test_bangCommands_help_queue_has_7()
	Bingo.CHAT_MSG_WHISPER( {}, "!help", "Otherplayer-Other Realm" )
	assertEquals( 7, #Bingo.messageQueue["Otherplayer-Other Realm"].queue )
end
function test.test_bangCommands_cards_one()
	Bingo.CHAT_MSG_WHISPER( {}, "!cards 1", "Otherplayer-Other Realm" )
	assertTrue( Bingo_PlayerCards["Otherplayer-Other Realm"], "Should be true." )
	hash, card = next( Bingo_PlayerCards["Otherplayer-Other Realm"] )
	assertEquals( 8, string.len(hash) )
	assertTrue( type(card) == "string" )
end
function test.test_bangCommands_cards_ten()
	Bingo.CHAT_MSG_WHISPER( {}, "!cards 10", "Otherplayer-Other Realm" )
	assertTrue( Bingo_PlayerCards["Otherplayer-Other Realm"] )
	local hash, card = next( Bingo_PlayerCards["Otherplayer-Other Realm"] )
	assertEquals( 8, string.len(hash) )
	assertTrue( type(card) == "string" )
end
function test.test_bangCommands_cards_overMax()
	Bingo.CHAT_MSG_WHISPER( {}, "!cards 100", "Otherplayer-Other Realm" )
	assertTrue( Bingo_PlayerCards["Otherplayer-Other Realm"] )
	local hash, card = next( Bingo_PlayerCards["Otherplayer-Other Realm"] )
	assertEquals( 8, string.len(hash) )
	assertTrue( type(card) == "string" )
end
function test.test_bangCommands_cards_zeroReturnsAllCards()
	Bingo.CHAT_MSG_WHISPER( {}, "!cards 10", "Otherplayer-Other Realm" )
	Bingo.CHAT_MSG_WHISPER( {}, "!cards 0", "Otherplayer-Other Realm" )
	assertIsNil( Bingo_PlayerCards["Otherplayer-Other Realm"] )
end
function test.test_bangCommand_list_noCards()
	Bingo.CHAT_MSG_WHISPER( {}, "!list", "Otherplayer-Other Realm" )
	assertEquals( "You have no cards to list.", Bingo.messageQueue["Otherplayer-Other Realm"].queue[1] )
end
function test.test_bangCommand_list_oneCard()
	Bingo.CHAT_MSG_WHISPER( {}, "!cards 1", "Otherplayer-Other Realm" )
	Bingo.CHAT_MSG_WHISPER( {}, "!list", "Otherplayer-Other Realm" )
	local hash, card = next( Bingo_PlayerCards["Otherplayer-Other Realm"] )
	assertEquals( "These are your card ids:", Bingo.messageQueue["Otherplayer-Other Realm"].queue[7] )
	assertEquals( hash, Bingo.messageQueue["Otherplayer-Other Realm"].queue[8] )
end
function test.test_bangCommand_list_tenCards()
	Bingo.CHAT_MSG_WHISPER( {}, "!cards 10", "Otherplayer-Other Realm" )
	Bingo.CHAT_MSG_WHISPER( {}, "!list", "Otherplayer-Other Realm" )
	local hash, card = next( Bingo_PlayerCards["Otherplayer-Other Realm"] )
	assertEquals( 71, #Bingo.messageQueue["Otherplayer-Other Realm"].queue )
end
function test.test_bangCommand_show_noCards()
	Bingo.CHAT_MSG_WHISPER( {}, "!show e40d7f00", "Otherplayer-Other Realm" )
	assertEquals( "You have no cards.", Bingo.messageQueue["Otherplayer-Other Realm"].queue[1] )
end
function test.test_bangCommand_show_oneCard()
	Bingo.CHAT_MSG_WHISPER( {}, "!cards 1", "Otherplayer-Other Realm" )
	local hash = next( Bingo_PlayerCards["Otherplayer-Other Realm"])
	Bingo.CHAT_MSG_WHISPER( {}, "!show "..hash, "Otherplayer-Other Realm" )
	-- 7th entry means that it was shown twice.
	assertEquals( " B  I  N  G  O  - "..hash, Bingo.messageQueue["Otherplayer-Other Realm"].queue[7] )
end
function test.test_bangCommand_show_oneCard_badHash()
	Bingo.CHAT_MSG_WHISPER( {}, "!cards 1", "Otherplayer-Other Realm" )
	local hash = next( Bingo_PlayerCards["Otherplayer-Other Realm"])
	Bingo.CHAT_MSG_WHISPER( {}, "!show e40d7f00", "Otherplayer-Other Realm" )
	assertEquals( "e40d7f00 is not one of your cards.", Bingo.messageQueue["Otherplayer-Other Realm"].queue[7] )
end
function test.test_bangCommand_show_tenCards()
	Bingo.CHAT_MSG_WHISPER( {}, "!cards 10", "Otherplayer-Other Realm" )
	local hash = next( Bingo_PlayerCards["Otherplayer-Other Realm"])
	Bingo.CHAT_MSG_WHISPER( {}, "!show "..hash, "Otherplayer-Other Realm" )
	-- 61st entry
	assertEquals( " B  I  N  G  O  - "..hash, Bingo.messageQueue["Otherplayer-Other Realm"].queue[61] )
end
function test.test_bangCommands_return_noCards()
	Bingo.CHAT_MSG_WHISPER( {}, "!return e40d7f00", "Otherplayer-Other Realm" )
	assertEquals( "You have no cards to return.", Bingo.messageQueue["Otherplayer-Other Realm"].queue[1] )
end
function test.test_bangCommands_return_oneCard()
	Bingo.CHAT_MSG_WHISPER( {}, "!cards 1", "Otherplayer-Other Realm" )
	local hash = next( Bingo_PlayerCards["Otherplayer-Other Realm"])
	Bingo.CHAT_MSG_WHISPER( {}, "!return "..hash, "Otherplayer-Other Realm" )
	assertEquals( hash.." has been returned.", Bingo.messageQueue["Otherplayer-Other Realm"].queue[7] )
	assertIsNil( Bingo_PlayerCards["Otherplayer-Other Realm"], "Player should not be listed if they have no cards left." )
end
function test.test_bangCommands_return_oneCard_badHash()
	Bingo.CHAT_MSG_WHISPER( {}, "!cards 1", "Otherplayer-Other Realm" )
	Bingo.CHAT_MSG_WHISPER( {}, "!return e40d7f00", "Otherplayer-Other Realm" )
	assertEquals( "e40d7f00 is not one of your cards.", Bingo.messageQueue["Otherplayer-Other Realm"].queue[7] )
end
function test.test_bangCommands_return_tenCards()
	Bingo.CHAT_MSG_WHISPER( {}, "!cards 10", "Otherplayer-Other Realm" )
	local hash = next( Bingo_PlayerCards["Otherplayer-Other Realm"])
	Bingo.CHAT_MSG_WHISPER( {}, "!return "..hash, "Otherplayer-Other Realm" )
	assertEquals( hash.." has been returned.", Bingo.messageQueue["Otherplayer-Other Realm"].queue[61] )
	assertTrue( Bingo_PlayerCards["Otherplayer-Other Realm"], "Player should still be listed." )
end
function test.test_bangCommands_return_all_tenCards()
	Bingo.CHAT_MSG_WHISPER( {}, "!cards 10", "Otherplayer-Other Realm" )
	Bingo.CHAT_MSG_WHISPER( {}, "!return all", "Otherplayer-Other Realm" )
	assertEquals( "All of your cards have been returned.", Bingo.messageQueue["Otherplayer-Other Realm"].queue[61] )
	assertIsNil( Bingo_PlayerCards["Otherplayer-Other Realm"], "Player should not be listed if they have no cards left." )
end
function test.test_windetect_row1()
	Bingo_PlayerCards["Frank-Win"] = {["e1211770"] = "14,10,5,1,9,23,19,30,29,17,43,40,0,31,37,49,59,46,57,58,67,73,72,68,66",}
	-- setup the game
	Bingo.Command( "say" )
	Bingo.initAt = time()-65
	Bingo_CurrentGame.startedAt = time()-5
	Bingo_CurrentGame.lastBallAt = time()
	Bingo_CurrentGame.picked = { [14] = true, [23] = true, [43] = true, [49] = true, [67] = true }
	Bingo.CHAT_MSG_( {}, "BINGO!", "Frank-Win" )
	assertEquals( "Frank-Win", Bingo_CurrentGame.winner )
	assertAlmostEquals( time(), Bingo_CurrentGame.endedAt )
	assertTrue( Bingo_CurrentGame.stopped )
end
function test.test_windetect_row2()
	Bingo_PlayerCards["Frank-Win"] = {["e1211770"] = "14,10,5,1,9,23,19,30,29,17,43,40,0,31,37,49,59,46,57,58,67,73,72,68,66",}
	-- setup the game
	Bingo.Command( "say" )
	Bingo.initAt = time()-65
	Bingo_CurrentGame.startedAt = time()-5
	Bingo_CurrentGame.lastBallAt = time()
	Bingo_CurrentGame.picked = { [10] = true, [19] = true, [40] = true, [59] = true, [73] = true }
	Bingo.CHAT_MSG_( {}, "BINGO!", "Frank-Win" )
	assertEquals( "Frank-Win", Bingo_CurrentGame.winner )
	assertAlmostEquals( time(), Bingo_CurrentGame.endedAt )
	assertTrue( Bingo_CurrentGame.stopped )
end
function test.test_windetect_row3() -- has free spot
	Bingo_PlayerCards["Frank-Win"] = {["e1211770"] = "14,10,5,1,9,23,19,30,29,17,43,40,0,31,37,49,59,46,57,58,67,73,72,68,66",}
	-- setup the game
	Bingo.Command( "say" )
	Bingo.initAt = time()-65
	Bingo_CurrentGame.startedAt = time()-5
	Bingo_CurrentGame.lastBallAt = time()
	Bingo_CurrentGame.picked = { [5] = true, [30] = true, [46] = true, [72] = true }
	Bingo.CHAT_MSG_( {}, "BINGO!", "Frank-Win" )
	assertEquals( "Frank-Win", Bingo_CurrentGame.winner )
	assertAlmostEquals( time(), Bingo_CurrentGame.endedAt )
	assertTrue( Bingo_CurrentGame.stopped )
end
function test.test_windetect_row4()
	Bingo_PlayerCards["Frank-Win"] = {["e1211770"] = "14,10,5,1,9,23,19,30,29,17,43,40,0,31,37,49,59,46,57,58,67,73,72,68,66",}
	-- setup the game
	Bingo.Command( "say" )
	Bingo.initAt = time()-65
	Bingo_CurrentGame.startedAt = time()-5
	Bingo_CurrentGame.lastBallAt = time()
	Bingo_CurrentGame.picked = { [1] = true, [29] = true, [31] = true, [57] = true, [68] = true }
	Bingo.CHAT_MSG_( {}, "BINGO!", "Frank-Win" )
	assertEquals( "Frank-Win", Bingo_CurrentGame.winner )
	assertAlmostEquals( time(), Bingo_CurrentGame.endedAt )
	assertTrue( Bingo_CurrentGame.stopped )
end
function test.test_windetect_row5_withExtras()
	Bingo_PlayerCards["Frank-Win"] = {["e1211770"] = "14,10,5,1,9,23,19,30,29,17,43,40,0,31,37,49,59,46,57,58,67,73,72,68,66",}
	-- setup the game
	Bingo.Command( "say" )
	Bingo.initAt = time()-65
	Bingo_CurrentGame.startedAt = time()-5
	Bingo_CurrentGame.lastBallAt = time()
	Bingo_CurrentGame.picked = { [1] = true, [5] = true, [9] = true, [17] = true, [37] = true, [58] = true, [66] = true }
	Bingo.CHAT_MSG_( {}, "BINGO!", "Frank-Win" )
	assertEquals( "Frank-Win", Bingo_CurrentGame.winner )
	assertAlmostEquals( time(), Bingo_CurrentGame.endedAt )
	assertTrue( Bingo_CurrentGame.stopped )
end
function test.test_windetect_col3_withExtras()
	Bingo_PlayerCards["Frank-Win"] = {["e1211770"] = "14,10,5,1,9,23,19,30,29,17,43,40,0,31,37,49,59,46,57,58,67,73,72,68,66",}
	-- setup the game
	Bingo.Command( "say" )
	Bingo.initAt = time()-65
	Bingo_CurrentGame.startedAt = time()-5
	Bingo_CurrentGame.lastBallAt = time()
	Bingo_CurrentGame.picked = { [1] = true, [5] = true, [9] = true, [30] = true, [17] = true, [37] = true, [46] = true, [72] = true }
	Bingo.CHAT_MSG_( {}, "BINGO!", "Frank-Win" )
	assertEquals( "Frank-Win", Bingo_CurrentGame.winner )
	assertAlmostEquals( time(), Bingo_CurrentGame.endedAt )
	assertTrue( Bingo_CurrentGame.stopped )
end
function test.test_windetect_diag1_withExtras()
	Bingo_PlayerCards["Frank-Win"] = {["e1211770"] = "14,10,5,1,9,23,19,30,29,17,43,40,0,31,37,49,59,46,57,58,67,73,72,68,66",}
	-- setup the game
	Bingo.Command( "say" )
	Bingo.initAt = time()-65
	Bingo_CurrentGame.startedAt = time()-5
	Bingo_CurrentGame.lastBallAt = time()
	Bingo_CurrentGame.picked = { [1] = true, [14] = true, [19] = true, [57] = true, [66] = true, }
	Bingo.CHAT_MSG_( {}, "BINGO!", "Frank-Win" )
	assertEquals( "Frank-Win", Bingo_CurrentGame.winner )
	assertAlmostEquals( time(), Bingo_CurrentGame.endedAt )
	assertTrue( Bingo_CurrentGame.stopped )
end
function test.test_windetect_playerHasNoCard()
	-- setup the game
	Bingo.Command( "say" )
	Bingo.initAt = time()-65
	Bingo_CurrentGame.startedAt = time()-5
	Bingo_CurrentGame.lastBallAt = time()
	Bingo_CurrentGame.picked = { [10] = true, [19] = true, [40] = true, [59] = true, [73] = true }
	Bingo.CHAT_MSG_( {}, "BINGO!", "Frank-NoCard" )
	assertIsNil( Bingo_CurrentGame.winner )  -- does not mark a winner
	assertIsNil( Bingo_CurrentGame.endedAt ) -- does not end the game
	assertIsNil( Bingo_CurrentGame.stopped ) -- does not stop the game
	assertEquals( "Frank-NoCard does not have a card!", Bingo.messageQueue["say"].queue[6] )
end
function test.test_resetGame()
	Bingo.Command( "say" )
	Bingo.initAt = time()-65
	Bingo_CurrentGame.startedAt = time()-5
	Bingo_CurrentGame.lastBallAt = time()
	Bingo_CurrentGame.picked = { [10] = true, [19] = true, [40] = true, [59] = true, [73] = true }
	Bingo.Command( "reset" )
	assertIsNil( Bingo_CurrentGame.ball )
	-- assertEquals( {}, Bingo_CurrentGame )
	-- assertTrue( Bingo_CurrentGame.stoppedAt )
end
function test.test_stopGame()
	Bingo.Command( "say" )
	Bingo.initAt = time()-65
	Bingo_CurrentGame.startedAt = time()-5
	Bingo_CurrentGame.lastBallAt = time()
	Bingo_CurrentGame.picked = { [10] = true, [19] = true, [40] = true, [59] = true, [73] = true }
	Bingo.Command( "stop" )
	assertIsNil( Bingo_CurrentGame.ball )
	-- assertEquals( {}, Bingo_CurrentGame )
	-- assertTrue( Bingo_CurrentGame.stoppedAt )
end
---------- Bugs
function test.test_b19_second_player_calling_bingo_should_not_also_win()
	Bingo_PlayerCards["Frank-Win"] = {["e1211770"] = "14,10,5,1,9,23,19,30,29,17,43,40,0,31,37,49,59,46,57,58,67,73,72,68,66",}
	Bingo_PlayerCards["Mark-Win"] = {["01234567"] = "14,10,5,1,9,23,19,30,29,17,43,40,0,31,37,49,59,46,57,58,67,73,72,68,66",}
	-- setup the game
	Bingo.Command( "say" )
	Bingo.initAt = time()-65
	Bingo_CurrentGame.startedAt = time()-5
	Bingo_CurrentGame.lastBallAt = time()
	Bingo_CurrentGame.picked = { [1] = true, [14] = true, [19] = true, [57] = true, [66] = true, }
	Bingo.CHAT_MSG_( {}, "BINGO!", "Frank-Win" )
	assertEquals( "Frank-Win", Bingo_CurrentGame.winner )
	assertAlmostEquals( time(), Bingo_CurrentGame.endedAt )
	assertTrue( Bingo_CurrentGame.stopped )
	Bingo.CHAT_MSG_( {}, "BINGO!", "Mark-Win" )
	assertEquals( "Frank-Win", Bingo_CurrentGame.winner ) -- Mark is not seen as winner now.
end

test.run()
