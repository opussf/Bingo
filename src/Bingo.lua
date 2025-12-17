BINGO_SLUG, Bingo   = ...
Bingo.MSG_ADDONNAME = C_AddOns.GetAddOnMetadata( BINGO_SLUG, "Title" )
Bingo.MSG_VERSION   = C_AddOns.GetAddOnMetadata( BINGO_SLUG, "Version" )
Bingo.MSG_AUTHOR    = C_AddOns.GetAddOnMetadata( BINGO_SLUG, "Author" )

Bingo.COLOR = {
	ORANGE = "|cffff6d00",
	END = "|r",
}

Bingo.cardLimit = 10  -- make this a configure option soonish
Bingo.ballDelaySeconds = 7
Bingo.gameEndDelaySeconds = 30

-- Init saved variables
Bingo_PlayerCards = {}  -- { ["player"] = {["hash"] = {{2d array of card}} } }
Bingo_CurrentGame = {}
Bingo.messageQueue = {}
Bingo.letters = {
	[0] = "B",   --  1-15
	[1] = "I",   -- 16-30
	[2] = "N",   -- 31-45
	[3] = "G",   -- 46-60
	[4] = "O",   -- 61-75
}
Bingo.startMessages = {
	"Lets play BINGO!",
	"If you don't have cards, please whisper me for cards with >!cards #<",
	"If you have cards, you can play with those cards by doing nothing.",
	"Whisper !help to me for more commands. The game will start in 1 minute.",
	"Say BINGO! in this channel when you get a BINGO!"
}
Bingo.helpMessages = {
	"Whisper these commands directly to me, with the line starting with ! (and no space)",
	"! cards # - generate and play with at least # cards.",
	"! cards 0 - will return all of your cards.",
	"! list - list the card hashes",
	"! show <hash> - shows card that match the hash.",
	"! return <hash>||all - return card that matches the hash.",
	"! tips - to show some helpful tips on playing."
}
Bingo.tipMessages = {
	"Tips for playing:",
	"Use two 3x5 index cards. one to create a reference card (with numbers),",
	"and a 2nd index card with dots in a grid. Mark the dots during a game.",
	"Add the 8 character card ID and your character name to the reference card for later.",
}
function Bingo.Print( msg, showName )
	-- print to the chat frame
	if (showName == nil) or (showName) then
		msg = Bingo.COLOR.ORANGE..Bingo.MSG_ADDONNAME.."> "..Bingo.COLOR.END..msg
	end
	DEFAULT_CHAT_FRAME:AddMessage( msg )
end
function Bingo.QueueMessage( msg, target )
	-- send msg to target
	-- msg can be a string, or a table of strings
	if not target or target == "" then
		target = Bingo_CurrentGame.channel or "pick a default"
	end
	Bingo.messageQueue[target] = Bingo.messageQueue[target] or { queue = {}, last = time()-1 }

	if type( msg ) == "string" then
		table.insert( Bingo.messageQueue[target].queue, msg )
	elseif type( msg ) == "table" then
		for _, s in pairs( msg ) do
			table.insert( Bingo.messageQueue[target].queue, tostring( s ) )
		end
	end
end
function Bingo.SendMessage( msg, target )
	-- guild, raid, party, general
	if not target or target == "" then
		target = Bingo_CurrentGame.channel or "pick a default"
	end
	local chatChannel, toWhom
	if target then
		if target == "guild" and IsInGuild() then
			chatChannel = "GUILD"
		elseif target == "raid" and IsInRaid() then
			chatChannel = "RAID"
		elseif target == "party" and IsInGroup( LE_PARTY_CATEGORY_HOME ) then
			chatChannel = "PARTY"
		elseif target == "say" then
			chatChannel = "SAY"
		elseif target == "yell" then
			chatChannel = "YELL"
		elseif target ~= "" then
			chatChannel = "WHISPER"
			toWhom = target
		end

		if( chatChannel ) then
			SendChatMessage( msg, chatChannel, nil, toWhom ) -- toWhom will be nil for most
		end
	end
