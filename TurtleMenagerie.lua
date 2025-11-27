if not Menagerie_Pets then Menagerie_Pets = { } end
if not Menagerie_Mounts then Menagerie_Mounts = { } end
Menagerie_LastPet = ""
Menagerie_LastMount = ""
local gfind = string.gmatch or string.gfind
local function strmatch(str, pat, init)
	local a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a13,a14,a15,a16,a17,a18,a19,a20 = string.find(str, pat, init)
	return a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a13,a14,a15,a16,a17,a18,a19,a20
end

function Menagerie_OnEvent(event, arg1)
	if event == "UNIT_FLAGS" and arg1 == "player" then
		if UnitOnTaxi("player") == 1 then
			DEFAULT_CHAT_FRAME:AddMessage("|cffbe5eff[Turtle Menagerie]|r Flying")
		else
			DEFAULT_CHAT_FRAME:AddMessage("|cffbe5eff[Turtle Menagerie]|r NOT flying")
		end
	elseif event == "PLAYER_ENTERING_WORLD" then
		DEFAULT_CHAT_FRAME:AddMessage("|cffbe5eff[Turtle Menagerie]|r Entering World")
	end
end

-- Generate the list of friends
local function FindFriends()
	for i = 1, MAX_SKILLLINE_TABS do
		local name, texture, offset, numSpells = GetSpellTabInfo(i);
		
		if not name then
			break;
		end
		
		SearchTab(name, offset, numSpells, "ZzCompanions", Menagerie_Pets, pets, function(spell)
			return true
		end)
		
		if GetZoneText() == "Ahn'Qiraj" then
			SearchTab(name, offset, numSpells, "ZMounts", Menagerie_Mounts, mounts, function(spell)
				return string.find(spell, "Qiraji Battle Tank")
			end)
		else
			SearchTab(name, offset, numSpells, "ZMounts", Menagerie_Mounts, mounts, function(spell)
				return not string.find(spell, "Qiraji Battle Tank")
			end)
			
			-- Search class talent trees for mounts using filter functions
			SearchTab(name, offset, numSpells, "Demonology", Menagerie_Mounts, mounts, function(spell)
				return string.find(spell, "Summon Felsteed") or string.find(spell, "Summon Dreadsteed")
			end)
			SearchTab(name, offset, numSpells, "Protection", Menagerie_Mounts, mounts, function(spell)
				return string.find(spell, "Summon Warhorse") or string.find(spell, "Summon Charger")
			end)
			SearchTab(name, offset, numSpells, "Feral Combat", Menagerie_Mounts, mounts, function(spell)
				return string.find(spell, "Travel Form")
			end)
		end
	end
end

function SearchTab(name, offset, numSpells, tabName, blacklistTable, targetTable, allowFunc)
	-- tabName: the spellbook tab to inspect
	-- blacklistTable: table of blacklisted pet/mount names
	-- targetTable: pets/mounts table to insert into
	-- allowFunc: function(spell) -> boolean, return true to add spell to pets/mounts
	
	if name ~= tabName then return end
	
	for s = offset + 1, offset + numSpells do
		local spell, rank = GetSpellName(s, BOOKTYPE_SPELL)
		if not spell then break end
		
		-- Check for blacklisted items
		local bl = false
		for i = 1, table.getn(blacklistTable) do
			if string.lower(spell) == blacklistTable[i] then
				bl = true
				break
			end
		end
		
		if not bl and allowFunc and allowFunc(spell) then
			table.insert(targetTable, spell)
		end
	end
end



SLASH_MENAGERIEPET1, SLASH_MENAGERIEPET2 = "/randompet", "/randpet"
SlashCmdList["MENAGERIEPET"] = function(message)
	Menagerie("pets " .. message)
end

SLASH_MENAGERIEMOUNT1, SLASH_MENAGERIEMOUNT2 = "/randommount", "/randmount"
SlashCmdList["MENAGERIEMOUNT"] = function(message)
	Menagerie("mounts " .. message)
end

SLASH_MENAGERIEBANK1 = "/bank"
SlashCmdList["SLASH_MENAGERIEBANK1"] = function(message)
	 CastSpellByName("Forworn Mule")
end

