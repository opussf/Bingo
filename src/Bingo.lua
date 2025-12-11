BINGO_SLUG, Bingo   = ...
Bingo.MSG_ADDONNAME = C_AddOns.GetAddOnMetadata( BINGO_SLUG, "Title" )
Bingo.MSG_VERSION   = C_AddOns.GetAddOnMetadata( BINGO_SLUG, "Version" )
Bingo.MSG_AUTHOR    = C_AddOns.GetAddOnMetadata( BINGO_SLUG, "Author" )

Bingo.COLOR = {
	ORANGE = "|cffff6d00",
	END = "|r",
}

-- Init saved variables
Bingo_PlayerCards = {}
Bingo_CurrentGame = {}
Bingo.letters = {
	[0] = "B",
	[1] = "I",
	[2] = "N",
	[3] = "G",
	[4] = "O",
}
Bingo.startMessages = {

}
Bingo.playerStates = {
	[1] = function(player)
			SendChatMessage("Please ask for cards by whispering me with >!cards #<")
			Bingo_CurrentGame.players[player]=2
		end,
	[2] = nil,
}
function Bingo.Print( msg, showName )
	-- print to the chat frame
	if (showName == nil) or (showName) then
		msg = Bingo.COLOR.ORANGE..Bingo.MSG_ADDONNAME.."> "..Bingo.COLOR.END..msg
	end
	DEFAULT_CHAT_FRAME:AddMessage( msg )
end
function Bingo.SendMessage( msg )
	if type( msg ) == "string" then
		SendChatMessage(msg, "EMOTE")
	elseif type( msg ) == "table" then
	end
end

-- function Steps.SendMessages()
--     if not C_ChatInfo.IsAddonMessagePrefixRegistered(Steps.commPrefix) then
--         C_ChatInfo.RegisterAddonMessagePrefix(Steps.commPrefix)
--     end

--     Steps.addonMsg = Steps.BuildAddonMessage2()
--     if IsInGuild() then
--         C_ChatInfo.SendAddonMessage( Steps.commPrefix, Steps.addonMsg, "GUILD" )
--     end
--     if IsInGroup(LE_PARTY_CATEGORY_HOME) then
--         C_ChatInfo.SendAddonMessage( Steps.commPrefix, Steps.addonMsg, "PARTY" )
--     end
--     if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
--         C_ChatInfo.SendAddonMessage( Steps.commPrefix, Steps.addonMsg, "INSTANCE_CHAT" )
--     end
--     Steps.totalC = math.floor( Steps.mine.steps / 100 )
-- end
function Bingo.OnLoad()
	SLASH_BINGO1 = "/BINGO"
	SlashCmdList["BINGO"] = Bingo.Command
	BingoFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
end
function Bingo.PLAYER_ENTERING_WORLD()
	Bingo.RegisterEvents()
end
function Bingo.OnUpdate( elapsed )
	if Bingo_CurrentGame and Bingo_CurrentGame.initAt and not Bingo_CurrentGame.endedAt then
		Bingo.Print("Game exists, and not ended")
		if Bingo_CurrentGame.players then
			Bingo.Print("player table exists")
			for player, state in pairs( Bingo_CurrentGame.players ) do
				Bingo.Print(player.." is at state "..state)
				if Bingo.playerStates[state] then
					Bingo.Print(state.." exists, calling the function.")
					Bingo.playerStates[state](player)
				end
			end
		end
	end
end
function Bingo.StartGame( chatToUse )
	if Bingo_CurrentGame.initAt == nil or Bingo_CurrentGame.endedAt then
		Bingo_CurrentGame = {}
		Bingo_CurrentGame.channel = chatToUse
		Bingo_CurrentGame.initAt = time()
		-- Init players
		Bingo_CurrentGame.players = {}
		-- Init the ball
		Bingo_CurrentGame.ball = {}
		for val = 1,75 do
			table.insert(Bingo_CurrentGame.ball, val)
		end
		-- Clear Picked
		Bingo_CurrentGame.picked = {}
		Bingo.RegisterEvents()
		Bingo.Print("Game started for "..chatToUse)

	else
		Bingo.Print( "A game is already in progress." )
	end
