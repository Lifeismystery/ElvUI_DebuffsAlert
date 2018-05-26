local E, L, V, P, G, _  = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local DebuffsAlert = E:NewModule('DebuffsAlert', 'AceHook-3.0', 'AceEvent-3.0', 'AceTimer-3.0');
local UF = E:GetModule('UnitFrames');
local EP = LibStub("LibElvUIPlugin-1.0") --We can use this to automatically insert our GUI tables when ElvUI_Config is loaded.
local addon, ns = ...

local _G = _G
local selectedSpell 
local type = type
local pairs = pairs
local tonumber = tonumber
local tostring = tostring
local match = string.match
local format = string.format
local COLOR = COLOR
local GetSpellInfo = GetSpellInfo
local filters = {}
local enableReset = false
DebuffsAlert.version = GetAddOnMetadata("ElvUI_DebuffsAlert", "Version")
DebuffsAlert.versionMinE = 10.70
DebuffsAlert.title = '|cff1783d1DebuffsAlert|r'

--Default options
P['DebuffsAlert'] = {
	['enabled'] = true,
	["default_color"] = {r = 0.5,g = 0,b = 0},
	['DA_filter'] = {}
}

local function 	DA_filter_update()
	if E.db.DebuffsAlert.DA_filter then
		for spellID, values in pairs(E.db.DebuffsAlert.DA_filter) do 
			if values.use_color == false or nil then 
				values.color.r = E.db.DebuffsAlert['default_color'].r
				values.color.g = E.db.DebuffsAlert['default_color'].g
				values.color.b = E.db.DebuffsAlert['default_color'].b
			end
		end
	end
end