-- A lot of this blacklist code is heavily based on Shagu's ShaguChat.
function Menagerie(message)
	pets = {}
	mounts = {}
	
	local commandlist = {}
	local command
	
	for command in gfind(message, "[^ ]+") do
		table.insert(commandlist, string.lower(command))
	end
	
	FindFriends()
	
	-- Add to blacklist
	if commandlist[2] == "bl" then
		AddToBlacklist(commandlist)
		
	-- Remove from blacklist
	elseif commandlist[2] == "rm" then
		RemoveFromBlacklist(commandlist)
		
	-- List the blacklist
	elseif commandlist[2] == "ls" then
		ListBlacklist(commandlist)
		
	-- Summon our friends!
	else
		SummonRandomCompanion(commandlist)
	end
end

function SummonRandomCompanion(commandlist)
	local function SummonRandomCompanionFromList(list, lastValue, lastSetter, emptyMessage)
		-- remove last summon so it won't be picked again
		-- do it only when there are more options to choose from
		if table.getn(list) > 1 and lastValue ~= "" then
			local found, idx = doesTableContain(list, lastValue)
			if found then
				table.remove(list, idx)
			end
		end
		
		-- pick new one
		if table.getn(list) > 0 then
			local chosen = list[math.random(table.getn(list))]
			lastSetter(chosen)
			CastSpellByName(chosen)
		else
			DEFAULT_CHAT_FRAME:AddMessage("|cffbe5eff[Turtle Menagerie]|r " .. emptyMessage)
		end
	end
	
	if commandlist[1] == "pets" then
		SummonRandomCompanionFromList(
			pets,
			Menagerie_LastPet,
			function(v) Menagerie_LastPet = v end,
			"No pets available."
		)
		elseif commandlist[1] == "mounts" then
		SummonRandomCompanionFromList(
			mounts,
			Menagerie_LastMount,
			function(v) Menagerie_LastMount = v end,
			"No mounts available."
		)
	end
end

function ListBlacklist(commandlist)
	local rmTable = GetCompanionsTable(commandlist[1])
	DEFAULT_CHAT_FRAME:AddMessage("|cffbe5eff[Turtle Menagerie]|r Blacklisted |cffbe5eff" .. commandlist[1] .. "|r:")
	
	for id, bl in pairs(rmTable) do
		DEFAULT_CHAT_FRAME:AddMessage(" |r[|cffbe5eff" .. id .. "|r] " .. bl)
	end
end

function AddToBlacklist(commandlist)
	local input = table.concat(commandlist, " ", 3)
	if input == "" then return end
	
	local m = strmatch(input, "%[(.+)%]")
	if m then
		input = m
	end
	DEFAULT_CHAT_FRAME:AddMessage("|cffbe5eff[Turtle Menagerie]|r Adding |cffbe5eff".. input .."|r to your |cffbe5eff" .. commandlist[1] .. "|r blacklist")
	companions = GetCompanionsTable(commandlist[1])
	table.insert(companions, string.lower(input))
end


function RemoveFromBlacklist(commandlist)
	local rmTable = GetCompanionsTable(commandlist[1])
	local input = table.concat(commandlist, " ", 3)
	if input == "" then return end
	
	local indexToRemove = tonumber(input)
	local nameToRemove = nil
	
	if indexToRemove then
		-- Remove by index
		if indexToRemove >= 1 and indexToRemove <= table.getn(rmTable) then
			nameToRemove = rmTable[indexToRemove]
		else
			DEFAULT_CHAT_FRAME:AddMessage("|cffbe5eff[Turtle Menagerie]|r Index |cffbe5eff" .. indexToRemove .. "|r out of range for your |cffbe5eff" .. commandlist[1] .. "|r blacklist")
			return
		end
	else
		-- Remove by name
		nameToRemove = input
		local isContained, idx = doesTableContain(rmTable, nameToRemove)
		if isContained then
			indexToRemove = idx
		else
			DEFAULT_CHAT_FRAME:AddMessage("|cffbe5eff[Turtle Menagerie]|r |cffbe5eff" .. nameToRemove .. "|r not found in your |cffbe5eff" .. commandlist[1] .. "|r blacklist")
			return
		end
	end
	
	DEFAULT_CHAT_FRAME:AddMessage("|cffbe5eff[Turtle Menagerie]|r Removing |cffbe5eff" .. nameToRemove .. "|r from your |cffbe5eff" .. commandlist[1] .. "|r blacklist")
	table.remove(rmTable, indexToRemove)
end

function GetCompanionsTable(command)
	if command == "pets" then
		return Menagerie_Pets
	elseif command == "mounts" then
		return Menagerie_Mounts
	end
	return nil
end

function doesTableContain(table, contains)
	local found = false
	local index = nil
	for k, v in pairs(table) do
		if v == contains then
			found = true
			index = k
		end
	end
	return found, index
end
