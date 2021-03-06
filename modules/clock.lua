
----------------------------------
-- module independent variables --
----------------------------------
local addon, ns = ...
local C, L, I = ns.LC.color, ns.L, ns.I
L.Clock = TIMEMANAGER_TITLE;


-----------------------------------------------------------
-- module own local variables and local cached functions --
-----------------------------------------------------------
local name = "Clock";
local ldbName,ttName = name,name.."TT"
local GetGameTime = GetGameTime
local tt,GetGameTime2,createMenu
local countries = {}
local played = false
local clock_diff = nil

-------------------------------------------
-- register icon names and default files --
-------------------------------------------
I[name] = {iconfile="Interface\\Addons\\"..addon.."\\media\\clock"}; --IconName::Clock--


---------------------------------------
-- module variables for registration --
---------------------------------------
ns.modules[name] = {
	desc = L["Broker to show local and/or realm time"],
	events = {"TIME_PLAYED_MSG"},
	updateinterval = 1,
	timeout = 30,
	timeoutAfterEvent = "PLAYER_ENTERING_WORLD",
	config_defaults = {
		format24 = true,
		timeLocal = true,
		showSeconds = false
	},
	config_allowed = {
	},
	config = {
		{ type="header", label=TIMEMANAGER_TITLE, align="left", icon=I[name] },
		{ type="separator" },
		{ type="toggle",name="format24", label=TIMEMANAGER_24HOURMODE, tooltip=L["Switch between time format 24 hours and 12 hours with AM/PM"] },
		{ type="toggle", name="timeLocal", label=L["Local or realm time"], tooltip=L["Switch between local and realm time in broker button"] },
		{ type="toggle", name="showSeconds", label=L["Show seconds"], tooltip=L["Display the time with seconds in broker button and tooltip"] }
	},
	clickOptions = {
		["1_timemanager"] = {
			cfg_label = "Open time manager", -- L["Open time manager"]
			cfg_desc = "open the time manager", -- L["open the time manager"]
			cfg_default = "_LEFT",
			hint = "Open time manager", -- L["Open time manager"]
			func = function(self,button)
				local _mod=name;
				securecall("ToggleTimeManager");
			end
		},
		["2_toggle_time"] = {
			cfg_label = "Local or realm time", -- L["Local or realm time"]
			cfg_desc = "switch between local and realm time", -- L["switch between local and realm time"]
			cfg_default = "_RIGHT",
			hint = "Local or realm time",
			func = function(self,button)
				local _mod=name;
				ns.profile[name].timeLocal = not ns.profile[name].timeLocal;
				ns.modules[name].onupdate(self)
			end
		},
		["3_calendar"] = {
			cfg_label = "Open calendar", -- L["Open calendar"]
			cfg_desc = "open the calendar", -- L["open the calendar"]
			cfg_default = "SHIFTRIGHT",
			hint = "Open calendar",
			func = function(self,button)
				local _mod=name;
				securecall("ToggleCalendar");
			end
		},
		["4_hours_mode"] = {
			cfg_label = "12 / 24 hours mode", -- L["12 / 24 hours mode"]
			cfg_desc = "switch between 12 and 24 time format", -- L["switch between 12 and 24 time format"]
			cfg_default = "SHIFTLEFT",
			hint = "12 / 24 hours mode",
			func = function(self,button)
				local _mod=name;
				ns.profile[name].format24 = not ns.profile[name].format24;
				ns.modules[name].onupdate(self)
			end
		},
		["5_open_menu"] = {
			cfg_label = "Open option menu", -- L["Open option menu"]
			cfg_desc = "open the option menu", -- L["open the option menu"]
			cfg_default = "_RIGHT",
			hint = "Open option menu", -- L["Open option menu"]
			func = function(self,button)
				local _mod=name; -- for error tracking
				createMenu(self);
			end
		},
		-- open blizzards stopwatch?
	}
}


--------------------------
-- some local functions --
--------------------------
function createMenu(self)
	if (tt~=nil) then ns.hideTooltip(tt,ttName,true); end
	ns.EasyMenu.InitializeMenu();
	ns.EasyMenu.addConfigElements(name);
	ns.EasyMenu.ShowMenu(self);
end