end
function Bingo.RegisterEvents()
	if Bingo_CurrentGame.channel == "guild" then
		BingoFrame:RegisterEvent( "CHAT_MSG_GUILD" )
	elseif Bingo_CurrentGame.channel == "raid" then
		BingoFrame:UnregisterEvent( "CHAT_MSG_PARTY" )
		BingoFrame:UnregisterEvent( "CHAT_MSG_PARTY_LEADER" )
		BingoFrame:UnregisterEvent( "CHAT_MSG_RAID" )
		BingoFrame:UnregisterEvent( "CHAT_MSG_RAID_LEADER" )
		BingoFrame:UnregisterEvent( "CHAT_MSG_RAID_WARNING" )
	elseif Bingo_CurrentGame.channel == "party" then
		BingoFrame:UnregisterEvent( "CHAT_MSG_PARTY" )
		BingoFrame:UnregisterEvent( "CHAT_MSG_PARTY_LEADER" )
	end
	BingoFrame:RegisterEvent( "CHAT_MSG_WHISPER" )
end
function Bingo.CHAT_MSG_WHISPER( self, msg, sender )
	Bingo.Print( "CHAT_MSG_WHISPER( "..msg..", "..sender.." )" )
end
function Bingo.CHAT_MSG_( self, msg, sender )
	Bingo.Print("CHAT_MSG_( "..msg..", "..sender.." )" )
	if string.find( msg, "!join" ) then
		if not Bingo_CurrentGame.players[sender] then
			Bingo_CurrentGame.players[sender] = 1
		end
	end

end
Bingo.CHAT_MSG_GUILD = Bingo.CHAT_MSG_
Bingo.Chat_MSG_PARTY = Bingo.CHAT_MSG_
Bingo.Chat_MSG_PARTY_LEADER = Bingo.CHAT_MSG_
Bingo.Chat_MSG_RAID = Bingo.CHAT_MSG_
Bingo.Chat_MSG_RAID_LEADER = Bingo.CHAT_MSG_
Bingo.Chat_MSG_RAID_WARNING = Bingo.CHAT_MSG_
function Bingo.ResetGame()
	Bingo_CurrentGame = {}
	Bingo.Print("Game has been reset")
end
function Bingo.PrintHelp()
	Bingo.Print(Bingo.MSG_ADDONNAME.." ("..Bingo.MSG_VERSION..") by "..Bingo.MSG_AUTHOR)
	for cmd, info in pairs(Bingo.commandList) do
		if info.help then
			local cmdStr = cmd
			for c2, i2 in pairs(Bingo.commandList) do
				if i2.alias and i2.alias == cmd then
					cmdStr = string.format( "%s / %s", cmdStr, c2 )
				end
			end
			Bingo.Print( string.format( "%s %s %s -> %s",
					SLASH_BINGO1, cmdStr, info.help[1], info.help[2] ) )
		end
	end
end
function Bingo.ParseCmd( msg )
	if msg then
		msg = string.lower( msg )
		local a,b,c = strfind( msg, "(%S+)" )  --contiguous string of non-space characters
		if a then
			-- c is the matched string, strsub is everything after that, skipping the space
			return c, strsub(msg, b+2)
		else
			return ""
		end
	end
end
function Bingo.Command( msg )
	local cmd, param = Bingo.ParseCmd( msg );
	if Bingo.commandList[cmd] and Bingo.commandList[cmd].alias then
		cmd = Bingo.commandList[cmd].alias
	end
	local cmdFunc = Bingo.commandList[cmd];
	if cmdFunc then
		cmdFunc.func(param);
	else
		Bingo.PrintHelp()
	end
end
Bingo.commandList = {
	["help"] = {
		["func"] = Bingo.PrintHelp,
		["help"] = {"", "Print this help."},
	},
	["guild"] = {
		["func"] = function() Bingo.StartGame("guild") end,
		["help"] = {"", "Start game in guild chat"},
	},
	["raid"] = {
		["func"] = function() Bingo.StartGame("raid") end,
		["help"] = {"", "Start game in raid chat"},
	},
	["party"] = {
		["func"] = function() Bingo.StartGame("party") end,
		["help"] = {"", "Start game in party chat"},
	},
	["reset"] = {
		["func"] = Bingo.ResetGame,
		["help"] = {"", "Reset the system."},
	},
}