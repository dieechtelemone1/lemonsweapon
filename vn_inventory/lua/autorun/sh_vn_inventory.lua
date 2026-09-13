-- VN Inventory - shared item registry and configuration.

if SERVER then AddCSLuaFile() end

VN_INV = VN_INV or {}
VN_INV.Items = {}
VN_INV.Order = {}

VN_INV.MaxSlots = 32  -- entspricht 4 Reihen à 8 Feldern im Inventar
VN_INV.CrateRange = 150
VN_INV.UseCooldown = 0.4
VN_INV.DropLifetime = 300  -- Sekunden, bis abgelegte Items wieder verschwinden
VN_INV.DropModel = "models/Items/item_item_crate.mdl"

function VN_INV.Register(id, data)
	data.id = id
	data.name = data.name or id
	data.desc = data.desc or ""
	data.category = data.category or "Sonstiges"
	data.maxStack = data.maxStack or 10
	data.consumed = data.consumed ~= false
	data.cost = data.cost or 1
	data.crate = data.crate or "supply"
	data.dropModel = data.dropModel or VN_INV.DropModel

	if not VN_INV.Items[id] then
		VN_INV.Order[#VN_INV.Order + 1] = id
	end

	VN_INV.Items[id] = data
end

function VN_INV.Get(id)
	return VN_INV.Items[id]
end

-- Every crate class and the item category it hands out.
VN_INV.CrateClasses = {
	vn_supply_crate = "supply",
	vn_medic_crate = "medic",
}

function VN_INV.CrateType(ent)
	if not IsValid(ent) then return nil end
	return VN_INV.CrateClasses[ent:GetClass()]
end

-- Munition -------------------------------------------------------------

local ammoBoxes = {
	{ id = "ammo_pistol",   name = "Pistolen-Munition", ammo = "Pistol",   amount = 36, cost = 2 },
	{ id = "ammo_smg",      name = "SMG-Munition",      ammo = "SMG1",     amount = 90, cost = 3 },
	{ id = "ammo_rifle",    name = "Blaster-Zellen",    ammo = "AR2",      amount = 60, cost = 3 },
	{ id = "ammo_buckshot", name = "Schrot-Munition",   ammo = "Buckshot", amount = 24, cost = 3 },
	{ id = "ammo_sniper",   name = "Scharfschützen-Munition", ammo = "357", amount = 18, cost = 4 },
}

for _, box in ipairs(ammoBoxes) do
	VN_INV.Register(box.id, {
		name = box.name,
		desc = box.amount .. " Schuss",
		category = "Munition",
		maxStack = 10,
		cost = box.cost,
		dropModel = "models/Items/BoxMRounds.mdl",
		OnUse = function(ply)
			ply:GiveAmmo(box.amount, box.ammo, true)
			return true
		end,
	})
end

-- Ausrüstung -----------------------------------------------------------

VN_INV.Register("grenade", {
	name = "Granate",
	desc = "Splittergranate",
	category = "Ausrüstung",
	maxStack = 5,
	cost = 6,
	dropModel = "models/Items/grenadeAmmo.mdl",
	OnUse = function(ply)
		if not ply:HasWeapon("weapon_frag") then
			ply:Give("weapon_frag")
		else
			ply:GiveAmmo(1, "Grenade", true)
		end

		ply:SelectWeapon("weapon_frag")
		return true
	end,
})

VN_INV.Register("binoculars", {
	name = "Fernglas",
	desc = "Zoom an/aus - wird nicht verbraucht",
	category = "Ausrüstung",
	maxStack = 1,
	consumed = false,
	cost = 10,
	OnUse = function(ply)
		ply:SetNWBool("vn_inv_binoculars", not ply:GetNWBool("vn_inv_binoculars", false))
		return true
	end,
})

-- Techniker ------------------------------------------------------------

VN_INV.Register("repair_kit", {
	name = "Reparaturkit",
	desc = "Repariert das anvisierte Fahrzeug oder Objekt",
	category = "Techniker",
	maxStack = 5,
	cost = 8,
	OnUse = function(ply)
		local ent = ply:GetEyeTrace().Entity
		if not IsValid(ent) or ent:IsPlayer() then return false, "Kein gültiges Ziel anvisiert." end
		if ply:GetPos():Distance(ent:GetPos()) > 200 then return false, "Ziel ist zu weit weg." end

		local max = ent:GetMaxHealth()
		if max <= 0 then max = 100 end
		if ent:Health() >= max then return false, "Ziel ist bereits intakt." end

		ent:SetHealth(math.min(ent:Health() + 50, max))
		return true
	end,
})

-- Medic: folgt, sobald die Item-Datei da ist.
