local BFChat = LibStub('AceAddon-3.0'):GetAddon('BigFootChat')
local L = LibStub("AceLocale-3.0"):GetLocale("BigFootChat")
local MODNAME = "CHATFRAME"
local BFChatFrame = BFChat:NewModule(MODNAME)
local BFC_NUM_TAB = 7
local chatchannelframe = {}
local buttonTemplate
local db
local defaults = {
    profile = {enablechatchannel = false, enablechatchannelmove = false}
}
local BFC_TABS = {
    {text = L.Say, tabtype = "/s ", texture = "say", tooltip = L["SayTooltip"]},
    {
        text = L.PartyShort,
        tabtype = "/p ",
        texture = "party",
        tooltip = L["PartyTooltip"]
    }, {
        text = L.RaidShort,
        tabtype = "/raid ",
        texture = "raid",
        tooltip = L["RaidTooltip"]
    }, {
        text = L.BattleGroundShort,
        tabtype = "/bg ",
        texture = "battleground",
        tooltip = L["BGTooltip"]
    }, {
        text = L.GuildShort,
        tabtype = "/g ",
        texture = "guild",
        tooltip = L["GuildTooltip"]
    }, {
        text = L.YellShort,
        tabtype = "/y ",
        texture = "yell",
        tooltip = L["YellTooltip"]
    }, {
        text = L.WhisperToShort,
        tabtype = "/w ",
        texture = "whisper",
        tooltip = L["WhisperTooltip"]
    }, {
        text = L.OfficerShort,
        tabtype = "/o ",
        texture = "officer",
        tooltip = L["OfficerTooltip"]
    }, {
        text = L.BigFootShort,
        tabtype = nil,
        texture = nil,
        tooltip = L["BigFootTooltip"]
    }
}
local optGetter, optSetter
do
    local mod = BFChatFrame
    function optGetter(info)
        local key = info[#info]
        return db[key]
    end
    function optSetter(info, value)
        local key = info[#info]
        db[key] = value
        mod:Refresh()
    end
end
local function BigFoot_LocateKeyBinding(bindingName)
    KeyBindingFrame_LoadUI()
    local numBindings = GetNumBindings()
    local offset = 1
    for i = 1, numBindings do
        if bindingName == GetBinding(i, 1) then
            offset = i
            break
        end
    end
    FauxScrollFrame_SetOffset(KeyBindingFrameScrollFrame, offset - 1)
    ShowUIPanel(KeyBindingFrame)
    KeyBindingFrameScrollFrameScrollBar:SetValue(
        (offset - 1) * KEY_BINDING_HEIGHT)
end
local options
local getOptions = function()
    if not options then
        options = {
            type = "group",
            name = L["ChatFrame"],
            arg = MODNAME,
            get = optGetter,
            set = optSetter,
            args = {
                intro = {
                    order = 1,
                    type = "description",
                    name = L["Fast chat channel provides you easy access to different channels"]
                },
                enablechatchannel = {
                    order = 2,
                    type = "toggle",
                    name = L["Enable channel buttons"],
                    get = function()
                        return BFChat:GetModuleEnabled(MODNAME)
                    end,
                    set = function(info, value)
                        BFChat:SetModuleEnabled(MODNAME, value)
                    end,
                    width = "full"
                },
                showbfckeybinding = {
                    order = 3,
                    type = "execute",
                    name = L["Show BFC keybinding"],
                    func = function()
                        LibStub("AceConfigDialog-3.0"):Close("BigFootChat")
                        BigFoot_LocateKeyBinding("BFCSAY")
                    end
                },
                enableRollButton = {
                    order = 4,
                    type = "toggle",
                    name = L["Enable roll buttons"],
                    get = function()
                        return BFChat.db.profile.enableRollButton
                    end,
                    set = function()
                        BFChat:BFChannelRollButton_OnClick()
                    end,
                    width = "full"
                },
                enableReportButton = {
                    order = 5,
                    type = "toggle",
                    name = L["Enable report buttons"],
                    get = function()
                        return BFChat.db.profile.enableReportButton
                    end,
                    set = function()
                        BFChat:BFChannelReportButton_OnClick()
                    end,
                    width = "full"
                },
                enableRaidersButton = {
                    order = 6,
                    type = "toggle",
                    name = L["Enable raiders buttons"],
                    get = function()
                        return BFChat.db.profile.enableRaidersButton
                    end,
                    set = function()
                        BFChat:BFChannelRaidersButton_OnClick()
                    end,
                    width = "full"
                }
            }
        }
    end
    return options
end
function getBigFootChannel()
    local channelList = {GetChannelList()}
    for i, channel in pairs(channelList) do
        if channel == L.BigFootChannel or channel == BFChatAddOn.nextChannel then
            return channelList[i - 1]
        end
    end
end
function BFC_SetChatType(_type)
    local editBox = ChatEdit_ChooseBoxForSend(SELECTED_CHAT_FRAME)
    if _type then
        ChatEdit_HandleChatType(editBox, "", _type)
        editBox:Show()
        editBox:SetFocus()
        editBox:SetText(_type)
    else
        local bfChannel = getBigFootChannel()
        if bfChannel then
            bfChannel = "/" .. bfChannel .. " "
            ChatEdit_HandleChatType(editBox, "", bfChannel)
            editBox:Show()
            editBox:SetFocus()
            editBox:SetText(bfChannel)
        end
    end
    ChatEdit_OnSpacePressed(editBox)
    if BFC_CurEB then
        local ExistMSG = BFC_CurEB:GetText() or ""
        if BFC_CurEB:IsShown() then BFC_CurEB:Insert(ExistMSG) end
    end
end
local function createChatTab(BFChat_e6955c64cf39bdb23dc86de1a9ec2117,
                             BFChat_6d5e7d83d8358745ae4dcf61d16bd1f3,
                             BFChat_9248008bbb6d0ee7ce13f6ee45680051,
                             BFChat_6c162b1123a1eb57c1827271b32b6959, index)
    local chatTab = _G["BFCChatTab" .. index]
    if not chatTab then
        chatTab = CreateFrame("Button", "BFCChatTab" .. index, UIParent,
                              "BFCChatTabTemplate")
    end
    chatTab.type = BFChat_6d5e7d83d8358745ae4dcf61d16bd1f3
    chatTab.text = BFChat_e6955c64cf39bdb23dc86de1a9ec2117
    _G[chatTab:GetName() .. "Text"]:SetText(chatTab.text)
    if (index == 1) then
        chatTab:SetPoint("LEFT", _G.BFCIconFrameCalloutButton, "RIGHT", 1, 0)
    else
        chatTab:SetPoint("LEFT", _G["BFCChatTab" .. (index - 1)], "RIGHT", 1, 0)
    end
    chatTab:Show()
    if BFChat_6c162b1123a1eb57c1827271b32b6959 then
        chatTab:SetScript("OnEnter", function()
            BigFoot_ShowNewbieTooltip(BFChat_6c162b1123a1eb57c1827271b32b6959)
        end)
        chatTab:SetScript("OnLeave", function()
            BigFoot_HideNewbieTooltip()
        end)
    end
    return chatTab
end
function BFChatFrame:OnInitialize()
    self.db = BFChat.db:RegisterNamespace(MODNAME, defaults)
    db = self.db.profile
    self:SetEnabledState(BFChat:GetModuleEnabled(MODNAME))
    BFChat:RegisterModuleOptions(MODNAME, getOptions, L["ChatFrame"])
end
local function BFChat_845d97ef2e392a3ba2b82c5a35958f77()
    for i = 1, 10 do
        local editBox = _G["ChatFrame" .. i .. "EditBox"]
        if editBox then
            editBox:SetPoint("TOPLEFT", _G["ChatFrame" .. i], "BOTTOMLEFT", -5,
                             -24)
            editBox:SetPoint("TOPRIGHT", _G["ChatFrame" .. i], "BOTTOMRIGHT", 5,
                             -24)
        end
    end
end
local function BFChat_6a1df3ac0d785e473180af9abe6758ca()
    for i = 1, 10 do
        local editBox = _G["ChatFrame" .. i .. "EditBox"]
        if editBox then
            editBox:SetPoint("TOPLEFT", _G["ChatFrame" .. i], "BOTTOMLEFT", -5,
                             -2)
            editBox:SetPoint("TOPRIGHT", _G["ChatFrame" .. i], "BOTTOMRIGHT", 5,
                             -2)
        end
    end
end
function BFChatFrame:Refresh() end
function BFChatFrame:GetChannelListTab(...) return {...} end
function BFChatFrame:AddNewChanel()
    local CheckNumber = 9
    local chatTab
    for i = 10, 14 do
        chatTab = _G["BFCChatTab" .. i]
        if chatTab then chatTab:Hide() end
    end
    local ChannelList = BFChatFrame:GetChannelListTab(GetChannelList())
    for k, v in pairs(ChannelList) do
        if mod(k, 3) == 1 and CheckNumber < 21 then
            if tonumber(v) and tonumber(v) > 5 then
                CheckNumber = CheckNumber + 1
                tinsert(chatchannelframe,
                        createChatTab(tostring(v), "/" .. tostring(v) .. " ",
                                      tostring(v), tostring(ChannelList[k + 1]),
                                      CheckNumber))
            end
        end
    end
    BFChatFrame_CheckNumber = CheckNumber
end
function BFChatFrame:UpdataChanelList()
    BFChatFrame:AddNewChanel()
    local rollButton = _G.BFCIconFrameRollButton
    rollButton:SetPoint("LEFT", _G["BFCChatTab" .. (BFChatFrame_CheckNumber)],
                        "RIGHT", 1, 0)
    local reportButton = _G.BFCIconFrameReportButton
    if BFChatFrame_CheckNumber then
        reportButton:SetPoint("LEFT", _G.BFCIconFrameRollButton, "RIGHT", 1, 0)
    end
    local raidersButton = _G.BFCIconFrameRaidersButton
    if BFChatFrame_CheckNumber then
        raidersButton:SetPoint("LEFT", _G.BFCIconFrameReportButton, "RIGHT", 1,
                               0)
    end
end
local f = CreateFrame 'Frame'
f:RegisterEvent("CHANNEL_UI_UPDATE")
f:SetScript("OnEvent",
            function(self, event, ...) BFChatFrame:UpdataChanelList() end)
function BFChatFrame:OnEnable()
    chatchannelframe = {}
    local i = 0
    for BFChat_63a9ce6f1eeac72ef41293b7d0303335,
        BFChat_8d0644c92128c1ff68223fd74ba63b56 in pairs(BFC_TABS) do
        i = i + 1
        tinsert(chatchannelframe,
                createChatTab(BFChat_8d0644c92128c1ff68223fd74ba63b56.text,
                              BFChat_8d0644c92128c1ff68223fd74ba63b56.tabtype,
                              BFChat_8d0644c92128c1ff68223fd74ba63b56.texture,
                              BFChat_8d0644c92128c1ff68223fd74ba63b56.tooltip, i))
    end
    BFChatFrame:AddNewChanel()
    BFChat_845d97ef2e392a3ba2b82c5a35958f77()
    BFCChatFrame:Show()
    self:Refresh()
end
function BFChatFrame:OnDisable()
    BFChat_6a1df3ac0d785e473180af9abe6758ca()
    for BFChat_63a9ce6f1eeac72ef41293b7d0303335,
        BFChat_8d0644c92128c1ff68223fd74ba63b56 in pairs(chatchannelframe) do
        BFChat_8d0644c92128c1ff68223fd74ba63b56:ClearAllPoints()
        BFChat_8d0644c92128c1ff68223fd74ba63b56:Hide()
    end
    self:Refresh()
end