local function createTooltip(self, tt)
	local h24 = ns.profile[name].format24
	local dSec = ns.profile[name].showSeconds
	local pT,pL,pS = ns.LT.GetPlayedTime()

	tt:Clear()
	tt:AddHeader(C("dkyellow",TIMEMANAGER_TITLE))
	tt:AddSeparator()

	tt:AddLine(C("ltyellow",L["Local time"]),	C("white",ns.LT.GetTimeString("GetLocalTime",h24,dSec)))
	tt:AddLine(C("ltyellow",L["Realm time"]),	C("white",ns.LT.GetTimeString("GetGameTime",h24,dSec)))
	tt:AddLine(C("ltyellow",L["UTC time"]),		C("white",ns.LT.GetTimeString("GetUTCTime",h24,dSec)))

	tt:AddSeparator(3,0,0,0,0)

	tt:AddLine(C("ltblue",L["Playtime"]))
	tt:AddSeparator()
	tt:AddLine(C("ltyellow",TOTAL),C("white",SecondsToTime(pT)))
	tt:AddLine(C("ltyellow",LEVEL),C("white",SecondsToTime(pL)))
	tt:AddLine(C("ltyellow",L["Session"]),C("white",SecondsToTime(pS)))

	if ns.profile.GeneralOptions.showHints then
		tt:AddSeparator(3,0,0,0,0)
		ns.clickOptions.ttAddHints(tt,name);
	end
	ns.roundupTooltip(self,tt)
end


------------------------------------
-- module (BE internal) functions --
------------------------------------
ns.modules[name].init = function(obj)
	ldbName = (ns.profile.GeneralOptions.usePrefix and "BE.." or "")..name
end

ns.modules[name].onevent = function(self,event,...)
	if event=="TIME_PLAYED_MSG" then
		played = true
	end
	if (event=="BE_UPDATE_CLICKOPTIONS") then
		ns.clickOptions.update(ns.modules[name],ns.profile[name]);
	end
end

-- ns.modules[name].optionspanel = function(panel) end
-- ns.modules[name].onmousewheel = function(self,direction) end

ns.modules[name].onupdate = function(self)
	if not self then self = {} end
	self.obj = self.obj or ns.LDB:GetDataObjectByName(ldbName)

	local h24 = ns.profile[name].format24
	local dSec = ns.profile[name].showSeconds

	self.obj.text = ns.profile[name].timeLocal and ns.LT.GetTimeString("GetLocalTime",h24,dSec) or ns.LT.GetTimeString("GetGameTime",h24,dSec)

	if tt~=nil and tt.key==name.."TT" and tt:IsShown() then
		createTooltip(false, tt)
	end
end

ns.modules[name].ontimeout = function(self)
	if played==false then
		--RequestTimePlayed()
	end
end

ns.modules[name].ontooltip = function(tt)
	if (not tt.key) or tt.key~=ttName then return end -- don't override other LibQTip tooltips...
	ns.tooltipScaling(tt)
	local h24 = ns.profile[name].format24
	local dSec = ns.profile[name].showSeconds
	tt:ClearLines()

	tt:AddLine(TIMEMANAGER_TITLE)
	tt:AddLine(" ")

	tt:AddDoubleLine(C("white",L["Local time"]), C("white",ns.LT.GetTimeString("GetLocalTime",h24,dSec)))
	tt:AddDoubleLine(C("white",L["Realm time"]), C("white",ns.LT.GetTimeString("GetGameTime",h24,dSec)))

	if ns.profile.GeneralOptions.showHints then
		tt:AddLine(" ")
		ns.clickOptions.ttAddHints(tt,name);
	end
end


-------------------------------------------
-- module functions for LDB registration --
-------------------------------------------
ns.modules[name].onenter = function(self)
	if (ns.tooltipChkOnShowModifier(false)) then return; end
	tt = ns.LQT:Acquire(ttName, 2 , "LEFT", "RIGHT" )
	createTooltip(self, tt)
end

ns.modules[name].onleave = function(self)
	if (tt) then ns.hideTooltip(tt,ttName,true); end
	if (tt2) then ns.hideTooltip(tt2,ttName2,true); end
end

-- ns.modules[name].ondblclick = function(self,button) end

