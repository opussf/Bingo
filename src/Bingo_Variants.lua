BINGO_SLUG, Bingo   = ...

Bingo.variants["box"] = {
    func = function() return { 33080895 } end,
    text = "Large box, all edges."
}
Bingo.variants["corners"] = {
	func = function() return { 17825809 } end,
    text = "4 corners",
}
Bingo.variants["tee"] = {
    func = function() return {
        1113121, -- top
		4325535, -- left
		17329680, -- bottom
		32637060 } -- right
    end,
    text = "T shape",
}
Bingo.variants["ex"] = {
    func = function() return { 18153809 } end,
    text = "X shape",
}
Bingo.variants["plus"] = {
	func = function() return { 4353156 } end,
    text = "+ shape",
}
Bingo.variants["full"] = {
    func = function() return { 33554431 } end,
    text = "Full house, blackout, etc.",
}
Bingo.variants["chevron"] = {
	func = function() return {
		1118273,   -- top
		18157568,  -- right
		17043728,  -- bottom
		4433 }     -- left
    end,
	text = "Chevon, any 2 adjacent corners to center",
}
Bingo.variants["hotdog"] = {
    func = function() return { 4667844 } end,
    text = "center 3x3, with center B and O",
}
Bingo.variants["postage"] = {
    func = function() return {
		99,       -- top left
		3244032,  -- top right
		25952256, -- bottom right
		792 }     -- bottom left
    end,
    text = "2x2 square in any corner",
}
Bingo.variants["kite"] = {
	func = function() return {
		17043555, -- top left
		3248400,  -- top right
		25956417, -- bottom right
		1119000 } -- bottom left
	end,
	text = "2x2 corner square with connected diagonal line",
}
Bingo.variants["flagpoles"] = {
    func = function() return {
		20287859,  -- top
		29200721,  -- right
		27071321,  -- bottom
		18158459 } -- left
	end,
    text = "X with adjacent 2x2 corners",
}
Bingo.variants["sputnik"] = {
	func = function() return { 18299345 } end,
	text = "center 3x3 with corners",
}
Bingo.variants["flyswatter"] = {
	func = function() return {
		1056743,  -- 1
		2105319,  -- 2
		4202471,  -- 3
		8396775,  -- 4
		16785383 }-- 5
    end,
	text = "top left 3x3, All of I, and O",
}
Bingo.variants["pyramid"] = {
	func = function() return {
		1154145,  -- top
		32968704, -- right
		17593104, -- bottom
		4575 }    -- left
    end,
	text = "any full edge, with center 3 next to it",
}
Bingo.variants["star"] = {
	func = function() return { 18185553 } end, -- X with all of N
	text = "X and all of N",
}
Bingo.variants["el"] = {
	func = function() return {
		1082431,   -- top left
		32539681,  -- top right
		33047056,  -- bottom right
		17318431 } -- bottom left
    end,
	text = "L shape in any corner",
}
Bingo.variants["bowtie"] = {
    func = function() return {
        25952355,   -- \
        3244824 }   -- /
    end,
    text = "2x2 square in opposite corners"
}
Bingo.variants["arrowhead"] = {
    func = function() return {
        1127,     -- top left
        7439360,  -- top right
        30162944, -- bottom right
        17180 }   -- bottom left
    end,
    text = "3x3 triangle pointing in corner"
}
