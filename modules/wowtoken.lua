
----------------------------------
-- module independent variables --
----------------------------------
local addon, ns = ...
local C, L, I = ns.LC.color, ns.L, ns.I


-----------------------------------------------------------
-- module own local variables and local cached functions --
-----------------------------------------------------------
local name = "WoWToken";
local ldbName, ttName = name, name.."TT";
local tt,_,icon = nil;
local ttColumns = 1;
local price = {last=0,money=0,diff=0};


-------------------------------------------
-- register icon names and default files --
-------------------------------------------
I[name] = {iconfile="Interface\\ICONS\\WoW_Token01",coords={0.05,0.95,0.05,0.95}}; --IconName::WoWToken--


---------------------------------------
-- module variables for registration --
---------------------------------------
ns.modules[name] = {
	desc = L["Broker to show current amount of gold for a WoW Token"],
	events = {
		"ADDON_LOADED",
		"PLAYER_ENTERING_WORLD",
		"TOKEN_MARKET_PRICE_UPDATED"
	},
	updateinterval = 120, -- false or integer
	config_defaults = {
		diff=true,
		history=true,
	},
	config_allowed = {},
	config = {
		{ type="header",                 label=L[name], align="left", icon=I[name] },
		{ type="toggle", name="diff",    label=L["Show difference"], tooltip=L["Show difference of last change in tooltip"]},
		{ type="toggle", name="history", label=L["Show history"],    tooltip=L["Show history of the 5 last changes in tooltip"]},
	}
}


--------------------------
-- some local functions --
--------------------------


------------------------------------
-- module (BE internal) functions --
------------------------------------
ns.modules[name].init = function(obj)
	ldbName = (ns.profile.GeneralOptions.usePrefix and "BE.." or "")..name
end

ns.modules[name].onevent = function(self,event,msg)
	if(event=="ADDON_LOADED" and msg==addon)then
		if Broker_Everything_DataDB[name]==nil then
			Broker_Everything_DataDB[name] = {};
		end
		if(#Broker_Everything_DataDB[name]>0 and Broker_Everything_DataDB[name][1].last<time()-(60*30))then
			wipe(Broker_Everything_DataDB[name]);
		end
		L[name] = GetItemInfo(122284);
	elseif(event=="PLAYER_ENTERING_WORLD")then
		L[name] = GetItemInfo(122284);
		C_WowTokenPublic.UpdateMarketPrice();
	elseif(event=="TOKEN_MARKET_PRICE_UPDATED")then

		if(#Broker_Everything_DataDB[name]==0 or (#Broker_Everything_DataDB[name]>0 and Broker_Everything_DataDB[name][1].money~=price.money))then
			tinsert(Broker_Everything_DataDB[name],1,{money=price.money,last=price.last});
			if(#Broker_Everything_DataDB[name]==7)then tremove(Broker_Everything_DataDB[name],7); end
		end

		local current = C_WowTokenPublic.GetCurrentMarketPrice();

		if(current)then
			if(current~=price.money)then
				local prev=price.money;
				price = {last=time(),money=current};
				if(prev>0)then
					price.diff=price.money-prev;
				end
			end

			local obj = ns.LDB:GetDataObjectByName(ldbName);
			obj.text = ns.GetCoinColorOrTextureString(name,current,{hideLowerZeros=true});
		end
	end
end

ns.modules[name].onupdate = function(self)
	C_WowTokenPublic.UpdateMarketPrice();
end

-- ns.modules[name].optionspanel = function(panel) end
-- ns.modules[name].onmousewheel = function(self,direction) end

ns.modules[name].ontooltip = function(tt)
	local l;
	--tt:AddHeader(C("dkyellow",L[name]));
	--tt:AddSeparator(4,0,0,0,0);
	tt:AddLine(L[name]);
	tt:AddLine(" ");
	if(price.last~=0)then
		tt:AddDoubleLine(
			C("ltblue",L["Current price:"]),
			ns.GetCoinColorOrTextureString(name,price.money,{hideLowerZeros=true})
		);
		tt:AddDoubleLine(
			C("ltblue",L["Last changed:"]),
			C("ltyellow",date("%Y-%m-%d %H:%M",price.last))
		);
		if(ns.profile[name].diff and price.diff)then
			local diff=0;
			if(price.diff<0)then
				diff = "- "..ns.GetCoinColorOrTextureString(name,-price.diff,{hideLowerZeros=true});
			else
				diff = ns.GetCoinColorOrTextureString(name,price.diff,{hideLowerZeros=true});
			end
			tt:AddDoubleLine(
				C("ltblue",L["Difference to previous:"]),
				diff
			);
		end
		if(ns.profile[name].history and #Broker_Everything_DataDB[name]>1)then
			tt:AddLine(" ");
			tt:AddLine(C("ltblue",L["Price history (last 5 changes)"]));
			for i,v in ipairs(Broker_Everything_DataDB[name])do
				if(i>1 and v.money>0)then
					tt:AddDoubleLine(date("%Y-%m-%d %H:%M",v.last),ns.GetCoinColorOrTextureString(name,v.money,{hideLowerZeros=true}));
				end
			end
		end
	else
		tt:AddLine(C("orange",L["Currently no price available..."]));
	end
end


-------------------------------------------
-- module functions for LDB registration --
-------------------------------------------
--ns.modules[name].onenter = function(self)
--	tt = ns.LQT:Acquire(ttName, ttColumns, "LEFT");
--	ns.modules[name].ontooltip(tt)
--	ns.roundupTooltip(self,tt);
--end

--ns.modules[name].onleave = function(self)
--	if (tt) then ns.hideTooltip(tt,ttName,false,true); end
--end

-- ns.modules[name].onclick = function(self,button) end
-- ns.modules[name].ondblclick = function(self,button) end