end
function Bingo.spairs( t )
	local keys={}
	for k in pairs(t) do keys[#keys+1] = k end
	table.sort( keys )
	local i = 0
	return function()
		i = i + 1
		if keys[i] then
			return keys[i], t[keys[i]]
		end
	end
end
function Bingo.OnLoad()
	SLASH_BINGO1 = "/BINGO"
	SlashCmdList["BINGO"] = Bingo.Command
	BingoFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
end
function Bingo.PLAYER_ENTERING_WORLD()
	Bingo.RegisterEvents()
	-- math.randomseed(time())
end
function Bingo.OnUpdate( elapsed )
	-- handle message Queue
	for target, q in pairs( Bingo.messageQueue ) do
		if time()>q.last then
			msg = table.remove( q.queue, 1 )
			q.last = time()
			Bingo.SendMessage( msg, target )
		end
		if #q.queue == 0 then
			Bingo.messageQueue[target] = nil
		end
	end
	-- handle game loop
	if not Bingo_CurrentGame then  -- there should always be a currentGame table
		Bingo_CurrentGame = {}
	end
	-- start a game that has been initalized
	if not Bingo_CurrentGame.startedAt and Bingo_CurrentGame.initAt and Bingo_CurrentGame.initAt+60 < time() then
		Bingo_CurrentGame.startedAt = time()
		Bingo_CurrentGame.lastBallAt = Bingo_CurrentGame.initAt -- set this in the past
	end
	if Bingo_CurrentGame.startedAt and not Bingo_CurrentGame.endedAt then
		if Bingo_CurrentGame.lastBallAt and Bingo_CurrentGame.lastBallAt + Bingo.ballDelaySeconds <= time() then
			Bingo.CallBall()
			if #Bingo_CurrentGame.ball == 0 then
				Bingo_CurrentGame.endedAt = time() + Bingo.gameEndDelaySeconds
				Bingo.QueueMessage( "That was the last ball. You have "..Bingo.gameEndDelaySeconds.." seconds till end of game." )
			end
		end
	end
	if not Bingo_CurrentGame.stopped and Bingo_CurrentGame.endedAt and Bingo_CurrentGame.endedAt < time() then
		Bingo.QueueMessage( "The game has ended." )
		Bingo_CurrentGame.stopped = true
		Bingo.UnregisterEvents()
	end
end
function Bingo.StartGame( chatToUse )
	-- validate chatToUse
	if Bingo_CurrentGame.initAt == nil or Bingo_CurrentGame.endedAt then
		Bingo_CurrentGame = {}
		Bingo_CurrentGame.channel = chatToUse
		Bingo_CurrentGame.initAt = time()
		-- Init the ball
		Bingo_CurrentGame.ball = {}
		for val = 1,75 do
			table.insert(Bingo_CurrentGame.ball, val)
		end
		-- Clear Picked
		Bingo_CurrentGame.picked = {}
		Bingo.RegisterEvents()
		Bingo.Print("Game started for "..chatToUse)
		Bingo.QueueMessage( Bingo.startMessages, chatToUse )

	else
		Bingo.Print( "A game is already in progress." )
	end
end
function Bingo.CallBall()
	if #Bingo_CurrentGame.ball > 0 then
		local ball = table.remove( Bingo_CurrentGame.ball, random( 1, #Bingo_CurrentGame.ball ) )
		local colLetter = Bingo.letters[ math.floor( (ball-1)/15 ) ]
		Bingo_CurrentGame.picked[ ball ] = true
		Bingo_CurrentGame.lastBallAt = time()
		Bingo.QueueMessage( colLetter.."-"..ball, Bingo_CurrentGame.channel )
	end
end
-------------
function Bingo.CardStrToArray( cardStr )
	-- convert the CardStr to a table
	local t = {}
	for val in string.gmatch( cardStr, "([^,]+)") do
		table.insert( t, val )
	end
	return t
end
function Bingo.FNV1a(str)
    local hash = 2166136261
    for i = 1, #str do
        hash = bit.bxor(hash, str:byte(i))
        hash = (hash * 16777619) % 2^32
    end
    return string.format("%08x", hash)
end
function Bingo.MakeCard()
	-- returns hash, and 2d array x,y
	-- also searches PlayerCards to assure unique card.
	-- 552,446,474,061,128,648,601,600,000 unique cards.
	-- 5.52 x 10^26

	local usedHashes = {}
	for _, cards in pairs( Bingo_PlayerCards ) do
		for hash in pairs( cards ) do
			usedHashes[hash] = true
		end
	end

	local buildCard = true
	local hash, card, cardString
	while buildCard do
		local values = {}
		for val = 1,75 do
			table.insert(values, val)
		end
		card = {{},{},{},{},{}} -- empty card

		local finished = 0
		while finished < 31 do
			-- get a random value
			local val = table.remove( values, random(1,#values) )
			local col = math.floor((val-1)/15)

			if #card[col+1] < 5 then
				-- Bingo.Print(val.."->"..col.."("..Bingo.letters[col]..")")
				table.insert( card[col+1], val )
				if #card[col+1] == 5 then
					finished = finished + 2^col
				end
			end
		end
		-- set the free spot
		card[3][3] = 0
		cardString = string.format("%s,%s,%s,%s,%s",
			table.concat(card[1],","),
			table.concat(card[2],","),
			table.concat(card[3],","),
			table.concat(card[4],","),
			table.concat(card[5],",")
		)
		hash = Bingo.FNV1a( cardString )
		buildCard = usedHashes[hash] -- set to nil (falsey) if not used already
	end
	return hash, cardString
end
function Bingo.AssignCards( player, minNumber )  -- !cards
	Bingo.Print( "AssignCards( "..player..", "..(minNumber or "nil").." )" )
	if minNumber then
		minNumber = tonumber(minNumber)
		if minNumber > 0 then
			minNumber = math.min( minNumber, Bingo.cardLimit )
			-- count the number of cards that the player has
			local cardCount = 0
			for hash, _ in pairs( Bingo_PlayerCards[player] or {} ) do
				cardCount = cardCount + 1
				Bingo.Print( cardCount.." -> "..hash )
			end
			Bingo_PlayerCards[player] = Bingo_PlayerCards[player] or {}
			for cardNum = cardCount+1, minNumber do
				-- Bingo.Print( "Make card "..cardNum )
				local hash, newCard = Bingo.MakeCard()
				Bingo_PlayerCards[player][hash] = newCard
				Bingo.ShowCard( player, hash )
			end
		else -- minNumber = 0
			Bingo.ReturnCard( player, "all" )
		end
	else
		Bingo.ListCards( player )
	end
end
function Bingo.ListCards( player )  -- !list
	-- Bingo.Print( "ListCards( "..player.." )" )
	-- list card hashes
	if Bingo_PlayerCards[player] then
		Bingo.QueueMessage( "These are your card ids:", player )
		for hash, _ in Bingo.spairs( Bingo_PlayerCards[player] ) do
			Bingo.QueueMessage( hash, player )
		end
	else
		Bingo.QueueMessage( "You have no cards to list.", player )
	end
end
function Bingo.ShowCard( player, hash )  -- !show
	-- Bingo.Print( "ShowCard( "..player..", "..(hash or "nil").." )" )
	local cardQueue = {}
	if Bingo_PlayerCards[player] then
		local cardStr = Bingo_PlayerCards[player][hash]
		if cardStr then
			local cardArray = Bingo.CardStrToArray( cardStr )
			table.insert( cardQueue, " B  I  N  G  O  - "..hash )
			for row = 1,5 do
				table.insert( cardQueue, string.format( "%2d %2d %2d %2d %2d",
						cardArray[row],
						cardArray[5+row],
						cardArray[10+row],
						cardArray[15+row],
						cardArray[20+row]
				))
			end
			Bingo.QueueMessage( cardQueue, player )
		else
			Bingo.QueueMessage( hash.." is not one of your cards.", player )
		end
	else
		Bingo.QueueMessage( "You have no cards.", player )
	end
end
function Bingo.ReturnCard( player, hash )  -- !return
	-- Bingo.Print( "ReturnCard( "..player..", "..(hash or "nil").." )" )
	if Bingo_PlayerCards[player] then
		if hash == "all" then
			Bingo_PlayerCards[player] = nil
			Bingo.QueueMessage( "All of your cards have been returned.", player )
		elseif Bingo_PlayerCards[player][hash] then
			Bingo_PlayerCards[player][hash] = nil
			Bingo.QueueMessage( hash.." has been returned.", player )
			if not next(Bingo_PlayerCards[player]) then
				Bingo_PlayerCards[player] = nil
			end
		else
			Bingo.QueueMessage( hash.." is not one of your cards.", player )
		end
	else
		Bingo.QueueMessage( "You have no cards to return.", player )
	end
end
function Bingo.MakeWinMasks()
	-- masks are bit places
	-- 0, 5, 10, 15, 20
	-- 1, 6, 11, 16, 21
	-- 2, 7, 12, 17, 22,
	-- 3, 8, 13, 18, 23,
	-- 4, 9, 14, 19, 24
	Bingo.WIN_MASKS = {}

	-- columns
	for c = 0, 4 do
		local mask = 0
		for r = 0, 4 do
			-- mask = mask | (1 << ( r * 5 + c ))
			mask = bit.bor( mask, bit.lshift(1, (c*5+r)) )
		end
		table.insert( Bingo.WIN_MASKS, mask )
	end
	-- rows
	for r = 0, 4 do
		local mask = 0
		for c = 0, 4 do
			mask = bit.bor( mask, bit.lshift(1, (c*5+r)) )
		end
		table.insert( Bingo.WIN_MASKS, mask )
	end
	-- Diagonals
	table.insert( Bingo.WIN_MASKS, bit.bor( bit.lshift( 1, 0 ),
							 	bit.bor( bit.lshift( 1, 6 ),
							 		bit.bor( bit.lshift( 1, 12 ),
							 			bit.bor( bit.lshift( 1, 18),
							 				bit.lshift( 1, 24 ) ) ) ) ) )
	table.insert( Bingo.WIN_MASKS, bit.bor( bit.lshift( 1, 4 ),
								bit.bor( bit.lshift( 1, 8 ),
									bit.bor( bit.lshift( 1, 12 ),
										bit.bor( bit.lshift( 1, 16 ),
											bit.lshift( 1, 20 ) ) ) ) ) )
end
function Bingo.CheckForWinningCard( player )
	-- Bingo.Print( "CheckForWinningCard( "..player.." )" )
	if not Bingo.WIN_MASKS then
		Bingo.MakeWinMasks()
	end

	if Bingo_PlayerCards[player] then
		for hash, cardStr in pairs( Bingo_PlayerCards[player] ) do
			local bitCard = bit.lshift(1, 12)  -- set the free spot

			-- print( hash, cardStr, bitCard )
			local cardArray = Bingo.CardStrToArray( cardStr )
			for place, value in ipairs( cardArray ) do
				value = tonumber( value )
				if Bingo_CurrentGame.picked[value] then
					bitCard = bit.bor( bitCard, bit.lshift( 1, place-1 ) )
				end
				-- print( place-1, value, bitCard )
			end

			for _, winMask in ipairs( Bingo.WIN_MASKS ) do
				-- print( "Does "..bit.band( bitCard, winMask ).." = "..winMask.."?" )
				if bit.band( bitCard, winMask ) == winMask then
					Bingo.QueueMessage( player.." has won the game!" )
					Bingo_CurrentGame.winner = player
					Bingo_CurrentGame.endedAt = time()
					Bingo_CurrentGame.stopped = true
					return true
				end
			end
		end
		Bingo.QueueMessage( player.." does not have bingo!" )
	else
		Bingo.QueueMessage( player.." does not have a card!" )
	end
end
function Bingo.RegisterEvents()
	if Bingo_CurrentGame.channel == "guild" then
		BingoFrame:RegisterEvent( "CHAT_MSG_GUILD" )
	elseif Bingo_CurrentGame.channel == "say" then
		BingoFrame:RegisterEvent( "CHAT_MSG_SAY" )
		BingoFrame:RegisterEvent( "CHAT_MSG_YELL" )
	elseif Bingo_CurrentGame.channel == "yell" then
		BingoFrame:RegisterEvent( "CHAT_MSG_SAY" )
		BingoFrame:RegisterEvent( "CHAT_MSG_YELL" )
	elseif Bingo_CurrentGame.channel == "raid" then
		BingoFrame:RegisterEvent( "CHAT_MSG_PARTY" )
		BingoFrame:RegisterEvent( "CHAT_MSG_PARTY_LEADER" )
		BingoFrame:RegisterEvent( "CHAT_MSG_RAID" )
		BingoFrame:RegisterEvent( "CHAT_MSG_RAID_LEADER" )
		BingoFrame:RegisterEvent( "CHAT_MSG_RAID_WARNING" )
	elseif Bingo_CurrentGame.channel == "party" then
		BingoFrame:RegisterEvent( "CHAT_MSG_PARTY" )
		BingoFrame:RegisterEvent( "CHAT_MSG_PARTY_LEADER" )
	end
	BingoFrame:RegisterEvent( "CHAT_MSG_WHISPER" )
end
function Bingo.UnregisterEvents()
	BingoFrame:UnregisterEvent( "CHAT_MSG_GUILD" )
	BingoFrame:UnregisterEvent( "CHAT_MSG_SAY" )
	BingoFrame:UnregisterEvent( "CHAT_MSG_YELL" )
	BingoFrame:UnregisterEvent( "CHAT_MSG_PARTY" )
	BingoFrame:UnregisterEvent( "CHAT_MSG_PARTY_LEADER" )
	BingoFrame:UnregisterEvent( "CHAT_MSG_RAID" )
	BingoFrame:UnregisterEvent( "CHAT_MSG_RAID_LEADER" )
	BingoFrame:UnregisterEvent( "CHAT_MSG_RAID_WARNING" )
	BingoFrame:UnregisterEvent( "CHAT_MSG_PARTY" )
	BingoFrame:UnregisterEvent( "CHAT_MSG_PARTY_LEADER" )
end
function Bingo.CHAT_MSG_WHISPER( self, msg, sender )
	-- Bingo.Print( "CHAT_MSG_WHISPER( "..msg..", "..sender.." )" )
	local cmd, param = Bingo.ParseCmd( msg )
	if Bingo.bangCommands[cmd] then
		Bingo.bangCommands[cmd](sender, param)
	end
end
function Bingo.CHAT_MSG_( self, msg, sender )
	msg = string.lower( msg )
	-- Bingo.Print("CHAT_MSG_( "..msg..", "..sender.." )" )
	if Bingo_CurrentGame.startedAt and Bingo_CurrentGame.startedAt < time() then
		if strmatch( msg, "^[!]?bingo[!]?$") then
			if strmatch( msg, "^!" ) or strmatch( msg, "!$" ) then
				Bingo.SendMessage( sender.." has called BINGO!", Bingo_CurrentGame.channel )
				Bingo.CheckForWinningCard( sender )
			end
		end
	end
end
Bingo.CHAT_MSG_SAY = Bingo.CHAT_MSG_
Bingo.CHAT_MSG_YELL = Bingo.CHAT_MSG_
Bingo.CHAT_MSG_GUILD = Bingo.CHAT_MSG_
Bingo.CHAT_MSG_PARTY = Bingo.CHAT_MSG_
Bingo.CHAT_MSG_PARTY_LEADER = Bingo.CHAT_MSG_
Bingo.CHAT_MSG_RAID = Bingo.CHAT_MSG_
Bingo.CHAT_MSG_RAID_LEADER = Bingo.CHAT_MSG_
Bingo.CHAT_MSG_RAID_WARNING = Bingo.CHAT_MSG_
function Bingo.ResetGame()
	Bingo_CurrentGame = {}
	Bingo.UnregisterEvents()
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
	["say"] = {
		["func"] = function() Bingo.StartGame("say") end,
		["help"] = {"", "Start game in say chat"},
	},
	["yell"] = {
		["func"] = function() Bingo.StartGame("yell") end,
		["help"] = {"", "Start game in yell chat"},
	},
	["reset"] = {
		["func"] = Bingo.ResetGame,
		["help"] = {"", "Reset the system."},
	},
}
Bingo.bangCommands = {
	["!help"] = function( player )
			Bingo.QueueMessage( Bingo.helpMessages, player )
		end,
	["!cards"] = Bingo.AssignCards,
	["!card"] = Bingo.AssignCards,
	["!list"] = Bingo.ListCards,
	["!show"] = Bingo.ShowCard,
	["!return"] = Bingo.ReturnCard,
	["!tips"] = function( player )
			Bingo.QueueMessage( Bingo.tipMessages, player )
		end,
}
