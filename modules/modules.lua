local addon, ns = ...;
local L = ns.L;

-- ------------------------------- --
-- modules table and init function --
-- ~Hizuro                         --
-- ------------------------------- --
ns.modules = {};
ns.updateList = {};
ns.timeoutList = {};
local counters = {};

local function moduleInit(name)
	local ldbName = (ns.profile.GeneralOptions.usePrefix and "BE.." or "")..name;
	local data = ns.modules[name];

	-- module load on demand like
	if (data.enabled==nil) then
		data.enabled = true;
	end

	-- check if savedvariables for module present?
	if (ns.profile[name]==nil) then
		ns.profile[name] = {enabled = data.enabled};
	elseif (type(ns.profile[name].enabled)~="boolean") then
		ns.profile[name].enabled = data.enabled;
	end

	if (data.config_defaults) then
		for i,v in pairs(data.config_defaults) do
			if (ns.profile[name][i]==nil) then
				ns.profile[name][i] = v;
			elseif (data.config_allowed~=nil) and (data.config_allowed[i]~=nil) then
				if (data.config_allowed[i][ns.profile[name][i]]~=true) then
					ns.profile[name][i] = v;
				end
			end
		end
	end

	-- force enabled status of non Broker modules.
	if (data.noBroker) then
		data.enabled = true;
		ns.profile[name].enabled = true;
	end

	if (ns.profile[name].enabled==true) then
		local onclick;

		-- pre LDB init
		if data.init then
			data.init();
		end

		-- new clickOptions system
		if (type(data.clickOptions)=="table") then
			local active = ns.clickOptions.update(data,ns.profile[name]);
			if (active) then
				onclick = function(self,button) ns.clickOptions.func(name,self,button); end;
			end
		elseif (type(data.onclick)=="function") then
			onclick = data.onclick;
		end

		-- LDB init
		if (not data.noBroker) then
			if (not data.onenter) and data.ontooltip then
				data.ontooltipshow = data.ontooltip;
			end

			local icon = ns.I(name .. (data.icon_suffix or ""));
			local iColor = ns.profile.GeneralOptions.iconcolor;
			data.obj = ns.LDB:NewDataObject(ldbName, {

				-- button data
				type          = "data source",
				label         = data.label or L[name],
				text          = data.text or L[name],
				icon          = icon.iconfile, -- default or custom icon
				staticIcon    = icon.iconfile, -- default icon only
				iconCoords    = icon.coords or {0, 1, 0, 1},

				-- button event functions
				OnEnter       = data.onenter or nil,
				OnLeave       = data.onleave or nil,
				OnClick       = onclick,
				OnTooltipShow = data.ontooltipshow or nil
			})

			ns.updateIconColor(name);

			if (ns.profile.GeneralOptions.libdbicon) then
				if (ns.profile[name].dbi==nil) then
					ns.profile[name].dbi = {};
				end
				data.dbi = ns.LDBI:Register(ldbName,data.obj,ns.profile[name].dbi);
			end
		end

		-- event/update handling
		if (data.onevent) or (data.onupdate) then
			data.eventFrame=CreateFrame("Frame");
			data.eventFrame.modName = name;

			if (type(data.onevent)=="function") then
				data.eventFrame:SetScript("OnEvent",data.onevent);
				for _, e in pairs(data.events) do
					if (e=="ADDON_LOADED") then
						data.onevent(data.eventFrame,e,addon);
					else
						data.eventFrame:RegisterEvent(e);
					end
				end
			end

			if (type(data.onupdate)=="function") and (data.updateinterval~=nil) then
				counters[name]=false;
				data.eventFrame:SetScript("OnUpdate",function(self,elapse)
					if (self.elapsed==nil) then
						self.elapsed=0;
					end
					if (counters[name]==false) then
						counters[name]=0;
					end
					if (data.updateinterval == false) then
						counters[name]=counters[name]+1;
						data.onupdate(self,elapse);
					elseif (self.elapsed>=data.updateinterval) then
						self.elapsed = 0;
						counters[name]=counters[name]+1;
						data.onupdate(self,elapse);
					else
						self.elapsed = self.elapsed + elapse;
					end
				end);
			end
		end

		-- timeout function
		if (type(data.ontimeout)=="function") and (type(data.timeout)=="number") and (data.timeout>0) then
			if (data.afterEvent) then
				C_Timer.After(data.timeout,data.ontimeout);
			else
				C_Timer.After(data.timeout,data.ontimeout);
			end
		end

		-- post LDB init
		if (data.init) then
			data.init(data);
		end

		-- chat command registration
		if (data.chatcommands) then
			for i,v in pairs(data.chatcommands) do
				if (type(i)=="string") and (ns.commands[i]==nil) then -- prevents overriding
					ns.commands[i] = v;
				end
			end
		end

		data.init = nil;
	end

end

ns.moduleInit = function(name)
	if (name) then
		moduleInit(name);
	else
		local i=0;
		for name, data in pairs(ns.modules) do
			moduleInit(name);
			i=i+1;
		end
	end
end

ns.moduleCoexist = function()
	for name,data in pairs(ns.modules) do
		if (type(data.coexist)=="function") then
			data.coexist();
		end
	end
end

--[[
function PrintCounters()
	local x = {};
	for i, v in pairs(counters)do
		tinsert(x,("[%s:%s]"):format(i,tostring(v)));
	end
	ns.print("counters",table.concat(x,", "));
end
--]]