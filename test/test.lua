#!/usr/bin/env lua
require "wowTest"

test.outFileName = "testOut.xml"
test.coberturaFileName = "../coverage.xml"
test.coverageReportPercent = true

ParseTOC( "../src/Bingo.toc" )

function test.before()
	myParty = { ["group"] = nil, ["raid"] = nil, ["roster"] = {} }
	chatLog = {}
	Bingo_PlayerCards = {}
	Bingo_CurrentGame = {}
	Bingo_Options = { variant = "line" }
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
	assertEquals( "|cffff6d00Bingo> |rBingo (@VERSION@) by opussf", chatLog[1].msg )
end
function test.test_unknownFunction_ShowsHelp()
	Bingo.Command("meh")
	assertEquals( "|cffff6d00Bingo> |rBingo (@VERSION@) by opussf", chatLog[1].msg )
end

function test.test_start_NewGame_sets_channel()
	Bingo.Command("guild")
	assertEquals( "guild", Bingo_CurrentGame.channel )
end
function test.test_start_NewGame_sets_startedAt()
	Bingo.Command("guild")
	assertAlmostEquals(time(), Bingo_CurrentGame.initAt, nil, nil, 1)
end
function test.test_start_NewGame_sets_picked()
	Bingo.Command("guild")
	assertTrue( Bingo_CurrentGame.picked )
	assertIsNil( next( Bingo_CurrentGame.picked ) )
end
function test.test_gameSendsToRightChannel_guild()
	Bingo.Command( "guild" )
	Bingo.OnUpdate()
	assertEquals( "GUILD", chatLog[2].chatType )
end
function test.test_gameSendsToRightChannel_raid()
	myParty["raid"] = 1
	Bingo.Command( "raid" )
	Bingo.OnUpdate()
	assertEquals( "RAID", chatLog[2].chatType )
end
function test.test_gameSendsToRightChannel_party()
	myParty["party"] = 1
	Bingo.Command( "party" )
	Bingo.OnUpdate()
	assertEquals( "PARTY", chatLog[2].chatType )
end
function test.test_gameSendsToRightChannel_yell()
	Bingo.Command( "yell" )
	Bingo.OnUpdate()
	assertEquals( "YELL", chatLog[2].chatType )
end
function test.test_gameSendsToRightChannel_say()
	Bingo.Command( "say" )
	Bingo.OnUpdate()
	assertEquals( "SAY", chatLog[2].chatType )
end
function test.test_cardCommand_whisper()
	Bingo.CHAT_MSG_WHISPER( {}, "!cards 1", "Otherplayer-Other Realm" )
	Bingo.OnUpdate()
	assertEquals( "WHISPER", chatLog[2].chatType )
end
function test.test_cardCommand_hasCardAlready()
	Bingo_PlayerCards["Otherplayer-Other Realm"] = {["12345678"] = "1,2,3,4,5"}
	Bingo.CHAT_MSG_WHISPER( {}, "!cards 1", "Otherplayer-Other Realm" )
	assertEquals( "Your card list:", Bingo.messageQueue["Otherplayer-Other Realm"].queue[1] )
