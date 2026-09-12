-- VN Logistics - shared configuration for supply requests and deliveries.

if SERVER then AddCSLuaFile() end

VN_LOG = VN_LOG or {}

VN_LOG.MaxSupply = 150      -- Wie viel Vorrat eine Kiste fassen kann
VN_LOG.StartSupply = 60     -- Vorrat einer frisch gespawnten Kiste
VN_LOG.PackageSize = 50     -- Vorrat pro Lieferung
VN_LOG.DeliveryTime = 25    -- Sekunden bis eine Lieferung ankommt
VN_LOG.RequestCooldown = 30 -- Sekunden zwischen zwei Anforderungen pro Kiste

-- Jobs/Teams, die das Datapad benutzen dürfen. Verglichen wird der Teamname in
-- Kleinbuchstaben auf Teilstring, "navy" trifft also auch "Navy Ensign".
VN_LOG.AllowedTeams = {
	"navy",
	"logistik",
	"logistics",
	"quartermaster",
}

function VN_LOG.IsLogistics(ply)
	if not IsValid(ply) then return false end
	if ply:IsAdmin() then return true end

	local ok, name = pcall(team.GetName, ply:Team())
	if not ok or not name then return false end

	name = string.lower(name)
	for _, allowed in ipairs(VN_LOG.AllowedTeams) do
		if string.find(name, allowed, 1, true) then return true end
	end

	return false
end
