-- VN Logistics - supply requests from the field and deliveries from the Navy.

util.AddNetworkString("vn_log_open")
util.AddNetworkString("vn_log_data")
util.AddNetworkString("vn_log_request")
util.AddNetworkString("vn_log_deliver")
util.AddNetworkString("vn_log_refresh")

local requests = {}
local nextAction = {}

local function Notify(ply, text)
	net.Start("vn_inv_notify")
	net.WriteString(text)
	net.Send(ply)
end

local function NotifyLogistics(text)
	for _, ply in ipairs(player.GetAll()) do
		if VN_LOG.IsLogistics(ply) then Notify(ply, text) end
	end
end

local function Crates()
	return ents.FindByClass("vn_supply_crate")
end

local function SendData(ply)
	local crates = Crates()

	net.Start("vn_log_data")
	net.WriteUInt(#crates, 8)

	for _, crate in ipairs(crates) do
		local request = requests[crate]

		net.WriteEntity(crate)
		net.WriteString(crate:GetCrateName())
		net.WriteUInt(math.max(crate:GetSupply(), 0), 16)
		net.WriteBool(request ~= nil)
		net.WriteString(request and request.requester or "")
		net.WriteUInt(request and math.max(math.ceil(request.eta - CurTime()), 0) or 0, 16)
	end

	net.Send(ply)
end

function VN_LOG.OpenPad(ply)
	if not VN_LOG.IsLogistics(ply) then
		Notify(ply, "Nur die Navy darf das Datapad benutzen.")
		return
	end

	net.Start("vn_log_open")
	net.Send(ply)

	SendData(ply)
end

local nextRefresh = {}

net.Receive("vn_log_refresh", function(_, ply)
	if (nextRefresh[ply] or 0) > CurTime() then return end
	nextRefresh[ply] = CurTime() + 1

	if not VN_LOG.IsLogistics(ply) then return end

	SendData(ply)
end)

net.Receive("vn_log_request", function(_, ply)
	if (nextAction[ply] or 0) > CurTime() then return end
	nextAction[ply] = CurTime() + 1

	local crate = net.ReadEntity()
	if not IsValid(crate) or crate:GetClass() ~= "vn_supply_crate" then return end
	if not ply:Alive() then return end
	if ply:GetPos():Distance(crate:GetPos()) > VN_INV.CrateRange then return end

	if requests[crate] then
		Notify(ply, "Für diese Kiste läuft bereits eine Anforderung.")
		return
	end

	if (crate.nextRequest or 0) > CurTime() then
		Notify(ply, "Zu kurz nach der letzten Anforderung. Bitte warten.")
		return
	end

	if crate:GetSupply() >= VN_LOG.MaxSupply then
		Notify(ply, "Diese Kiste ist voll.")
		return
	end

	crate.nextRequest = CurTime() + VN_LOG.RequestCooldown
	crate:SetRequested(true)

	requests[crate] = {
		requester = ply:Nick(),
		crateName = crate:GetCrateName(),
		eta = 0,
		delivered = false,
	}

	Notify(ply, "Nachschub für " .. crate:GetCrateName() .. " angefordert.")
	NotifyLogistics("Neue Anforderung: " .. crate:GetCrateName() .. " (von " .. ply:Nick() .. ")")
end)

net.Receive("vn_log_deliver", function(_, ply)
	if (nextAction[ply] or 0) > CurTime() then return end
	nextAction[ply] = CurTime() + 1

	if not VN_LOG.IsLogistics(ply) then return end

	local crate = net.ReadEntity()
	if not IsValid(crate) or crate:GetClass() ~= "vn_supply_crate" then return end

	local request = requests[crate]
	if request and request.eta > CurTime() then
		Notify(ply, "Für diese Kiste ist bereits eine Lieferung unterwegs.")
		return
	end

	if crate:GetSupply() >= VN_LOG.MaxSupply then
		Notify(ply, "Diese Kiste ist voll.")
		return
	end

	requests[crate] = {
		requester = request and request.requester or "-",
		crateName = crate:GetCrateName(),
		eta = CurTime() + VN_LOG.DeliveryTime,
	}

	crate:SetRequested(true)
	Notify(ply, "Lieferung an " .. crate:GetCrateName() .. " abgeschickt.")

	timer.Simple(VN_LOG.DeliveryTime, function()
		if not IsValid(crate) then return end

		crate:AddSupply(VN_LOG.PackageSize)
		requests[crate] = nil

		for _, other in ipairs(player.GetAll()) do
			if other:GetPos():Distance(crate:GetPos()) <= 1000 or VN_LOG.IsLogistics(other) then
				Notify(other, "Nachschub für " .. crate:GetCrateName() .. " ist eingetroffen.")
			end
		end
	end)
end)

concommand.Add("vn_log_name", function(ply, _, args)
	if not IsValid(ply) or not ply:IsAdmin() then return end

	local crate = ply:GetEyeTrace().Entity
	if not IsValid(crate) or crate:GetClass() ~= "vn_supply_crate" then
		Notify(ply, "Keine Versorgungskiste anvisiert.")
		return
	end

	local name = string.Trim(table.concat(args, " "))
	if name == "" then
		Notify(ply, "Benutzung: vn_log_name <Name>")
		return
	end

	crate:SetCrateName(string.sub(name, 1, 32))
	Notify(ply, "Kiste umbenannt.")
end, nil, "Benennt die anvisierte Versorgungskiste um (Admin)")

hook.Add("EntityRemoved", "vn_log_cleanup", function(ent)
	requests[ent] = nil
end)

hook.Add("PlayerDisconnected", "vn_log_cleanup_cooldowns", function(ply)
	nextAction[ply] = nil
	nextRefresh[ply] = nil
end)
