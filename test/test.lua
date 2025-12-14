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
function test.test_bangCommands_help_queue_has_6()
	Bingo.CHAT_MSG_WHISPER( {}, "!help", "Otherplayer-Other Realm" )
	assertEquals( 6, #Bingo.messageQueue["Otherplayer-Other Realm"].queue )
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
	hash, card = next( Bingo_PlayerCards["Otherplayer-Other Realm"] )
	assertEquals( 8, string.len(hash) )
	assertTrue( type(card) == "string" )
end
function test.test_bangCommands_cards_overMax()
	Bingo.CHAT_MSG_WHISPER( {}, "!cards 100", "Otherplayer-Other Realm" )
	assertTrue( Bingo_PlayerCards["Otherplayer-Other Realm"] )
	hash, card = next( Bingo_PlayerCards["Otherplayer-Other Realm"] )
	assertEquals( 8, string.len(hash) )
	assertTrue( type(card) == "string" )
end
function test.test_bangCommand_list_noCards()
	Bingo.CHAT_MSG_WHISPER( {}, "!list", "Otherplayer-Other Realm" )
	assertEquals( "You have no cards to list.", Bingo.messageQueue["Otherplayer-Other Realm"].queue[1] )
end
function test.test_bangCommand_list_oneCard()
	Bingo.CHAT_MSG_WHISPER( {}, "!cards 1", "Otherplayer-Other Realm" )
	Bingo.CHAT_MSG_WHISPER( {}, "!list", "Otherplayer-Other Realm" )
	hash, card = next( Bingo_PlayerCards["Otherplayer-Other Realm"] )
	assertEquals( hash, Bingo.messageQueue["Otherplayer-Other Realm"].queue[7] )
end
function test.test_bangCommand_list_tenCards()
	Bingo.CHAT_MSG_WHISPER( {}, "!cards 10", "Otherplayer-Other Realm" )
	Bingo.CHAT_MSG_WHISPER( {}, "!list", "Otherplayer-Other Realm" )
	hash, card = next( Bingo_PlayerCards["Otherplayer-Other Realm"] )
	assertEquals( 70, #Bingo.messageQueue["Otherplayer-Other Realm"].queue )
end
function test.test_bangCommand_show_noCards()
	Bingo.CHAT_MSG_WHISPER( {}, "!show e40d7f00", "Otherplayer-Other Realm" )
	assertEquals( "You have no cards.", Bingo.messageQueue["Otherplayer-Other Realm"].queue[1] )
end
function test.test_bangCommand_show_oneCard()
	Bingo.CHAT_MSG_WHISPER( {}, "!cards 1", "Otherplayer-Other Realm" )
	hash = next( Bingo_PlayerCards["Otherplayer-Other Realm"])
	Bingo.CHAT_MSG_WHISPER( {}, "!show "..hash, "Otherplayer-Other Realm" )
	-- 7th entry means that it was shown twice.
	assertEquals( " B  I  N  G  O  - "..hash, Bingo.messageQueue["Otherplayer-Other Realm"].queue[7] )
end
function test.test_bangCommand_show_oneCard_badHash()
	Bingo.CHAT_MSG_WHISPER( {}, "!cards 1", "Otherplayer-Other Realm" )
	hash = next( Bingo_PlayerCards["Otherplayer-Other Realm"])
	Bingo.CHAT_MSG_WHISPER( {}, "!show e40d7f00", "Otherplayer-Other Realm" )
	assertEquals( "e40d7f00 is not one of your cards.", Bingo.messageQueue["Otherplayer-Other Realm"].queue[7] )
end
function test.test_bangCommand_show_tenCards()
	Bingo.CHAT_MSG_WHISPER( {}, "!cards 10", "Otherplayer-Other Realm" )
	hash = next( Bingo_PlayerCards["Otherplayer-Other Realm"])
	Bingo.CHAT_MSG_WHISPER( {}, "!show "..hash, "Otherplayer-Other Realm" )
	test.dump(chatLog)
	test.dump(Bingo.messageQueue)
	-- 61st entry
	assertEquals( " B  I  N  G  O  - "..hash, Bingo.messageQueue["Otherplayer-Other Realm"].queue[61] )
end


test.run()


--[[



Bingo_CurrentGame.picked = {
	["B1"] = true

}

Bingo_CurrentGame.player = {
	["player"] =
}

Send alert to start a game.


"LETS PLAY BINGO!"
"Please /whisper me if you want instuctions."




function StripDice.GROUP_ROSTER_UPDATE()
	local NumGroupMembers = GetNumGroupMembers()
	if( NumGroupMembers == 0 ) then  -- turn off listening
		if( StripDice.gameActive ) then
			StripDice.LogMsg( "Deactivating Dice game.", 4 )
		end
		StripDiceFrame:UnregisterEvent( "CHAT_MSG_SYSTEM" )
		StripDiceFrame:UnregisterEvent( "CHAT_MSG_SAY" )
		StripDiceFrame:UnregisterEvent( "CHAT_MSG_PARTY" )
		StripDiceFrame:UnregisterEvent( "CHAT_MSG_PARTY_LEADER" )
		StripDiceFrame:UnregisterEvent( "CHAT_MSG_RAID" )
		StripDiceFrame:UnregisterEvent( "CHAT_MSG_RAID_LEADER" )
		StripDiceFrame:UnregisterEvent( "CHAT_MSG_RAID_WARNING" )
		StripDiceFrame:UnregisterEvent( "CHAT_MSG_INSTANCE_CHAT" )
		StripDiceFrame:UnregisterEvent( "CHAT_MSG_INSTANCE_CHAT_LEADER" )
		StripDiceFrame:UnregisterEvent( "CHAT_MSG_YELL" )
		StripDice.StopGame()
		StripDice.gameActive = nil
	elseif( NumGroupMembers > 0 and not StripDice.gameActive ) then
		StripDice.LogMsg( "Dice game is active with "..NumGroupMembers.." in the group.", 4 )
		StripDiceFrame:RegisterEvent( "CHAT_MSG_SYSTEM" )
		StripDiceFrame:RegisterEvent( "CHAT_MSG_SAY" )
		StripDiceFrame:RegisterEvent( "CHAT_MSG_PARTY" )
		StripDiceFrame:RegisterEvent( "CHAT_MSG_PARTY_LEADER" )
		StripDiceFrame:RegisterEvent( "CHAT_MSG_RAID" )
		StripDiceFrame:RegisterEvent( "CHAT_MSG_RAID_LEADER" )
		StripDiceFrame:RegisterEvent( "CHAT_MSG_RAID_WARNING" )
		StripDiceFrame:RegisterEvent( "CHAT_MSG_INSTANCE_CHAT" )
		StripDiceFrame:RegisterEvent( "CHAT_MSG_INSTANCE_CHAT_LEADER" )
		StripDiceFrame:RegisterEvent( "CHAT_MSG_YELL" )
		StripDice.gameActive = true
	end
end


]]