-- VN Inventory - storage, persistence and the authoritative use/take logic.

util.AddNetworkString("vn_inv_sync")
util.AddNetworkString("vn_inv_use")
util.AddNetworkString("vn_inv_crate")
util.AddNetworkString("vn_inv_take")
util.AddNetworkString("vn_inv_notify")

if not sql.TableExists("vn_inventory") then
	sql.Query("CREATE TABLE vn_inventory (steamid TEXT PRIMARY KEY, data TEXT)")
end

local inventories = {}

local function Notify(ply, text)
	net.Start("vn_inv_notify")
	net.WriteString(text)
	net.Send(ply)
end

local function Sync(ply)
	local inv = inventories[ply:SteamID64()] or {}

	net.Start("vn_inv_sync")
	net.WriteUInt(table.Count(inv), 8)
	for id, count in pairs(inv) do
		net.WriteString(id)
		net.WriteUInt(count, 16)
	end
	net.Send(ply)
end

local function Save(steamid)
	local inv = inventories[steamid]
	if not inv then return end

	sql.Query("REPLACE INTO vn_inventory (steamid, data) VALUES (" ..
		sql.SQLStr(steamid) .. ", " .. sql.SQLStr(util.TableToJSON(inv)) .. ")")
end

local function Load(ply)
	local steamid = ply:SteamID64()
	local row = sql.QueryValue("SELECT data FROM vn_inventory WHERE steamid = " .. sql.SQLStr(steamid))
	local inv = row and util.JSONToTable(row) or {}

	-- Items that no longer exist in the registry are dropped on load, so a
	-- renamed or removed item cannot leave an unusable entry behind.
	for id in pairs(inv) do
		if not VN_INV.Get(id) then inv[id] = nil end
	end

	inventories[steamid] = inv
	Sync(ply)
end

function VN_INV.GiveItem(ply, id, count)
	local item = VN_INV.Get(id)
	if not item then return false end

	count = math.max(1, math.floor(count or 1))

	local inv = inventories[ply:SteamID64()]
	if not inv then return false end

	local current = inv[id] or 0
	if current == 0 and table.Count(inv) >= VN_INV.MaxSlots then
		return false, "Inventar ist voll."
	end

	if current >= item.maxStack then
		return false, "Maximale Anzahl erreicht."
	end

	inv[id] = math.min(current + count, item.maxStack)

	Save(ply:SteamID64())
	Sync(ply)
	return true
end

function VN_INV.TakeItem(ply, id, count)
	local inv = inventories[ply:SteamID64()]
	if not inv or not inv[id] then return false end

	inv[id] = inv[id] - math.max(1, math.floor(count or 1))
	if inv[id] <= 0 then inv[id] = nil end

	Save(ply:SteamID64())
	Sync(ply)
	return true
end

function VN_INV.Clear(ply)
	inventories[ply:SteamID64()] = {}
	ply:SetNWBool("vn_inv_binoculars", false)

	Save(ply:SteamID64())
	Sync(ply)
end

hook.Add("PlayerInitialSpawn", "vn_inv_load", Load)

hook.Add("PlayerDisconnected", "vn_inv_save", function(ply)
	local steamid = ply:SteamID64()
	Save(steamid)
	inventories[steamid] = nil
end)

hook.Add("PlayerDeath", "vn_inv_clear", function(ply)
	VN_INV.Clear(ply)
end)

hook.Add("ShutDown", "vn_inv_save_all", function()
	for steamid in pairs(inventories) do
		Save(steamid)
	end
end)

local nextUse = {}

net.Receive("vn_inv_use", function(_, ply)
	if (nextUse[ply] or 0) > CurTime() then return end
	nextUse[ply] = CurTime() + VN_INV.UseCooldown

	if not ply:Alive() then return end

	local id = net.ReadString()
	local item = VN_INV.Get(id)
	if not item or not item.OnUse then return end

	local inv = inventories[ply:SteamID64()]
	if not inv or not inv[id] then return end

	local ok, reason = item.OnUse(ply)
	if not ok then
		if reason then Notify(ply, reason) end
		return
	end

	if item.consumed then
		VN_INV.TakeItem(ply, id, 1)
	end
end)

net.Receive("vn_inv_take", function(_, ply)
	if (nextUse[ply] or 0) > CurTime() then return end
	nextUse[ply] = CurTime() + VN_INV.UseCooldown

	local crate = net.ReadEntity()
	local id = net.ReadString()

	if not IsValid(crate) or crate:GetClass() ~= "vn_supply_crate" then return end
	if not ply:Alive() then return end
	if ply:GetPos():Distance(crate:GetPos()) > VN_INV.CrateRange then return end
	if not VN_INV.Get(id) then return end

	local ok, reason = VN_INV.GiveItem(ply, id, 1)
	if not ok and reason then Notify(ply, reason) end
end)

concommand.Add("vn_inv_give", function(ply, _, args)
	if IsValid(ply) and not ply:IsAdmin() then return end

	local target = args[1]
	local id = args[2]
	local count = tonumber(args[3]) or 1

	if not target or not id then
		print("Benutzung: vn_inv_give <Spielername> <Item-ID> [Anzahl]")
		return
	end

	for _, other in ipairs(player.GetAll()) do
		if string.find(string.lower(other:Nick()), string.lower(target), 1, true) then
			VN_INV.GiveItem(other, id, count)
			return
		end
	end
end, nil, "Gibt einem Spieler ein Item ins Inventar (Admin)")
