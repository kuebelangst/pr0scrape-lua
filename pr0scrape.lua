#!/usr/bin/env lua
-- pr0scrape als lua
-- imports
local http = require("socket.http")
local JSON = (loadfile "JSON.lua")() 
local socket = 	require("socket")

-- "global" variables
local apiURL = "http://pr0gramm.com/api/items/get?newer="
local picURL = "http://pr0gramm.com/data/images/"
local dumpDir = "/tmp/pr0scrape/"
local fileExt = ".pic"
local saveStateFile = "savestate"
local lastID = 0

-- helper functions
-- lua has no own sleep, so we abuse socket.select()
function sleep(seconds)
	socket.select(nil,nil,seconds)
end

-- here we go
function main()
	saveStateFile = dumpDir..saveStateFile
	idFromFile = io.open(saveStateFile,"r")
	io.input(idFromFile)
	lastID = io.read("*a")
	lastID = scrapeIDs(lastID)
	print("Feddich...")
end

function scrapeIDs(startID)

	json, status = http.request(apiURL..lastID)
	content = JSON:decode(json)
	if status == 200 then
		for id,value in pairs(content["items"]) do
			-- i don't believe this brings any speed :D
			-- just keeping it as close to the Golang version
			-- as possible
			local co = coroutine.create(function()
					fetchImage(value["source"],value["id"])
				end)
			coroutine.resume(co)
			lastID = value["id"]
		end
	end

	tempfile = io.open(saveStateFile,"w")
	tempfile:write(lastID)
	tempfile:close()
	io.write("Wrote new ID: "..lastID.." to savestate file\n")
	sleep(10)

	if content["atStart"] == true then
		return -1
	end

	return scrapeIDs(lastID)
end

function fetchImage(path,ID)
	success = false
	img, status = http.request(picURL..path)
	if status == 200 then
		outfile = io.open(dumpDir..ID..fileExt,"a")
		outfile:write(img)
		outfile:close()
		success = true
	end
	return success
end

-- start pr0scrape
main()