local E, L, V, P, G, _  = unpack(ElvUI); --Inport: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local UF = E:GetModule('UnitFrames');
local DebuffsAlert = E:GetModule('DebuffsAlert');

function DebuffsAlert:Construct_DebuffHighlight(frame)
	if not E.db.DebuffsAlert.enable then return end
	local dbh = frame.Health
	frame.DebuffHighlightFilter = true
	frame.DebuffHighlightAlpha = 0
	frame.DebuffHighlightFilterTable = E.db.DebuffsAlert.DA_filter
	return dbh
end

function DebuffsAlert:Configure_DebuffHighlight(frame)
	if not E.db.DebuffsAlert.enable then return end
	if E.db.unitframe.debuffHighlighting ~= 'NONE' then
		frame:EnableElement('DebuffHighlight')
		frame.DebuffHighlightFilterTable = E.db.DebuffsAlert.DA_filter
		frame.DebuffHighlightBackdrop = false
	else
		frame:DisableElement('DebuffHighlight')
	end
end

hooksecurefunc(UF, "Construct_DebuffHighlight", DebuffsAlert.Construct_DebuffHighlight)
hooksecurefunc(UF, "Configure_DebuffHighlight", DebuffsAlert.Configure_DebuffHighlight)