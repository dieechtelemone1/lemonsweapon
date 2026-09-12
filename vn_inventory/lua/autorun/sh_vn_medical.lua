-- Brücke zu Kraken's Medical System (KMS).
--
-- Registriert die KMS-Sanitätsartikel als Inhalt der Sanitätskiste. Entnommene
-- Artikel landen nicht im VN-Inventar, sondern direkt im KMS-Inventar des
-- Spielers, damit sie über das gewohnte Medic-Menü benutzbar sind.
-- An den Dateien von KMS wird nichts verändert.

if SERVER then AddCSLuaFile() end

-- Vorrat pro Artikel und deutscher Anzeigename als Rückfall, falls die
-- Sprachdatei von KMS den Namen (noch) nicht liefert.
local MEDICAL = {
	{ id = "bandage_field",    cost = 2,  name = "Feldverband" },
	{ id = "bandage_packing",  cost = 3,  name = "Tamponade-Verband" },
	{ id = "bandage_elastic",  cost = 2,  name = "Elastischer Verband" },
	{ id = "bandage_quickclot", cost = 4, name = "QuickClot-Verband" },
	{ id = "tourniquet",       cost = 3,  name = "Tourniquet" },
	{ id = "splint",           cost = 3,  name = "Schiene" },
	{ id = "morphine",         cost = 5,  name = "Morphin" },
	{ id = "epinephrine",      cost = 5,  name = "Adrenalin" },
	{ id = "adenosine",        cost = 5,  name = "Adenosin" },
	{ id = "painkillers",      cost = 2,  name = "Schmerzmittel" },
	{ id = "iv_saline",        cost = 5,  name = "Kochsalz-Infusion" },
	{ id = "iv_saline_500",    cost = 4,  name = "Kochsalz-Infusion 500ml" },
	{ id = "iv_saline_250",    cost = 3,  name = "Kochsalz-Infusion 250ml" },
	{ id = "iv_plasma",        cost = 7,  name = "Plasma-Infusion" },
	{ id = "iv_plasma_500",    cost = 6,  name = "Plasma-Infusion 500ml" },
	{ id = "iv_plasma_250",    cost = 4,  name = "Plasma-Infusion 250ml" },
	{ id = "iv_blood",         cost = 9,  name = "Bluttransfusion" },
	{ id = "iv_blood_500",     cost = 7,  name = "Bluttransfusion 500ml" },
	{ id = "iv_blood_250",     cost = 5,  name = "Bluttransfusion 250ml" },
	{ id = "surgical_kit",     cost = 12, name = "Chirurgisches Besteck" },
	{ id = "pak",              cost = 15, name = "Erste-Hilfe-Paket" },
}

VN_MED = VN_MED or {}
VN_MED.Prefix = "kms_"

local registered = false

local function Label(entry)
	local kms = KrakensMedical
	if not kms or not kms.ItemLabel then return entry.name end

	local ok, label = pcall(kms.ItemLabel, entry.id)
	-- Fehlt die Übersetzung, liefert KMS den Schlüssel selbst zurück.
	if ok and isstring(label) and label ~= "" and label ~= "item_" .. entry.id then
		return label
	end

	return entry.name
end

function VN_MED.Register()
	local kms = KrakensMedical
	if registered or not kms or not kms.ItemById then return end
	if not VN_INV or not VN_INV.Register then return end

	local count = 0
	for _, entry in ipairs(MEDICAL) do
		if kms.ItemById[entry.id] then
			count = count + 1
			VN_INV.Register(VN_MED.Prefix .. entry.id, {
				name = Label(entry),
				desc = "Sanitätsmaterial",
				category = "Medic",
				crate = "medic",
				cost = entry.cost,
				maxStack = 1,
				kmsItem = entry.id,
			})
		end
	end

	registered = count > 0
end

hook.Add("KrakensMedical.Loaded", "vn_med_register", VN_MED.Register)
hook.Add("InitPostEntity", "vn_med_register", VN_MED.Register)

-- Läuft dieses Addon nach KMS, ist der Loaded-Hook schon durch.
VN_MED.Register()

if not SERVER then return end

-- Die Kiste ruft VN_INV.GiveItem auf. Sanitätsartikel werden hier abgefangen
-- und ins KMS-Inventar umgeleitet, statt im VN-Inventar zu landen; der Rest
-- geht unverändert an die ursprüngliche Funktion.
-- VN_INV.GiveItem lives in autorun/server and may not exist yet when this file
-- runs, so the wrap is attempted both now and once everything is loaded.
function VN_MED.Bridge()
	if VN_MED.bridged or not VN_INV or not VN_INV.GiveItem then return end
	VN_MED.bridged = true

	local giveToInventory = VN_INV.GiveItem

	function VN_INV.GiveItem(ply, id, count)
		local item = VN_INV.Get(id)
		if not item or not item.kmsItem then
			return giveToInventory(ply, id, count)
		end

		local kms = KrakensMedical
		if not kms or not kms.GiveItem then
			return false, "Das Medizinsystem ist nicht geladen."
		end

		if kms.Settings and kms.Settings.infiniteSupplies then
			return false, "Sanitätsmaterial ist unbegrenzt verfügbar."
		end

		kms.GiveItem(ply, item.kmsItem)
		return true
	end
end

hook.Add("InitPostEntity", "vn_med_bridge", VN_MED.Bridge)
VN_MED.Bridge()
