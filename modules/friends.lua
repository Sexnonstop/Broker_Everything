
----------------------------------
-- module independent variables --
----------------------------------
local addon, ns = ...
local C, L, I = ns.LC.color, ns.L, ns.I


-----------------------------------------------------------
-- module own local variables and local cached functions --
-----------------------------------------------------------
local name = "Friends"; -- L["Friends"]
local ldbName,ttName,ttName2=name,name.."TT",name.."TT2";
local tt, tt2
local unknownGameError = false;
local DSw, DSh =  0,  0;
local ULx, ULy =  0,  0;
local LLx, LLy = 32, 32;
local URx, URy =  5, 27;
local LRx, LRy =  5, 27;
local ttColumns,createMenu;
local gameIconPos = setmetatable({},{ __index = function(t,k) return format("%s:%s:%s:%s:%s:%s:%s:%s:%s:%s",DSw,DSh,ULx,ULy,LLx,LLy,URx,URy,LRx,LRy) end})
local gameShortcut = setmetatable({ [BNET_CLIENT_WTCG] = "HS", [BNET_CLIENT_SC2] = "Sc2"},{ __index = function(t, k) return k end })
local _BNet_GetClientTexture = BNet_GetClientTexture
ns.friendlist = {};

-------------------------------------------
-- register icon names and default files --
-------------------------------------------
I[name] = {iconfile="Interface\\Addons\\"..addon.."\\media\\friends"}; --IconName::Friends--