end
function test.test_cardCommand_noNumber()
	Bingo_PlayerCards["Otherplayer-Other Realm"] = {["12345678"] = "1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25"}
	Bingo.CHAT_MSG_WHISPER( {}, "!cards", "Otherplayer-Other Realm" )
	assertEquals( "These are your card ids:", Bingo.messageQueue["Otherplayer-Other Realm"].queue[1] )
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
function test.test_bangCommands_help_queue_has_8()
	Bingo.CHAT_MSG_WHISPER( {}, "!help", "Otherplayer-Other Realm" )
	assertEquals( 8, #Bingo.messageQueue["Otherplayer-Other Realm"].queue )
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
function test.test_windect_noBingo()
	Bingo_PlayerCards["Frank-Win"] = {["e1211770"] = "14,10,5,1,9,23,19,30,29,17,43,40,0,31,37,49,59,46,57,58,67,73,72,68,66",}
	-- setup the game
	Bingo.Command( "say" )
	Bingo.initAt = time()-65
	Bingo_CurrentGame.startedAt = time()-5
	Bingo_CurrentGame.lastBallAt = time()
	Bingo_CurrentGame.picked = { [1] = true, [14] = true, [19] = true, [57] = true }
	Bingo.CHAT_MSG_( {}, "BINGO!", "Frank-Win" )
	assertIsNil( Bingo_CurrentGame.winner )
	assertIsNil( Bingo_CurrentGame.endedAt )
	assertIsNil( Bingo_CurrentGame.stopped )
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
	assertEquals( "Frank-NoCard does not have a card!", Bingo.messageQueue["say"].queue[7] )
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
function test.test_game_GetsStarted()
	Bingo.Command( "say" )
	Bingo_CurrentGame.initAt = 100
	Bingo.OnUpdate()
	assertAlmostEquals( time(), Bingo_CurrentGame.startedAt )
	assertEquals( time(), Bingo_CurrentGame.lastBallAt )
end
function test.test_game_LastBallCalled()
	Bingo.Command( "say" )
	Bingo_CurrentGame.initAt = 100
	Bingo_CurrentGame.ball = {}
	Bingo.OnUpdate()
	assertAlmostEquals( time() + Bingo.gameEndDelaySeconds, Bingo_CurrentGame.endedAt )
end
function test.test_game_GetsStopped()
	Bingo.Command( "say" )
	Bingo_CurrentGame.startedAt = time() -60
	Bingo_CurrentGame.endedAt = time() - 10
	Bingo.OnUpdate()
	assertTrue( Bingo_CurrentGame.stopped )
end
-- Penality
function test.test_windect_noBingo_wPenality()
	Bingo_PlayerCards["Frank-Win"] = {["e1211770"] = "14,10,5,1,9,23,19,30,29,17,43,40,0,31,37,49,59,46,57,58,67,73,72,68,66",}
	-- setup the game
	Bingo.Command( "say" )
	Bingo.initAt = time()-65
	Bingo_CurrentGame.startedAt = time()-5
	Bingo_CurrentGame.lastBallAt = time()
	Bingo_CurrentGame.picked = { [1] = true, [14] = true, [19] = true, [57] = true }
	Bingo.CHAT_MSG_( {}, "BINGO!", "Frank-Win" )
	assertTrue( Bingo_CurrentGame.penalityBox, "PenaltyBox table should exist." )
	assertTrue( Bingo_CurrentGame.penalityBox["Frank-Win"], "Frank-Win has an entry." )
	assertAlmostEquals( time()+21, Bingo_CurrentGame.penalityBox["Frank-Win"], "Should have timeout value. ")
end
function test.test_windetect_Bingo_wCurrentPenality()
	-- Player has card
	Bingo_PlayerCards["Frank-Win"] = {["e1211770"] = "14,10,5,1,9,23,19,30,29,17,43,40,0,31,37,49,59,46,57,58,67,73,72,68,66",}
	-- game started
	Bingo.Command( "say" )
	Bingo.initAt = time()-65
	Bingo_CurrentGame.startedAt = time()-5
	Bingo_CurrentGame.lastBallAt = time()
	Bingo_CurrentGame.penalityBox = {["Frank-Win"] = time() + 5}
	-- player has current time penality
	Bingo_CurrentGame.picked = { [1] = true, [5] = true, [9] = true, [17] = true, [37] = true, [58] = true, [66] = true }
	-- picked balls allow Frank to win game
	Bingo.CHAT_MSG_( {}, "BINGO!", "Frank-Win" )
	-- Calls for winDetect.
	assertIsNil( Bingo_CurrentGame.winner, "No winner should be recorded." )
	assertIsNil( Bingo_CurrentGame.endedAt, "Game should not be marked as ended." )
	assertIsNil( Bingo_CurrentGame.stopped, "Game should not be stopped." )
end
function test.test_windetect_Bingo_wExpiredPenality()
	-- Player has card
	Bingo_PlayerCards["Frank-Win"] = {["e1211770"] = "14,10,5,1,9,23,19,30,29,17,43,40,0,31,37,49,59,46,57,58,67,73,72,68,66",}
	-- game started
	Bingo.Command( "say" )
	Bingo.initAt = time()-65
	Bingo_CurrentGame.startedAt = time()-5
	Bingo_CurrentGame.lastBallAt = time()
	Bingo_CurrentGame.penalityBox = {["Frank-Win"] = time()-25}
	-- player has current time penality
	Bingo_CurrentGame.picked = { [1] = true, [5] = true, [9] = true, [17] = true, [37] = true, [58] = true, [66] = true }
	-- picked balls allow Frank to win game
	Bingo.CHAT_MSG_( {}, "BINGO!", "Frank-Win" )
	-- Calls for winDetect.
	assertEquals( "Frank-Win", Bingo_CurrentGame.winner, "Frank should be marked as winner." )
	assertAlmostEquals( time(), Bingo_CurrentGame.endedAt, "Game should be marked as ended." )
	assertTrue( Bingo_CurrentGame.stopped, "Game should be marked as stopped." )
end
function test.test_windect_noBingo_wPenality_message()
	Bingo_PlayerCards["Frank-Win"] = {["e1211770"] = "14,10,5,1,9,23,19,30,29,17,43,40,0,31,37,49,59,46,57,58,67,73,72,68,66",}
	-- setup the game
	Bingo.Command( "say" )
	Bingo.initAt = time()-65
	Bingo_CurrentGame.startedAt = time()-5
	Bingo_CurrentGame.lastBallAt = time()
	Bingo_CurrentGame.picked = { [1] = true, [14] = true, [19] = true, [57] = true }
	Bingo.CHAT_MSG_( {}, "BINGO!", "Frank-Win" )
	assertEquals( "Frank-Win has incurred a 21 second calling penality.", Bingo.messageQueue.say.queue[8] )
end
-- Variations
function test.test_windetect_box()
	Bingo_PlayerCards["Frank-Win"] = {["e1211770"] = "14,10,5,1,9,23,19,30,29,17,43,40,0,31,37,49,59,46,57,58,67,73,72,68,66",}
	Bingo.Command( "box" )
	-- setup the game
	Bingo.Command( "say" )
	Bingo.initAt = time()-65
	Bingo_CurrentGame.startedAt = time()-5
	Bingo_CurrentGame.lastBallAt = time()
	Bingo_CurrentGame.picked = { [14] = true, [10] = true,  [5] = true,  [1] = true,  [9] = true, [23] = true, [17] = true, [43] = true,
			                     [37] = true, [49] = true, [58] = true, [67] = true, [73] = true, [72] = true, [68] = true, [66] = true }
	Bingo.CHAT_MSG_( {}, "BINGO!", "Frank-Win" )
	assertEquals( "Frank-Win", Bingo_CurrentGame.winner )
	assertAlmostEquals( time(), Bingo_CurrentGame.endedAt )
	assertTrue( Bingo_CurrentGame.stopped )
end
function test.test_windetect_box_fail()
	Bingo_PlayerCards["Frank-Win"] = {["e1211770"] = "14,10,5,1,9,23,19,30,29,17,43,40,0,31,37,49,59,46,57,58,67,73,72,68,66",}
	Bingo.Command( "box" )
	-- setup the game
	Bingo.Command( "say" )
	Bingo.initAt = time()-65
	Bingo_CurrentGame.startedAt = time()-5
	Bingo_CurrentGame.lastBallAt = time()
	Bingo_CurrentGame.picked = { [14] = true, [19] = true,  [5] = true,  [1] = true,  [9] = true, [23] = true, [17] = true, [43] = true,
			                     [37] = true, [49] = true, [58] = true, [67] = true, [73] = true, [72] = true, [68] = true, [66] = true }
	Bingo.CHAT_MSG_( {}, "BINGO!", "Frank-Win" )
	assertIsNil( Bingo_CurrentGame.winner )
	assertIsNil( Bingo_CurrentGame.endedAt )
	assertIsNil( Bingo_CurrentGame.stopped )
end
function test.test_windetect_corners()
	Bingo_PlayerCards["Frank-Win"] = {["e1211770"] = "14,10,5,1,9,23,19,30,29,17,43,40,0,31,37,49,59,46,57,58,67,73,72,68,66",}
	Bingo.Command( "corners" )
	-- setup the game
	Bingo.Command( "say" )
	Bingo.initAt = time()-65
	Bingo_CurrentGame.startedAt = time()-5
	Bingo_CurrentGame.lastBallAt = time()
	Bingo_CurrentGame.picked = { [14] = true, [9] = true, [67] = true, [66] = true }
	Bingo.CHAT_MSG_( {}, "BINGO!", "Frank-Win" )
	assertEquals( "Frank-Win", Bingo_CurrentGame.winner )
	assertAlmostEquals( time(), Bingo_CurrentGame.endedAt )
	assertTrue( Bingo_CurrentGame.stopped )
end
function test.test_windetect_corners_fail()
	Bingo_PlayerCards["Frank-Win"] = {["e1211770"] = "14,10,5,1,9,23,19,30,29,17,43,40,0,31,37,49,59,46,57,58,67,73,72,68,66",}
	Bingo.Command( "corners" )
	-- setup the game
	Bingo.Command( "say" )
	Bingo.initAt = time()-65
	Bingo_CurrentGame.startedAt = time()-5
	Bingo_CurrentGame.lastBallAt = time()
	Bingo_CurrentGame.picked = { [19] = true, [9] = true, [67] = true, [66] = true }
	Bingo.CHAT_MSG_( {}, "BINGO!", "Frank-Win" )
	assertIsNil( Bingo_CurrentGame.winner )
	assertIsNil( Bingo_CurrentGame.endedAt )
	assertIsNil( Bingo_CurrentGame.stopped )
end
function test.test_windetect_tee_top()
	Bingo_PlayerCards["Frank-Win"] = {["e1211770"] = "14,10,5,1,9,23,19,30,29,17,43,40,0,31,37,49,59,46,57,58,67,73,72,68,66",}
	Bingo.Command( "tee" )
	-- setup the game
	Bingo.Command( "say" )
	Bingo.initAt = time()-65
	Bingo_CurrentGame.startedAt = time()-5
	Bingo_CurrentGame.lastBallAt = time()
	Bingo_CurrentGame.picked = { [14] = true, [23] = true, [43] = true, [40] = true, [31] = true, [37] = true, [49] = true, [67] = true }
	Bingo.CHAT_MSG_( {}, "BINGO!", "Frank-Win" )
	assertEquals( "Frank-Win", Bingo_CurrentGame.winner )
	assertAlmostEquals( time(), Bingo_CurrentGame.endedAt )
	assertTrue( Bingo_CurrentGame.stopped )
end
function test.test_windetect_tee_top_fail()
	Bingo_PlayerCards["Frank-Win"] = {["e1211770"] = "14,10,5,1,9,23,19,30,29,17,43,40,0,31,37,49,59,46,57,58,67,73,72,68,66",}
	Bingo.Command( "tee" )
	-- setup the game
	Bingo.Command( "say" )
	Bingo.initAt = time()-65
	Bingo_CurrentGame.startedAt = time()-5
	Bingo_CurrentGame.lastBallAt = time()
	Bingo_CurrentGame.picked = { [14] = true, [23] = true, [43] = true, [40] = true, [31] = true, [17] = true, [49] = true, [67] = true }
	Bingo.CHAT_MSG_( {}, "BINGO!", "Frank-Win" )
	assertIsNil( Bingo_CurrentGame.winner )
	assertIsNil( Bingo_CurrentGame.endedAt )
	assertIsNil( Bingo_CurrentGame.stopped )
end
function test.test_windetect_tee_left()
	Bingo_PlayerCards["Frank-Win"] = {["e1211770"] = "14,10,5,1,9,23,19,30,29,17,43,40,0,31,37,49,59,46,57,58,67,73,72,68,66",}
	Bingo.Command( "tee" )
	-- setup the game
	Bingo.Command( "say" )
	Bingo.initAt = time()-65
	Bingo_CurrentGame.startedAt = time()-5
	Bingo_CurrentGame.lastBallAt = time()
	Bingo_CurrentGame.picked = { [14] = true, [10] = true, [5] = true, [1] = true, [9] = true, [30] = true, [46] = true, [72] = true }
	Bingo.CHAT_MSG_( {}, "BINGO!", "Frank-Win" )
	assertEquals( "Frank-Win", Bingo_CurrentGame.winner )
	assertAlmostEquals( time(), Bingo_CurrentGame.endedAt )
	assertTrue( Bingo_CurrentGame.stopped )
end
function test.test_windetect_tee_left_fail()
	Bingo_PlayerCards["Frank-Win"] = {["e1211770"] = "14,10,5,1,9,23,19,30,29,17,43,40,0,31,37,49,59,46,57,58,67,73,72,68,66",}
	Bingo.Command( "tee" )
	-- setup the game
	Bingo.Command( "say" )
	Bingo.initAt = time()-65
	Bingo_CurrentGame.startedAt = time()-5
	Bingo_CurrentGame.lastBallAt = time()
	Bingo_CurrentGame.picked = { [14] = true, [10] = true, [1] = true, [9] = true, [30] = true, [46] = true, [72] = true }
	Bingo.CHAT_MSG_( {}, "BINGO!", "Frank-Win" )
	assertIsNil( Bingo_CurrentGame.winner )
	assertIsNil( Bingo_CurrentGame.endedAt )
	assertIsNil( Bingo_CurrentGame.stopped )
end
function test.test_windetect_tee_bottom()
	Bingo_PlayerCards["Frank-Win"] = {["e1211770"] = "14,10,5,1,9,23,19,30,29,17,43,40,0,31,37,49,59,46,57,58,67,73,72,68,66",}
	Bingo.Command( "tee" )
	-- setup the game
	Bingo.Command( "say" )
	Bingo.initAt = time()-65
	Bingo_CurrentGame.startedAt = time()-5
	Bingo_CurrentGame.lastBallAt = time()
	Bingo_CurrentGame.picked = { [9] = true, [17] = true, [43] = true, [40] = true, [31] = true, [37] = true, [58] = true, [66] = true }
	Bingo.CHAT_MSG_( {}, "BINGO!", "Frank-Win" )
	assertEquals( "Frank-Win", Bingo_CurrentGame.winner )
	assertAlmostEquals( time(), Bingo_CurrentGame.endedAt )
	assertTrue( Bingo_CurrentGame.stopped )
end
function test.test_windetect_tee_bottom_fail()
	Bingo_PlayerCards["Frank-Win"] = {["e1211770"] = "14,10,5,1,9,23,19,30,29,17,43,40,0,31,37,49,59,46,57,58,67,73,72,68,66",}
	Bingo.Command( "tee" )
	-- setup the game
	Bingo.Command( "say" )
	Bingo.initAt = time()-65
	Bingo_CurrentGame.startedAt = time()-5
	Bingo_CurrentGame.lastBallAt = time()
	Bingo_CurrentGame.picked = { [9] = true, [17] = true, [43] = true, [40] = true, [31] = true, [36] = true, [58] = true, [66] = true }
	Bingo.CHAT_MSG_( {}, "BINGO!", "Frank-Win" )
	assertIsNil( Bingo_CurrentGame.winner )
	assertIsNil( Bingo_CurrentGame.endedAt )
	assertIsNil( Bingo_CurrentGame.stopped )
end
function test.test_windetect_tee_right()
	Bingo_PlayerCards["Frank-Win"] = {["e1211770"] = "14,10,5,1,9,23,19,30,29,17,43,40,0,31,37,49,59,46,57,58,67,73,72,68,66",}
	Bingo.Command( "tee" )
	-- setup the game
	Bingo.Command( "say" )
	Bingo.initAt = time()-65
	Bingo_CurrentGame.startedAt = time()-5
	Bingo_CurrentGame.lastBallAt = time()
	Bingo_CurrentGame.picked = { [5] = true, [30] = true, [46] = true, [67] = true, [73] = true, [72] = true, [68] = true, [66] = true }
	Bingo.CHAT_MSG_( {}, "BINGO!", "Frank-Win" )
	assertEquals( "Frank-Win", Bingo_CurrentGame.winner )
	assertAlmostEquals( time(), Bingo_CurrentGame.endedAt )
	assertTrue( Bingo_CurrentGame.stopped )
end
function test.test_windetect_tee_right_fail()
	Bingo_PlayerCards["Frank-Win"] = {["e1211770"] = "14,10,5,1,9,23,19,30,29,17,43,40,0,31,37,49,59,46,57,58,67,73,72,68,66",}
	Bingo.Command( "tee" )
	-- setup the game
	Bingo.Command( "say" )
	Bingo.initAt = time()-65
	Bingo_CurrentGame.startedAt = time()-5
	Bingo_CurrentGame.lastBallAt = time()
	Bingo_CurrentGame.picked = { [5] = true, [30] = true, [46] = true, [49] = true, [73] = true, [72] = true, [68] = true, [66] = true }
	Bingo.CHAT_MSG_( {}, "BINGO!", "Frank-Win" )
	assertIsNil( Bingo_CurrentGame.winner )
	assertIsNil( Bingo_CurrentGame.endedAt )
	assertIsNil( Bingo_CurrentGame.stopped )
end
function test.test_windetect_ex()
	Bingo_PlayerCards["Frank-Win"] = {["e1211770"] = "14,10,5,1,9,23,19,30,29,17,43,40,0,31,37,49,59,46,57,58,67,73,72,68,66",}
	Bingo.Command( "ex" )
	-- setup the game
	Bingo.Command( "say" )
	Bingo.initAt = time()-65
	Bingo_CurrentGame.startedAt = time()-5
	Bingo_CurrentGame.lastBallAt = time()
	Bingo_CurrentGame.picked = { [14] = true, [9] = true, [19] = true, [29] = true, [59] = true, [57] = true, [67] = true, [66] = true }
	Bingo.CHAT_MSG_( {}, "BINGO!", "Frank-Win" )
	assertEquals( "Frank-Win", Bingo_CurrentGame.winner )
	assertAlmostEquals( time(), Bingo_CurrentGame.endedAt )
	assertTrue( Bingo_CurrentGame.stopped )
end
function test.test_windetect_ex_fail()
	Bingo_PlayerCards["Frank-Win"] = {["e1211770"] = "14,10,5,1,9,23,19,30,29,17,43,40,0,31,37,49,59,46,57,58,67,73,72,68,66",}
	Bingo.Command( "ex" )
	-- setup the game
	Bingo.Command( "say" )
	Bingo.initAt = time()-65
	Bingo_CurrentGame.startedAt = time()-5
	Bingo_CurrentGame.lastBallAt = time()
	Bingo_CurrentGame.picked = { [14] = true, [9] = true, [19] = true, [29] = true, [58] = true, [57] = true, [67] = true, [66] = true }
	Bingo.CHAT_MSG_( {}, "BINGO!", "Frank-Win" )
	assertIsNil( Bingo_CurrentGame.winner )
	assertIsNil( Bingo_CurrentGame.endedAt )
	assertIsNil( Bingo_CurrentGame.stopped )
end
function test.test_windetect_plus()
	Bingo_PlayerCards["Frank-Win"] = {["e1211770"] = "14,10,5,1,9,23,19,30,29,17,43,40,0,31,37,49,59,46,57,58,67,73,72,68,66",}
	Bingo.Command( "plus" )
	-- setup the game
	Bingo.Command( "say" )
	Bingo.initAt = time()-65
	Bingo_CurrentGame.startedAt = time()-5
	Bingo_CurrentGame.lastBallAt = time()
	Bingo_CurrentGame.picked = { [5] = true, [30] = true, [43] = true, [40] = true, [31] = true, [37] = true, [46] = true, [72] = true }
	Bingo.CHAT_MSG_( {}, "BINGO!", "Frank-Win" )
	assertEquals( "Frank-Win", Bingo_CurrentGame.winner )
	assertAlmostEquals( time(), Bingo_CurrentGame.endedAt )
	assertTrue( Bingo_CurrentGame.stopped )
end
function test.test_windetect_plus_fail()
	Bingo_PlayerCards["Frank-Win"] = {["e1211770"] = "14,10,5,1,9,23,19,30,29,17,43,40,0,31,37,49,59,46,57,58,67,73,72,68,66",}
	Bingo.Command( "plus" )
	-- setup the game
	Bingo.Command( "say" )
	Bingo.initAt = time()-65
	Bingo_CurrentGame.startedAt = time()-5
	Bingo_CurrentGame.lastBallAt = time()
	Bingo_CurrentGame.picked = { [5] = true, [30] = true, [43] = true, [40] = true, [31] = true, [32] = true, [46] = true, [72] = true }
	Bingo.CHAT_MSG_( {}, "BINGO!", "Frank-Win" )
	assertIsNil( Bingo_CurrentGame.winner )
	assertIsNil( Bingo_CurrentGame.endedAt )
	assertIsNil( Bingo_CurrentGame.stopped )
end
function test.test_windetect_full()
	Bingo_PlayerCards["Frank-Win"] = {["e1211770"] = "14,10,5,1,9,23,19,30,29,17,43,40,0,31,37,49,59,46,57,58,67,73,72,68,66",}
	Bingo.Command( "full" )
	-- setup the game
	Bingo.Command( "say" )
	Bingo.initAt = time()-65
	Bingo_CurrentGame.startedAt = time()-5
	Bingo_CurrentGame.lastBallAt = time()
	Bingo_CurrentGame.picked = { [14] = true, [10] = true,  [5] = true,  [1] = true,  [9] = true,
								 [23] = true, [19] = true, [30] = true, [29] = true, [17] = true,
								 [43] = true, [40] = true,              [31] = true, [37] = true,
								 [49] = true, [59] = true, [46] = true, [57] = true, [58] = true,
								 [67] = true, [73] = true, [72] = true, [68] = true, [66] = true }
	Bingo.CHAT_MSG_( {}, "BINGO!", "Frank-Win" )
	assertEquals( "Frank-Win", Bingo_CurrentGame.winner )
	assertAlmostEquals( time(), Bingo_CurrentGame.endedAt )
	assertTrue( Bingo_CurrentGame.stopped )
end
function test.test_windetect_full_fail()
	Bingo_PlayerCards["Frank-Win"] = {["e1211770"] = "14,10,5,1,9,23,19,30,29,17,43,40,0,31,37,49,59,46,57,58,67,73,72,68,66",}
	Bingo.Command( "full" )
	-- setup the game
	Bingo.Command( "say" )
	Bingo.initAt = time()-65
	Bingo_CurrentGame.startedAt = time()-5
	Bingo_CurrentGame.lastBallAt = time()
	Bingo_CurrentGame.picked = { [14] = true, [10] = true,  [5] = true,  [1] = true,  [9] = true,
								 [23] = true, [19] = true, [30] = true, [29] = true, [17] = true,
								 [43] = true, [40] = true,              [31] = true, [37] = true,
								 [48] = true, [59] = true, [46] = true, [57] = true, [58] = true,
								 [67] = true, [73] = true, [72] = true, [68] = true, [66] = true }
	Bingo.CHAT_MSG_( {}, "BINGO!", "Frank-Win" )
	assertIsNil( Bingo_CurrentGame.winner )
	assertIsNil( Bingo_CurrentGame.endedAt )
	assertIsNil( Bingo_CurrentGame.stopped )
end
function test.test_variants_reset_to_line()
	-- set saved variant to box
	Bingo_Options.variant = "box"
	-- start game
	Bingo.Command( "say" )
	-- set variant
	Bingo.Command( "line" )
	-- stop and restart game
	Bingo.Command( "stop" )
	Bingo.Command( "say" )
	assertEquals( "line", Bingo_CurrentGame.variant, "Current game should be line variant")
end
function test.test_variants_setVariantDoesNotChangeCurrentGame()
	-- set saved variant to box
	Bingo_Options.variant = "box"
	-- start game
	Bingo.Command( "say" )
	Bingo.Command( "line" )
	Bingo.Command( "say" )
	assertEquals( "box", Bingo_CurrentGame.variant, "Current game should be box variant")
end
function test.test_new_create_playerCard_vertical()
	Bingo.CHAT_MSG_WHISPER( {}, "!new 14,10,5,1,9,23,19,30,29,17,43,40,0,31,37,49,59,46,57,58,67,73,72,68,66", "New-Card" )
	-- card is added, and sends message to player with id.
	assertEquals( "14,10,5,1,9,23,19,30,29,17,43,40,0,31,37,49,59,46,57,58,67,73,72,68,66", Bingo_PlayerCards["New-Card"]["e1211770"] )
	assertEquals( "e1211770 is your new card's id.", Bingo.messageQueue["New-Card"].queue[1] )
end
function test.test_new_create_playerCard_vertical_badCard_isMissingANumber()
	Bingo.CHAT_MSG_WHISPER( {}, "!new 14,10,5,9,23,19,30,29,17,43,40,0,31,37,49,59,46,57,58,67,73,72,68,66", "New-Card" )
	-- card is not added, and sends error message to player.
	assertIsNil( Bingo_PlayerCards["New-Card"] )
	assertEquals( "There was something wrong with the card you gave. Please resubmit.", Bingo.messageQueue["New-Card"].queue[1] )
end
function test.test_new_create_playerCard_vertical_badCard_extraB_notEnoughI()
	Bingo.CHAT_MSG_WHISPER( {}, "!new 14,10,5,1,9,11,12,30,29,17,43,40,0,31,37,49,59,46,57,58,67,73,72,68,66", "New-Card" )
	assertIsNil( Bingo_PlayerCards["New-Card"] )
	assertEquals( "There was something wrong with the card you gave. Please resubmit.", Bingo.messageQueue["New-Card"].queue[1] )
end
function test.test_new_create_playerCard_vertical_badCard_allSame()
	Bingo.CHAT_MSG_WHISPER( {}, "!new 1,1,1,1,1,16,16,16,16,16,31,31,31,31,31,46,46,46,46,46,61,61,61,61,61", "New-Card" )
	assertIsNil( Bingo_PlayerCards["New-Card"] )
	assertEquals( "There was something wrong with the card you gave. Please resubmit.", Bingo.messageQueue["New-Card"].queue[1] )
end
function test.test_new_create_playerCard_horizontal()
	Bingo.CHAT_MSG_WHISPER( {}, "!new 14,23,43,49,67,10,19,40,59,73,5,30,0,46,72,1,29,31,57,68,9,17,37,58,66", "New-Card" )
	assertEquals( "14,10,5,1,9,23,19,30,29,17,43,40,0,31,37,49,59,46,57,58,67,73,72,68,66", Bingo_PlayerCards["New-Card"]["e1211770"] )
	assertEquals( "e1211770 is your new card's id.", Bingo.messageQueue["New-Card"].queue[1] )
end
function test.test_new_create_playerCard_cardIsUsedByOtherPlayer()
	Bingo_PlayerCards["Frank-Win"] = {["e1211770"] = "14,10,5,1,9,23,19,30,29,17,43,40,0,31,37,49,59,46,57,58,67,73,72,68,66",}
	Bingo.CHAT_MSG_WHISPER( {}, "!new 14,23,43,49,67,10,19,40,59,73,5,30,0,46,72,1,29,31,57,68,9,17,37,58,66", "New-Card" )
	assertIsNil( Bingo_PlayerCards["New-Card"] )
	assertEquals( "Someone else has that card.", Bingo.messageQueue["New-Card"].queue[1] )
end
function test.test_new_create_playerCard_cardIsDuplicate()
	Bingo_PlayerCards["New-Card"] = {["e1211770"] = "14,10,5,1,9,23,19,30,29,17,43,40,0,31,37,49,59,46,57,58,67,73,72,68,66",}
	Bingo.CHAT_MSG_WHISPER( {}, "!new 14,23,43,49,67,10,19,40,59,73,5,30,0,46,72,1,29,31,57,68,9,17,37,58,66", "New-Card" )
	-- card is still there, and user knows it.
	assertEquals( "14,10,5,1,9,23,19,30,29,17,43,40,0,31,37,49,59,46,57,58,67,73,72,68,66", Bingo_PlayerCards["New-Card"]["e1211770"] )
	assertEquals( "e1211770 is already your card.", Bingo.messageQueue["New-Card"].queue[1] )
end

--------- Corner cases
function test.test_gameStructureIsRemade()
	Bingo_CurrentGame = nil
	Bingo.OnUpdate()
	assertTrue( Bingo_CurrentGame )
end

--------- Bugs
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
function test.test_b31_all_balls_spent_bingo_does_not_work()
	Bingo_PlayerCards["Frank-Win"] = {["e1211770"] = "14,10,5,1,9,23,19,30,29,17,43,40,0,31,37,49,59,46,57,58,67,73,72,68,66",}
	Bingo.Command( "say" )
	Bingo.initAt = time()-125
	Bingo_CurrentGame.startedAt = time()-65
	Bingo_CurrentGame.lastBallAt = time()-8
	Bingo_CurrentGame.ball = { 75 }
	Bingo_CurrentGame.picked = { true, true, true, true, true, true, true, true, true, true, true, true, true, true, true,
								 true, true, true, true, true, true, true, true, true, true, true, true, true, true, true,
								 true, true, true, true, true, true, true, true, true, true, true, true, true, true, true,
								 true, true, true, true, true, true, true, true, true, true, true, true, true, true, true,
								 true, true, true, true, true, true, true, true, true, true, true, true, true, true }
	Bingo.OnUpdate()
	Bingo.CHAT_MSG_( {}, "BINGO!", "Frank-Win" )
	assertEquals( "Frank-Win", Bingo_CurrentGame.winner )
	assertAlmostEquals( time(), Bingo_CurrentGame.endedAt, nil, nil, 1 )
	assertTrue( Bingo_CurrentGame.stopped )
end
function test.test_stopped_game_is_stopped()
	Bingo_PlayerCards["Frank-Win"] = {["e1211770"] = "14,10,5,1,9,23,19,30,29,17,43,40,0,31,37,49,59,46,57,58,67,73,72,68,66",}
	Bingo.Command( "say" )
	Bingo.initAt = time()-125
	Bingo_CurrentGame.startedAt = time()-65
	Bingo_CurrentGame.lastBallAt = time()-8
	Bingo_CurrentGame.ball = { 75 }
	Bingo_CurrentGame.picked = { true, true, true, true, true, true, true, true, true, true, true, true, true, true, true,
								 true, true, true, true, true, true, true, true, true, true, true, true, true, true, true,
								 true, true, true, true, true, true, true, true, true, true, true, true, true, true, true,
								 true, true, true, true, true, true, true, true, true, true, true, true, true, true, true,
								 true, true, true, true, true, true, true, true, true, true, true, true, true, true }
	Bingo.OnUpdate()
	Bingo_CurrentGame.endedAt = time()-31
	Bingo_CurrentGame.stopped = true
	Bingo.CHAT_MSG_( {}, "BINGO!", "Frank-Win" )
	assertIsNil( Bingo_CurrentGame.winner )
end

test.run()
