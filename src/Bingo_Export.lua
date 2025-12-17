#!/usr/bin/env lua
-- Version: @VERSION@

accountPath = arg[1]
exportType = arg[2]

pathSeparator = string.sub(package.config, 1, 1) -- first character of this string (http://www.lua.org/manual/5.2/manual.html#pdf-package.config)
-- remove 'extra' separators from the end of the given path
while (string.sub( accountPath, -1, -1 ) == pathSeparator) do
	accountPath = string.sub( accountPath, 1, -2 )
end
-- append the expected location of the datafile
dataFilePath = {
	accountPath,
	"SavedVariables",
	"Bingo.lua"
}
dataFile = table.concat( dataFilePath, pathSeparator )
cards = {}

function FileExists( name )
	local f = io.open( name, "r" )
	if f then io.close( f ) return true else return false end
end
function DoFile( filename )
	local f = assert( loadfile( filename ) )
	return f()
end
function BuildCardData()
	for _, pcards in pairs( Bingo_PlayerCards ) do
		for id, card in pairs( pcards ) do
			cards[id] = card
		end
	end
end
function ExportXML()
	strOut = "<?xml version='1.0' encoding='utf-8' ?>\n"
	strOut = strOut .. "<cards>\n"

	for id, card in sorted_pairs( cards ) do
		strOut = strOut .. string.format( "<card id=\"%s\">%s</card>\n", id, card )
	end

	strOut = strOut .. "</cards>\n"
	return strOut
end
function ExportJSON()
	strOut = "{\"cards\": [\n"

	cardsOut = {}

	for id, card in sorted_pairs( cards ) do
		table.insert( cardsOut, string.format( "\t{\"id\":\"%s\", \"card\":\"%s\"}", id, card ) )
	end

	strOut = strOut .. table.concat( cardsOut, ",\n" ) .. "\n]}"

	return strOut
end
function sorted_pairs( tableIn )
	local keys = {}
	for k in pairs( tableIn ) do table.insert( keys, k ) end
	table.sort( keys )
	local lcv = 0
	local iter = function()
		lcv = lcv + 1
		if keys[lcv] == nil then return nil
		else return keys[lcv], tableIn[keys[lcv]]
		end
	end
	return iter
end

functionList = {
	["xml"] = ExportXML,
	["json"] = ExportJSON
}

func = functionList[string.lower( exportType )]

if dataFile and FileExists( dataFile ) and exportType and func then
	DoFile( dataFile )
	BuildCardData()
	strOut = func()
	print( strOut )
else
	io.stderr:write( "Something is wrong.  Lets review:\n")
	io.stderr:write( "Data file provided: "..( dataFile and " True" or "False" ).."\n" )
	io.stderr:write( "Data file exists  : "..( FileExists( dataFile ) and " True" or "False" ).."\n" )
	io.stderr:write( "ExportType given  : "..( exportType and " True" or "False" ).."\n" )
	io.stderr:write( "ExportType valid  : "..( func and " True" or "False" ).."\n" )
end
