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

function Bingo.Print( msg, showName )
    -- print to the chat frame
    if (showName == nil) or (showName) then
        msg = Bingo.COLOR.ORANGE..Bingo.MSG_ADDONNAME.."> "..Bingo.COLOR.END..msg
    end
    DEFAULT_CHAT_FRAME:AddMessage( msg )
end
function Bingo.OnLoad()
    SLASH_BINGO1 = "/BINGO"
    SlashCmdList["BINGO"] = Bingo.Command
    Bingo_Frame:RegisterEvent("PLAYER_ENTERING_WORLD")
end
function Bingo.PLAYER_ENTERING_WORLD()
    -- do something here
end
function Bingo.StartGame( chatToUse )

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
}