---------------------------------------
-- module variables for registration --
---------------------------------------
ns.modules[name] = {
	desc = L["Broker to show you which friends are online on realm and BattleNet"],
	events = {
		"BATTLETAG_INVITE_SHOW",
		"BN_BLOCK_LIST_UPDATED",
		"BN_CONNECTED",
		"BN_CUSTOM_MESSAGE_CHANGED",
		"BN_CUSTOM_MESSAGE_LOADED",
		"BN_DISCONNECTED",
		"BN_FRIEND_ACCOUNT_OFFLINE",
		"BN_FRIEND_ACCOUNT_ONLINE",
		"BN_FRIEND_INFO_CHANGED",
		"BN_FRIEND_INVITE_ADDED",
		"BN_FRIEND_INVITE_REMOVED",
		"BN_INFO_CHANGED",
		"BN_SELF_ONLINE",
		"FRIENDLIST_UPDATE",
		"GROUP_ROSTER_UPDATE", --?
		"IGNORELIST_UPDATE",
		"PLAYER_ENTERING_WORLD",
		"PLAYER_FLAGS_CHANGED", --?
		"CHAT_MSG_SYSTEM"
	},
	updateinterval = nil, -- 10
	config_defaults = {
		splitFriends = true,
		splitFriendsTT = true,
		disableGameIcons = false,
		showBattleTags = true
	},
	config_allowed = {
	},
	config = {
		{ type="header", label=L[name], align="left", icon=I[name] },
		{ type="separator" },
		{ type="toggle", name="disableGameIcons", label=L["Disable game icons"], tooltip=L["Disable displaying game icons and use game shortcut instead of"] },
		{ type="toggle", name="splitFriends", label=L["Split friends on Broker"], tooltip=L["Split Characters and BattleNet-Friends on Broker Button"], event=true },
		{ type="toggle", name="splitFriendsTT", label=L["Split friends in Tooltip"], tooltip=L["Split Characters and BattleNet-Friends in Tooltip"], event=true },
		{ type="toggle", name="showBattleTags", label=L["Show BattleTags in tooltip"], tooltip=L["Show BattleTags in tooltip behind the realID"] }
	},
	clickOptions = {
		["1_open_character_info"] = {
			cfg_label = "Open friends roster", -- L["Open friends roster"]
			cfg_desc = "open the friends roster", -- L["open the friends roster"]
			cfg_default = "_LEFT",
			hint = "Open friends roster",
			func = function(self,button)
				local _mod=name;
				securecall("ToggleFriendsFrame",1);
			end
		},
		["2_open_menu"] = {
			cfg_label = "Open option menu",
			cfg_desc = "open the option menu",
			cfg_default = "_RIGHT",
			hint = "Open option menu",
			func = function(self,button)
				local _mod=name;
				createMenu(self)
			end
		}
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

local function BNet_GetClientTexture(game)
	if ns.profile[name].disableGameIcons then
		return gameShortcut[game]
	else
		local icon = _BNet_GetClientTexture(game)
		return format("|T%s:%s|t",icon,gameIconPos[game])
	end
end

local _status = function(afk,dnd)
	return (afk==true and C("gold","[AFK]")) or (dnd==true and C("ltred","[DND]")) or ""
end

local function broadcastTooltip(self)
	local broadcastText,broadcastTime = 13,14; -- BNGetFriendToonInfo
	if (self~=false) then
		local blue = C("ltblue","colortable");

		GameTooltip:SetOwner(self,"ANCHOR_NONE");
		if (select(1,self:GetCenter()) > (select(1,UIParent:GetWidth()) / 2)) then
			GameTooltip:SetPoint("RIGHT",tt,"LEFT",-2,0);
		else
			GameTooltip:SetPoint("LEFT",tt,"RIGHT",2,0);
		end
		GameTooltip:SetPoint("TOP",self,"TOP", 0, 4);

		GameTooltip:ClearLines();
		GameTooltip:AddLine(self.name,blue[1],blue[2],blue[3]);
		GameTooltip:AddLine(date("%Y-%m-%d %H:%M:%S",self.toonInfo[broadcastTime]),.7,.7,.7);
		GameTooltip:AddLine(SecondsToTime(time()-self.toonInfo[broadcastTime]),.7,.7,.7);
		GameTooltip:AddLine(self.toonInfo[broadcastText],1,1,1,true);
		GameTooltip:Show();
	else
		GameTooltip:Hide();
	end
end

local function createTooltip(self, tt)
	if tt and (not tt.key or tt.key~=ttName) then return end -- don't override other LibQTip tooltips...

	local columns,split,l,c=8,ns.profile[name].splitFriendsTT;
	local numChars, charsOnline = GetNumFriends();
	local numFriends, friendsOnline = BNGetNumFriends();

	tt:Clear()
	tt:AddHeader(C("dkyellow",L[name]))

	local _, _, _, broadcastText = BNGetInfo()
	if broadcastText~=nil and broadcastText~="" then
		tt:AddSeparator(4,0,0,0,0)
		line,column = tt:AddLine()
		tt:SetCell(line,1,C("dkyellow",L["My current broadcast message"]),nil,nil,columns)
		tt:AddSeparator()
		line,column = tt:AddLine()
		tt:SetCell(line,1,C("white",ns.scm(broadcastText,true)),nil,nil,columns)
	end

	if totalOnline == 0 then
		tt:AddSeparator(4,0,0,0,0)
		tt:AddLine(L["No friends online."])
		if ns.profile.GeneralOptions.showHints then
			line, column = tt:AddLine()
			tt:SetCell(line, 1, C("copper",L["Left-click"]).." "..C("green",L["Open friends roster"]), nil, nil, columns)
		end
		return
	end

	-- RealId	Status Character	Level	Zone	Game	Realm	Notes
	tt:AddSeparator(4,0,0,0,0)
	tt:AddLine(
		(split==true and C("ltblue",  BATTLENET_OPTIONS_LABEL)) or C("ltyellow",L["Real ID"].."/"..BATTLETAG), -- 1
		C("ltyellow",LEVEL),		-- 2
		C("ltyellow",CHARACTER),	-- 3
		C("ltyellow",GAME),		-- 4
		C("ltyellow",ZONE),		-- 5
		C("ltyellow",L["Realm"]),		-- 6
		C("ltyellow",FACTION),		-- 7
		C("ltyellow",L["Notes"])		-- 8
	)
	tt:AddSeparator()

	local presenceName,battleTag,isBattleTagPresence,isOnline,isAFK,isDND,noteText = 2,3,4,8,10,11,13; -- BNGetFriendInfo
	local toonName,client,realmName,faction,class,zoneName,level,gameText,broadcastText,broadcastTime,toonID = 2,3,4,6,8,10,11,12,13,14,16; -- BNGetFriendToonInfo (WoD 6.2.3) / BNGetFriendGameAccountInfo (WoD 6.2.4)
	local fi,nt,ti,l,c;
	local visible = {};
	if (friendsOnline>0) then
		for i=1, numFriends do
			if BNGetNumFriendGameAccounts then
				nt = BNGetNumFriendGameAccounts(i); -- WoD 6.2.4
			else
				nt = BNGetNumFriendToons(i); -- WoD 6.2.3
			end
			fi = {BNGetFriendInfo(i)};
			if (fi[isOnline]) then
				for I=1, nt do
					local bnName = fi[presenceName];
					if (ns.profile[name].showBattleTags) then
						bnName = bnName .. " ("..fi[battleTag]..")";
					end
					local ti = {};
					if BNGetFriendGameAccountInfo then
						ti = {BNGetFriendGameAccountInfo(i, I)}; -- WoD 6.2.4
					else
						ti = {BNGetFriendToonInfo(i, I)}; -- WoD 6.2.3
					end
					if visible[bnName..ti[client]..ti[zoneName]] then
						-- filter it...
					elseif (nt>1 and ti[client]~="App") or nt==1 then
						visible[bnName..ti[client]..ti[zoneName]] = true;
						if (not ti[toonName]) or (ti[client]=="Hero") then
							ti[toonName] = strsplit("#",fi[battleTag]);
						end 

						if (ti[client]=="WoW") then
							l,c = tt:AddLine(
								C("ltblue", ns.scm(bnName)) .. (ti[broadcastText]~="" and "|Tinterface\\chatframe\\ui-chatinput-focusicon:0|t" or ""), -- 1
								C("white",ti[level]),		-- 2
								_status(fi[isAFK],fi[isDND])..C(ti[class],ns.scm(ti[toonName])),	-- 3
								C("white", BNet_GetClientTexture(ti[client]) ),	-- 4
								C("white",ti[zoneName]~="" and ti[zoneName] or ti[gameText]),			-- 5
								C("white",ti[realmName]),			-- 6
								C("white",_G["FACTION_"..ti[faction]:upper()] or ti[faction]),		-- 7
								C("white",ns.scm(fi[noteText] or " ",true))	-- 8
							);
							ns.friendlist[ti[toonName].."-"..gsub(ti[realmName]," ","")] = 2;
						else
							l,c = tt:AddLine();
							tt:SetCell(l,1,C("ltblue", ns.scm(bnName)) .. (ti[broadcastText]~="" and "|Tinterface\\chatframe\\ui-chatinput-focusicon:0|t" or ""));
							tt:SetCell(l,2,C("white",ti[level]));
							tt:SetCell(l,3,_status(fi[isAFK],fi[isDND])..C(ti[class],ns.scm(ti[toonName])));
							tt:SetCell(l,4,C("white", BNet_GetClientTexture(ti[client]) ));
							tt:SetCell(l,5,C("white",C("white",ti[zoneName]~="" and ti[zoneName] or ti[gameText])),nil,nil,3); -- 5 6 7
							tt:SetCell(l,8,C("white",C("white",ns.scm(fi[noteText] or " ",true))));
						end

						tt.lines[l].bnName=bnName;
						tt.lines[l].toonInfo=ti;
						tt.lines[l].friendInfo=fi;

						tt:SetLineScript(l, "OnMouseUp", function(self)
							if (IsAltKeyDown()) then
								if (self.toonInfo[client]~="WoW") then return; end
								BNInviteFriend(self.toonInfo[toonID]);
							else
								ChatFrame_SendSmartTell(self.friendInfo[presenceName]);
							end
						end);
						tt:SetLineScript(l, "OnEnter", function(self)
							tt:SetLineColor(l, 1,192/255, 90/255, 0.3);
							if (self.toonInfo[broadcastText]~="") then broadcastTooltip(self); end
						end);
						tt:SetLineScript(l, "OnLeave", function()
							tt:SetLineColor(l, 0,0,0,0);
							broadcastTooltip(false);
						end);

						l,c=nil;
					end
				end
			end
		end
	elseif BNConnected()==false then
		tt:SetCell(tt:AddLine(),1,C("red",BATTLENET_UNAVAILABLE),nil,nil,ttColumns);
	end

	if (numChars > 0) then
		if (split) then
			tt:AddSeparator(4,0,0,0,0)
			tt:AddLine(
				C("yellow",  L["Characters"]),	-- 1
				C("ltyellow",LEVEL),		-- 2
				C("ltyellow",CHARACTER),	-- 3
				C("ltyellow",GAME),		-- 4
				C("ltyellow",ZONE),		-- 5
				C("ltyellow",L["Realm"]),		-- 6
				C("ltyellow",FACTION),		-- 7
				C("ltyellow",L["Notes"])		-- 8
			)
			tt:AddSeparator()
		end

		local charName,level,class,area,connected,status,note=1,2,3,4,5,6,7;
		local l,c,v,s,n,_;
		for i=1, numChars do
			v = {GetFriendInfo(i)};
			if visible[ns.realm..v[charName]..v[area]] then
				-- filter it...
			elseif (v[charName]) and (v[connected]) then
				visible[ns.realm..v[charName]..v[area]] = true;
				n = v[charName];
				s = ns.realm;
				if (v[charName]:find("-")) then
					n,s = strsplit("-",v[charName]);
					ns.friendlist[v[charName]] = 1;
				else
					ns.friendlist[n.."-"..gsub(s," ","")] = 1;
				end
				l,c = tt:AddLine(
					" ",
					C("white",v[level]),
					_status((status=="AFK"),(status=="DND")) .. C(v[class]:upper(),ns.scm(n)),
					C("white",BNet_GetClientTexture(BNET_CLIENT_WOW)),
					C("white",v[area]),
					C("white",s),
					C("white",ns.player.factionL or ns.player.faction),
					C("white",ns.scm(v[note] or ""))
				);
				tt.lines[l].friendInfo=v;
				tt:SetLineScript(l, "OnMouseUp", function(self) if (IsAltKeyDown()) then InviteUnit(self.friendInfo[charName]); else ChatFrame_SendTell(self.friendInfo[charName]); end end);
				tt:SetLineScript(l, "OnEnter", function() tt:SetLineColor(l, 1,192/255, 90/255, 0.3) end )
				tt:SetLineScript(l, "OnLeave", function() tt:SetLineColor(l, 0,0,0,0) end)
				l,c=nil,nil;
			end
		end
	end

	if friendsOnline==0 and numChars==0 then
		tt:SetCell(tt:AddLine(),1,C("gray",L["Currently no friends online..."]),nil,nil,ttColumns);
	end

	if (ns.profile.GeneralOptions.showHints) then
		tt:AddSeparator(3,0,0,0,0);
		tt:SetCell(tt:AddLine(),1,C("ltblue",L["Click"]).." || "..C("green",L["Whisper with a friend"]) .." - ".. C("ltblue",L["Alt+Click"]).." || "..C("green",L["Invite a friend"]),nil,nil,columns);
		ns.clickOptions.ttAddHints(tt,name,ttColumns,2);
	end

	line, column = nil, nil
	ns.roundupTooltip(self,tt);
end


------------------------------------
-- module (BE internal) functions --
------------------------------------
ns.modules[name].init = function(self)
	ldbName = (ns.profile.GeneralOptions.usePrefix and "BE.." or "")..name
end

ns.modules[name].onevent = function(self,event,msg)
	local dataobj = self.obj or ns.LDB:GetDataObjectByName(ldbName);
	local numBNFriends, numOnlineBNFriends = "?","?";
	if BNConnected() then
		numBNFriends, numOnlineBNFriends = BNGetNumFriends();
	end
	local numFriends, friendsOnline = GetNumFriends();
	local broadcastText = select(4,BNGetInfo());

	if (event=="BE_UPDATE_CLICKOPTIONS") then
		ns.clickOptions.update(ns.modules[name],ns.profile[name]);
	end

	if (ns.profile[name].splitFriends) then
		dataobj.text = format("%s/%s "..C(BNConnected() and "ltblue" or "red","%s/%s"),friendsOnline, numFriends, numOnlineBNFriends, numBNFriends);
	else
		dataobj.text = (numOnlineBNFriends + friendsOnline) .. "/" .. (numBNFriends + numFriends) .. (BNConnected()==false and "("..C("red","BNet Off")..")" or "");
	end

	if (broadcastText) and (strlen(broadcastText)>0) then
		dataobj.text=dataobj.text.." |Tinterface\\chatframe\\ui-chatinput-focusicon:0|t";
	end

	if (tt) and (tt.key) and (tt.key==ttName) and (tt:IsShown()) then
		createTooltip(false, tt);
	end
end

-- ns.modules[name].onupdate = function(self) end
-- ns.modules[name].optionspanel = function(panel) end
-- ns.modules[name].onmousewheel = function(self,direction) end
-- ns.modules[name].ontooltip = function(tt) end


-------------------------------------------
-- module functions for LDB registration --
-------------------------------------------
ns.modules[name].onenter = function(self)
	if (ns.tooltipChkOnShowModifier(false)) then return; end
	ttColumns=8;
	tt = ns.LQT:Acquire(ttName, ttColumns, "LEFT","CENTER", "LEFT", "CENTER", "LEFT", "LEFT", "LEFT", "LEFT" );
	createTooltip(self, tt)
end

ns.modules[name].onleave = function(self)
	if (tt) then ns.hideTooltip(tt,ttName,false,true); end
end

-- ns.modules[name].onclick = function(self,button)
-- ns.modules[name].ondblclick = function(self,button) end