local function UpdateFilterGroup()
	--Prevent errors when choosing a new filter, by doing a reset of the groups
	E.Options.args.DebuffsAlert.args.filterGroup = nil
	E.Options.args.DebuffsAlert.args.resetGroup = nil
	
	E.Options.args.DebuffsAlert = {
		order = 101,
		type = 'group',
		name = DebuffsAlert.title,
		args = {
			header = {
				order = 1,
				type = "header",
				name = format(L["%s version %s by Lifeismystery"], DebuffsAlert.title, DebuffsAlert.version),
			},	
			spacer = {
				order = 2,
				type = "description",
				name = "",
			},			
			desc = {
				order = 3,
				type = 'description',
				name = L["Color the unit healthbar if there is a debuff from this filter"],
			},
			spacer = {
				order = 4,
				type = "description",
				name = "",
			},
			enable = {
				order = 5,
				type = "toggle",
				name = L["Enable"],
				get = function(info) return E.db.DebuffsAlert.enable end,
				set = function(info, value) E.db.DebuffsAlert.enable = value 
				end,
			},
			default_color = {
				order = 6,
				type = 'color',
				name = L["Default Color"],
				hasAlpha = false,
				get = function(info)
					local t = E.db.DebuffsAlert.default_color
					local d = P.DebuffsAlert.default_color
					return t.r, t.g, t.b, t.a, d.r, d.g, d.b
				end,
				set = function(info, r, g, b)
					local t = E.db.DebuffsAlert.default_color
					t.r, t.g, t.b = r, g, b
					DA_filter_update();
					UF:Update_AllFrames();
				end,
			},
			filterGroup = {
				order = 7,
				type = 'group',
				name = L["Filters Page"],
				guiInline = true,
				disabled = function() return not E.db.DebuffsAlert.enable end,
				get = function(info) return E.db.DebuffsAlert.DA_filter[ info[#info] ] end,
				set = function(info, value) E.db.DebuffsAlert.DA_filter[ info[#info] ] = value end,
				args = {
					addSpell = {
						order = 1,
						name = L["Add Spell ID or Name"],
						desc = L["Add a spell to the filter. Use spell ID if you don't want to match all auras which share the same name."],
						type = 'input',
						get = function(info) return "" end,
						set = function(info, value)
							if tonumber(value) then value = tonumber(value) end
							E.db.DebuffsAlert.DA_filter[value] = {enable = true, use_color = true, color = {r = 0.8, g = 0, b = 0}};
							selectedSpell = value;
					end,
					},
					removeSpell = {
						order = 2,
						name = L["Remove Spell ID or Name"],
						desc = L["Remove a spell from the filter. Use the spell ID if you see the ID as part of the spell name in the filter."],
						type = 'input',
						get = function(info) return "" end,
						set = function(info, value)
							if tonumber(value) then value = tonumber(value) end
							E.db.DebuffsAlert.DA_filter[value] = nil;
							selectedSpell = nil;
							UF:Update_AllFrames();
					end,
					},
					selectSpell = {
						name = L["Select Spell"],
						type = 'select',
						order = 10,
						width = "double",
						get = function(info) return selectedSpell end,
						set = function(info, value) selectedSpell = value; 
						UpdateFilterGroup(); 
						end,
						values = function() 
							for filter in pairs(E.db.DebuffsAlert.DA_filter) do
								if tonumber(filter) then
									local spellName = GetSpellInfo(filter)
									if spellName then
										filter = format("%s (%s)", spellName, filter)
									else
										filter = tostring(filter)
									end
								end
								filters[filter] = filter
							end
							return filters
							
						end,
					},
				},	
			},	
			resetGroup = {
				type = "group",
				name = L["Reset Filter"],
				order = 25,
				guiInline = true,
				args = {
					enableReset = {
						order = 1,
						type = "toggle",
						name = L["Enable"],
						get = function(info) return enableReset end,
						set = function(info, value) enableReset = value; end,
					},
					resetFilter = {
						order = 2,
						type = "execute",
						buttonElvUI = true,
						name = L["Reset Filter"],
						desc = L["This will reset the contents of this filter back to default. Any spell you have added to this filter will be removed."],
						disabled = function() return not enableReset end,
						func = function(info)
							E.db.DebuffsAlert.DA_filter = {};
							selectedSpell = nil;
							enableReset = false;
							UpdateFilterGroup();
							UF:Update_AllFrames();
						end,
					},
					},
				}
		}	
	}

	local spellID = selectedSpell and match(selectedSpell, "(%d+)")
	if spellID then spellID = tonumber(spellID) end
	
	if not selectedSpell or E.db.DebuffsAlert.DA_filter[(spellID or selectedSpell)] == nil then
		E.Options.args.DebuffsAlert.args.filterGroup.args.spellGroup = nil
		return
	end

	E.Options.args.DebuffsAlert.args.filterGroup.args.spellGroup = {
		order = 15,
		type = 'group',
		name = tostring(selectedSpell),
		guiInline = true,
		args = {
			enabled = {
				order = 0,
				type = "toggle",
				name = L["Enable"],
				get = function(info) 
					return E.db.DebuffsAlert.DA_filter[(spellID or selectedSpell)].enable 
				end,
				set = function(info, value)
					E.db.DebuffsAlert.DA_filter[(spellID or selectedSpell)].enable = value
					UF:Update_AllFrames();
				end,
			},
			color = {
				order = 2,
				type = 'color',
				name = COLOR,
				hasAlpha = false,
				visible=false,
				disabled = function() return not E.db.DebuffsAlert.DA_filter[(spellID or selectedSpell)].use_color end,
				get = function(info)
						local t = E.db.DebuffsAlert.DA_filter[(spellID or selectedSpell)].color
						return t.r, t.g, t.b
				end,
				set = function(info, r, g, b)
					local t = E.db.DebuffsAlert.DA_filter[(spellID or selectedSpell)].color
					t.r, t.g, t.b = r, g, b
					UF:Update_AllFrames();
			end,
			},
			use_color = {
				name = L["Enable"],
				order = 1,
				type = "toggle",
				name = L["special color"],
				get = function(info) 
					return E.db.DebuffsAlert.DA_filter[(spellID or selectedSpell)].use_color 
				end,
				set = function(info, value)
					E.db.DebuffsAlert.DA_filter[(spellID or selectedSpell)].use_color = value
					DA_filter_update();
					UF:Update_AllFrames();
				end,
			}
		}
	}	

	UF:Update_AllFrames();
end

function DebuffsAlert:InsertOptions()
	
	E.Options.args.DebuffsAlert = {
		order = 101,
		type = 'group',
		name = DebuffsAlert.title,
		args = {
			header = {
				order = 1,
				type = "header",
				name = format(L["%s version %s by Lifeismystery"], DebuffsAlert.title, DebuffsAlert.version),
			},
			spacer = {
				order = 2,
				type = "description",
				name = "",
			},			
			desc = {
				order = 3,
				type = 'description',
				name = L["Color the unit healthbar if there is a debuff from this filter"],
			},
			spacer = {
				order = 4,
				type = "description",
				name = "",
			},
			enable = {
				order = 4,
				type = "toggle",
				name = L["Enable"],
				get = function(info) return E.db.DebuffsAlert.enable end,
				set = function(info, value) E.db.DebuffsAlert.enable = value;
				UF:Update_AllFrames();
				end,
			},
			default_color = {
				order = 6,
				type = 'color',
				name = L["Default Color"],
				hasAlpha = false,
				get = function(info)
					local t = E.db.DebuffsAlert.default_color
					local d = P.DebuffsAlert.default_color
					return t.r, t.g, t.b, t.a, d.r, d.g, d.b
				end,
				set = function(info, r, g, b)
					E.db.DebuffsAlert.default_color = {}
					local t = E.db.DebuffsAlert.default_color
					t.r, t.g, t.b = r, g, b
					DA_filter_update();
					UpdateFilterGroup();
				end,
			},
			filterGroup = {
				order = 7,
				type = 'group',
				name = L["Filters Page"],
				guiInline = true,
				disabled = function() return not E.db.DebuffsAlert.enable end,
				get = function(info) return E.db.DebuffsAlert.DA_filter[ info[#info] ] end,
				set = function(info, value) E.db.DebuffsAlert.DA_filter[ info[#info] ] = value end,
				args = {
					addSpell = {
						order = 1,
						name = L["Add Spell ID or Name"],
						desc = L["Add a spell to the filter. Use spell ID if you don't want to match all auras which share the same name."],
						type = 'input',
						get = function(info) return "" end,
						set = function(info, value)
							if tonumber(value) then value = tonumber(value) end
							E.db.DebuffsAlert.DA_filter[value] = {enable = true, use_color = false, color = {r = 0.8, g = 0, b = 0}}
							selectedSpell = value;
							UpdateFilterGroup();
					end,
					},
					removeSpell = {
						order = 2,
						name = L["Remove Spell ID or Name"],
						desc = L["Remove a spell from the filter. Use the spell ID if you see the ID as part of the spell name in the filter."],
						type = 'input',
						get = function(info) return "" end,
						set = function(info, value)
							if tonumber(value) then value = tonumber(value) end
							E.db.DebuffsAlert.DA_filter[value] = nil;
							selectedSpell = nil;
							UpdateFilterGroup();
					end,
					},
					selectSpell = {
						name = L["Select Spell"],
						type = 'select',
						order = 3,
						width = "double",
						get = function(info) return selectedSpell end,
						set = function(info, value) selectedSpell = value; 
						UpdateFilterGroup() 
						end,
						values = function()
							for filter in pairs(E.db.DebuffsAlert.DA_filter) do
								if tonumber(filter) then
									local spellName = GetSpellInfo(filter)
									if spellName then
										filter = format("%s (%s)", spellName, filter)
									else
										filter = tostring(filter)
									end
								end
								filters[filter] = filter
							end
							return filters
						end,
					},
				},	
			},
			resetGroup = {
			type = "group",
			name = L["Reset Filter"],
			order = 25,
			guiInline = true,
			args = {
				enableReset = {
					order = 1,
					type = "toggle",
					name = L["Enable"],
					get = function(info) return enableReset end,
					set = function(info, value) enableReset = value; end,
				},
				resetFilter = {
					order = 2,
					type = "execute",
					buttonElvUI = true,
					name = L["Reset Filter"],
					desc = L["This will reset the contents of this filter back to default. Any spell you have added to this filter will be removed."],
					disabled = function() return not enableReset end,
					func = function(info)
						E.db.DebuffsAlert.DA_filter = {};
						selectedSpell = nil;
						enableReset = false;
						UpdateFilterGroup();
						UF:Update_AllFrames();
					end,
				},
				},
			}
		}	
	}
	
	local spellID = selectedSpell and match(selectedSpell, "(%d+)")
	if spellID then spellID = tonumber(spellID) end
	
	if not selectedSpell or E.db.DebuffsAlert.DA_filter[(spellID or selectedSpell)] == nil then
		E.Options.args.DebuffsAlert.args.filterGroup.args.spellGroup = nil
		return
	end
	
	E.Options.args.DebuffsAlert.args.filterGroup.args.spellGroup = {
		order = 15,
		type = 'group',
		name = tostring(selectedSpell),
		guiInline = true,
		args = {
			enabled = {
				order = 0,
				type = "toggle",
				name = L["Enable"],
				get = function(info) 
					return E.db.DebuffsAlert.DA_filter[(spellID or selectedSpell)].enable 
				end,
				set = function(info, value)
					E.db.DebuffsAlert.DA_filter[(spellID or selectedSpell)].enable = value
					UpdateFilterGroup();
					UF:Update_AllFrames();
				end,
			},
			color = {
				order = 2,
				type = 'color',
				name = COLOR,
				visible=false,
				hasAlpha = false,
				disabled = function() return not E.db.DebuffsAlert.DA_filter[(spellID or selectedSpell)].use_color end,
				get = function(info)
					local t = E.db.DebuffsAlert.DA_filter[(spellID or selectedSpell)].color
					return t.r, t.g, t.b
				end,
				set = function(info, r, g, b)
					local t = E.db.DebuffsAlert.DA_filter[(spellID or selectedSpell)].color
					t.r, t.g, t.b = r, g, b
					UpdateFilterGroup();
			end,
			},
			use_color = {
				name = L["Enable"],
				order = 1,
				type = "toggle",
				name = L["use special color"],
				get = function(info) 
					return E.db.DebuffsAlert.DA_filter[(spellID or selectedSpell)].use_color 
				end,
				set = function(info, value)
					E.db.DebuffsAlert.DA_filter[(spellID or selectedSpell)].use_color = value
					DA_filter_update();
					UpdateFilterGroup();
				end,
			}
		}
	}
	
	if not DebuffsAlert.initialized or not E.private.unitframe.enable then return end
	if not E.db.DebuffsAlert.enable then return end
end

function DebuffsAlert:Initialize()
	--Register plugin so options are properly inserted when config is loaded
	EP:RegisterPlugin(addon, DebuffsAlert.InsertOptions)
end

E:RegisterModule(DebuffsAlert:GetName()) --Register the module with ElvUI. ElvUI will now call DebuffsAlert:Initialize() when ElvUI is ready to load our plugin.