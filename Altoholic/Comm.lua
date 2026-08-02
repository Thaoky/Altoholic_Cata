local addonName = ...
local addon = _G[addonName]
local colors = addon.Colors

local L = AddonFactory:GetLocale(addonName)
local LibDeflate = LibStub:GetLibrary("LibDeflate")
local LibSerialize = LibStub:GetLibrary("LibSerialize")
local commPrefix = "AltoShare"

Altoholic.Comm = {}

-- Message types
local MSG_ACCOUNT_SHARING_REQUEST			= 1
local MSG_ACCOUNT_SHARING_REFUSED			= 2
local MSG_ACCOUNT_SHARING_REFUSEDINCOMBAT	= 3
local MSG_ACCOUNT_SHARING_REFUSEDDISABLED	= 4
local MSG_ACCOUNT_SHARING_ACCEPTED			= 5
local MSG_ACCOUNT_SHARING_SENDITEM			= 6
local MSG_ACCOUNT_SHARING_COMPLETED			= 7
local MSG_ACCOUNT_SHARING_ACK					= 8	-- a simple ACK message, confirms message has been received, but no data is sent back

local CMD_DATASTORE_XFER			= 100
local CMD_DATASTORE_CHAR_XFER		= 101		-- these 2 require a special treatment
local CMD_DATASTORE_STAT_XFER		= 102
-- local CMD_BANKTAB_XFER				= 103
local CMD_REFDATA_XFER				= 104


local TOC_SEP = ";"	-- separator used between items

-- TOC Item Types
local TOC_SETREALM				= "1"
local TOC_SETGUILD				= "2"
-- local TOC_BANKTAB					= "3"
local TOC_SETCHAR					= "4"
local TOC_DATASTORE				= "5"
local TOC_REFDATA					= "6"



--[[	*** Protocol ***

Client				Server

==> MSG_ACCOUNT_SHARING_REQUEST 
<== MSG_ACCOUNT_SHARING_REFUSED (stop)   
or 
<== MSG_ACCOUNT_SHARING_ACCEPTED (receives the TOC)

while toc not empty
==> MSG_ACCOUNT_SHARING_SENDNEXT (pass the type, based on the TOC)
<== CMD_??? (transfer & save data)
wend

==> MSG_ACCOUNT_SHARING_COMPLETED

--]]

Altoholic.Comm.Sharing = {}
Altoholic.Comm.Sharing.Callbacks = {
	[MSG_ACCOUNT_SHARING_REQUEST] = "OnSharingRequest",
	[MSG_ACCOUNT_SHARING_REFUSED] = "OnSharingRefused",
	[MSG_ACCOUNT_SHARING_REFUSEDINCOMBAT] = "OnPlayerInCombat",
	[MSG_ACCOUNT_SHARING_REFUSEDDISABLED] = "OnSharingDisabled",
	[MSG_ACCOUNT_SHARING_ACCEPTED] = "OnSharingAccepted",
	[MSG_ACCOUNT_SHARING_SENDITEM] = "OnSendItemReceived",
	[MSG_ACCOUNT_SHARING_COMPLETED] = "OnSharingCompleted",
	[MSG_ACCOUNT_SHARING_ACK] = "OnAckReceived",

	[CMD_DATASTORE_XFER] = "OnDataStoreReceived",
	[CMD_DATASTORE_CHAR_XFER] = "OnDataStoreCharReceived",
	[CMD_REFDATA_XFER] = "OnRefDataReceived",
}

local importedChars

local function Whisper(player, messageType, ...)
	local serializedData = LibSerialize:Serialize(messageType, ...)
	local compressedData = LibDeflate:CompressDeflate(serializedData, {level = 8})
	local encodedData = LibDeflate:EncodeForWoWAddonChannel(compressedData)

	DataStore:SendChatMessage(commPrefix, encodedData, "WHISPER", player)
end

local function GetRequestee()
	local player	-- name of the player to whom the account sharing request will be sent
	
	if AltoAccountSharing_UseTarget:GetChecked() then
		player = UnitName("target")
	elseif AltoAccountSharing_UseName:GetChecked() then
		player = AltoAccountSharing_AccTargetEditBox:GetText()
	end

	if player and strlen(player) > 0 then
		return player
	end
end

local function SetStatus(text)
	AltoAccountSharingTransferStatus:SetText(text)
end

-- *** User guidance ***
-- the help text at the bottom of the frame describes the step the user is currently at

local function SetHelp(text)
	AltoAccountSharingHelp:SetText(text)
end

local white = colors.white

local function Highlight(text)		-- highlight a few words inside a white paragraph
	return format("%s%s%s", colors.green, text, white)
end

local function Title(text, color)
	return format("%s%s%s", color or colors.gold, text, white)
end

local HELP_SEND_REQUEST = format("%s %s\n%s\n\n%s %s\n%s\n%s",
	Title("1) Account Name:"),
	format("a label of your choice for the account you want to import data %s (ex: the name or the nickname", Highlight("from")),
	"of the player behind it). It only groups the imported characters in your Summary tab, and does not have to be a real account or character name.",
	Title("2) Send Request:"),
	format("target the player, or type the name of the character he is %s, then click the button.", Highlight("playing right now")),
	"He must have account sharing enabled, and either accept your request manually, or have authorized you in advance.",
	"Once he accepts, everything he shares will be listed on the right, and this button will become 'Request Content'.")

local HELP_REQUEST_CONTENT = format("%s %s\n%s\n%s\n\n%s",
	Title("Request accepted.", colors.green),
	"What this player shares is now listed on the right, nothing has been imported yet.",
	"Check the characters and the data you want (checking a character also checks its data categories), or use the",
	"[-] and 'All' boxes above the list to expand or check everything, then click Request Content.",
	"The date column tells you how old each item is, 'Up-to-date' means you already have that exact version.")

local HELP_TRANSFER_IN_PROGRESS = format("%s%s\n%s", white,
	"Transfer in progress, please wait...",
	"Both characters must stay online until it is complete.")

local HELP_TRANSFER_COMPLETE = format("%s %s\n%s\n\n%s %s\n%s",
	Title("Transfer complete.", colors.green),
	"The imported characters are now in your Summary tab, grouped under the account name you entered.",
	"The list on the right has been cleared, this is normal.",
	Title("Note:"),
	format("an import is a one-time snapshot, it is %s kept up to date automatically.", Highlight("not")),
	"To refresh it later, right-click the realm line in the Summary tab and choose 'Update from ...', or come back here.")

local function AccSharingHandler(prefix, message, distribution, sender)
	-- 	since communication handlers cannot be enabled/disabled on the fly,
	--	let's use a function pointer to either an empty function, or the normal one
	local self = Altoholic.Comm.Sharing

	if self and self.msgHandler then
		self[self.msgHandler](self, prefix, message, distribution, sender)
	end
end

AddonFactory:OnAddonLoaded(addonName, function()
	DataStore:OnGuildComm(commPrefix, AccSharingHandler)
end)

function Altoholic.Comm.Sharing:SetMessageHandler(handler)
	self.msgHandler = handler
end

function Altoholic.Comm.Sharing:EmptyHandler(prefix, message, distribution, sender)
	-- automatically reply that the option is disabled
	Whisper(sender, MSG_ACCOUNT_SHARING_REFUSEDDISABLED)
end

function Altoholic.Comm.Sharing:ActiveHandler(prefix, message, distribution, sender)
	local decodedData = LibDeflate:DecodeForWoWAddonChannel(message)
	local decompressedData = LibDeflate:DecompressDeflate(decodedData)
	local success, msgType, msgData = LibSerialize:Deserialize(decompressedData)

	if not success then
		self.SharingEnabled = nil
		-- self:Print(msgType)
		-- self:Print(string.sub(decompData, 1, 15))
		return
	end
	
	if success and msgType then
		local comm = Altoholic.Comm.Sharing
		local cb = comm.Callbacks[msgType]
		
		if cb then
			comm[cb](self, sender, msgData)		-- process the message
		end
	end
end

function Altoholic.Comm.Sharing:Request()

	local account = AltoAccountSharing_AccNameEditBox:GetText()
	if not account or strlen(account) == 0 then 		-- account name cannot be empty
		Altoholic:Print("[" .. L["Account Name"] .. "] " .. L["This field |cFF00FF00cannot|r be left empty."])
		return 
	end
	
	self.account = account

	local player = GetRequestee()
	if player then
		self.SharingInProgress = true
		-- AltoAccountSharing:Hide()
		Altoholic:Print(format(L["Sending account sharing request to %s"], player))
		SetStatus(format("Getting table of content from %s", player))
		SetHelp(format("%s %s\n%s\n%s", Title("Request sent."),
			format("Waiting for %s to answer...", player),
			"He has to accept it, unless he has already authorized your character in his own options.",
			"If nothing happens, make sure he is online, on the same realm, and that he is running Altoholic."))
		Whisper(player, MSG_ACCOUNT_SHARING_REQUEST)
	end
end

local function ImportCharacters()
	-- once data has been transfered, finalize the import by acknowledging that these alts can be seen by client addons
	-- will be changed when account sharing goes into datastore.
	for key in pairs(importedChars) do
		DataStore:ImportCharacter(key)
	end
	importedChars = nil
end

function Altoholic.Comm.Sharing:RequestNext(player)
	self.NetDestCurItem = self.NetDestCurItem + 1
	local index = self.NetDestCurItem

	-- find the next checked item
	local isChecked = Altoholic.Sharing.AvailableContent:IsItemChecked(index)
	while not isChecked and index <= #self.DestTOC do
		index = index + 1
		isChecked = Altoholic.Sharing.AvailableContent:IsItemChecked(index)
	end

	if isChecked and index <= #self.DestTOC then
		SetStatus(format("Transfering item %d/%d", index, #self.DestTOC ))
		local TocData = self.DestTOC[index]
		local TocType = strsplit(TOC_SEP, TocData)
		local _
			
		if TocType == TOC_SETREALM then
			_, self.ClientRealmName = strsplit(TOC_SEP, TocData)
		elseif TocType == TOC_SETGUILD then
			_, self.ClientGuildName = strsplit(TOC_SEP, TocData)
			
		elseif TocType == TOC_SETCHAR then
			_, self.ClientCharName = strsplit(TOC_SEP, TocData)
			
		elseif TocType == TOC_DATASTORE then
			
		elseif TocType == TOC_REFDATA then
		end
		
		Whisper(player, MSG_ACCOUNT_SHARING_SENDITEM, index)
		self.NetDestCurItem = index
		return
	end

	ImportCharacters()
	SetStatus(L["Transfer complete"])
	Whisper(player, MSG_ACCOUNT_SHARING_COMPLETED)

	wipe(self.DestTOC)
	self.DestTOC = nil
	
	self.SharingInProgress = nil
	self.SharingEnabled = nil
	self.NetDestCurItem = nil
	self.ClientRealmName = nil
	self.ClientGuildName = nil
	self.ClientCharName = nil
	
	Altoholic.Sharing.AvailableContent:Clear()
	self:SetMode(1)
	SetHelp(HELP_TRANSFER_COMPLETE)		-- SetMode has just reset the help text, tell the user what happened instead

	Altoholic:SetLastAccountSharingInfo(player, GetRealmName(), self.account)
	
	-- the summary tab is load on demand, only refresh it if it has been loaded
	if Altoholic.Characters then
		Altoholic.Characters:InvalidateView()
		Altoholic.Summary:Update()
	end
end

local function SharingRequestReceived_Handler(self, button, sender)
	if not button then 
		Whisper(sender, MSG_ACCOUNT_SHARING_REFUSED)
		return 
	end

	Altoholic.Comm.Sharing:SendSourceTOC(sender)
end

local AUTH_AUTO	= 1
local AUTH_ASK		= 2
local AUTH_NEVER	= 3

function Altoholic.Comm.Sharing:OnSharingRequest(sender, data)
	self.SharingEnabled = nil
	
	if InCombatLockdown() then
		-- automatically reject if requestee is in combat
		Whisper(sender, MSG_ACCOUNT_SHARING_REFUSEDINCOMBAT)
		return
	end
	
	local auth = Altoholic.Sharing.Clients:GetRights(sender)
	
	if not auth then		-- if the sender is not a known client, add him with defaults rights (=ask)
		Altoholic.Sharing.Clients:Add(sender)
		Altoholic.Sharing.Clients:Update()		-- refresh the authorization list, the option pane may be open
		auth = AUTH_ASK
	end
	
	if auth == AUTH_AUTO then
		self:SendSourceTOC(sender)
	elseif auth == AUTH_ASK then
		Altoholic:Print(format(L["Account sharing request received from %s"], sender))
		
		AltoMessageBox:SetHeight(130)
		AltoMessageBox.Text:SetHeight(60)
		AltoMessageBox:SetHandler(SharingRequestReceived_Handler, sender)
		AltoMessageBox:SetText(
			format("%s\n\n%s",
				format(L["You have received an account sharing request\nfrom %s%s|r, accept it?"], colors.white, sender),
				format(L["%sWarning:|r if you accept, %sALL|r information known\nby Altoholic will be sent to %s%s|r (bags, money, etc..)"], colors.white, colors.green, colors.white,sender)
			))
		AltoMessageBox:Show()
		
	elseif auth == AUTH_NEVER then
		Whisper(sender, MSG_ACCOUNT_SHARING_REFUSED)
	end
end

function Altoholic.Comm.Sharing:SendSourceTOC(sender)
	self.SharingEnabled = true
	self.SourceTOC = Altoholic.Sharing.Content:GetSourceTOC()
	-- self.NetSrcCurItem = 0					-- to display that item is 1 of x
	self.AuthorizedRecipient = sender
	Altoholic:Print(format(L["Sending table of content (%d items)"], #self.SourceTOC))
	Whisper(sender, MSG_ACCOUNT_SHARING_ACCEPTED, self.SourceTOC)
end

function Altoholic.Comm.Sharing:GetContent()
	local player = GetRequestee()
	if player then
		self:SetMode(3)
		self:RequestNext(player)
	end
end

function Altoholic.Comm.Sharing:GetAccount()
	return self.account
end

function Altoholic.Comm.Sharing:SetMode(mode)
	local button = AltoAccountSharing_SendButton
	if mode == 1 then			-- send request, expect toc in return
		button:SetText("Send Request")
		button:Enable()
		button.requestMode = nil
		SetHelp(HELP_SEND_REQUEST)
	elseif mode == 2 then	-- request content, get data in return
		button:SetText("Request Content")
		button:Enable()
		button.requestMode = true
		SetHelp(HELP_REQUEST_CONTENT)
	elseif mode == 3 then
		importedChars = importedChars or {}
		wipe(importedChars)
		button:Disable()
		SetHelp(HELP_TRANSFER_IN_PROGRESS)
	end
end

function Altoholic.Comm.Sharing:OnSharingRefused(sender, data)
	SetStatus(format("%s%s", colors.red, format(L["Request rejected by %s"], sender)))
	SetHelp(format("%s %s\n%s", Title("Request rejected.", colors.red),
		"This player either declined your request, or has set your character to 'always reject'.",
		"Nothing has been imported. You may send a new request at any time."))
	self.SharingInProgress = nil
end

function Altoholic.Comm.Sharing:OnPlayerInCombat(sender, data)
	SetStatus(format("%s%s", colors.red, format(L["%s is in combat, request cancelled"], sender)))
	SetHelp(format("%s %s\n%s", Title("Request cancelled.", colors.red),
		"Account sharing requests are always rejected while the other player is in combat.",
		"Wait until he is out of combat, then send the request again."))
	self.SharingInProgress = nil
end

function Altoholic.Comm.Sharing:OnSharingDisabled(sender, data)
	SetStatus(format("%s%s", colors.red, format(L["%s has disabled account sharing"], sender)))
	SetHelp(format("%s %s\n%s", Title("Request rejected.", colors.red),
		"This player has not enabled account sharing.",
		"He must tick 'Account Sharing Enabled' in his own Altoholic options before you can request anything."))
	self.SharingInProgress = nil
end

function Altoholic.Comm.Sharing:OnSharingAccepted(sender, data)
	self.DestTOC = data
	self.NetDestCurItem = 0
	SetStatus(format("%s%s", colors.green, format(L["Table of content received (%d items)"], #self.DestTOC)))

	-- build & refresh the scroll frame
	Altoholic.Sharing.AvailableContent:ResetScroll()
	Altoholic.Sharing.AvailableContent:BuildView()
	Altoholic.Sharing.AvailableContent:Update()
	
	-- change the text on the 'send' button 
	self:SetMode(2)
end

-- Send Content
function Altoholic.Comm.Sharing:OnSendItemReceived(sender, data)
	-- Server side, a request to send a given item is processed here
	if not self.SharingEnabled or not self.AuthorizedRecipient then
		return
	end
	
	local DS = DataStore
	local index = tonumber(data)		-- get the index of the item in the toc
		
	local TocData = self.SourceTOC[index]
	local TocType = strsplit(TOC_SEP, TocData)		-- get its type
	local _
		
	if TocType == TOC_SETREALM then
		_, self.ServerRealmName = strsplit(TOC_SEP, TocData)
		Whisper(self.AuthorizedRecipient, MSG_ACCOUNT_SHARING_ACK)
	elseif TocType == TOC_SETGUILD then
		_, self.ServerGuildName = strsplit(TOC_SEP, TocData)
		Whisper(self.AuthorizedRecipient, MSG_ACCOUNT_SHARING_ACK)
	elseif TocType == TOC_SETCHAR then		-- character ? send mandatory modules (char definition = DS_Char + DS_Stats)
		_, self.ServerCharacterName = strsplit(TOC_SEP, TocData)
		Whisper(self.AuthorizedRecipient, CMD_DATASTORE_CHAR_XFER, DS:GetCharacterTable("DataStore_Characters", self.ServerCharacterName, self.ServerRealmName))
	
	elseif TocType == TOC_DATASTORE then	-- DS ? Send the appropriate DS module
		local _, moduleName = strsplit(TOC_SEP, TocData)
		Whisper(self.AuthorizedRecipient, CMD_DATASTORE_XFER, DS:GetCharacterTable(moduleName, self.ServerCharacterName, self.ServerRealmName))
		
	elseif TocType == TOC_REFDATA then
		local _, class = strsplit(TOC_SEP, TocData)
		Whisper(self.AuthorizedRecipient, CMD_REFDATA_XFER, DS:GetClassReference(class))
	end
end

function Altoholic.Comm.Sharing:OnSharingCompleted(sender, data)
	self.SharingEnabled = nil
	self.AuthorizedRecipient = nil
	self.ServerRealmName = nil
	self.ServerGuildName = nil
	self.ServerCharacterName = nil
	wipe(self.SourceTOC)
	
	self.SourceTOC = nil
	Altoholic:Print(L["Transfer complete"])
end

function Altoholic.Comm.Sharing:OnAckReceived(sender, data)
	self:RequestNext(sender)
end


-- Receive content
function Altoholic.Comm.Sharing:OnDataStoreReceived(sender, data)
	local TocData = self.DestTOC[self.NetDestCurItem]
	local _, moduleName = strsplit(TOC_SEP, TocData)
	
	DataStore:ImportData(moduleName, data, self.ClientCharName, self.ClientRealmName, self.account)
	self:RequestNext(sender)
end

function Altoholic.Comm.Sharing:OnDataStoreCharReceived(sender, data)
	DataStore:ImportData("DataStore_Characters", data, self.ClientCharName, self.ClientRealmName, self.account)

	-- temporarily deal with this here, will be changed when account sharing goes to  DataStore.
	-- faction & guild are no longer stored in the character table, they are derived from the imported data,
	-- so just keep track of the key, and finalize the import once the transfer is over.
	local key = format("%s.%s.%s", self.account, self.ClientRealmName, self.ClientCharName)

	importedChars[key] = true

	self:RequestNext(sender)
end

function Altoholic.Comm.Sharing:OnRefDataReceived(sender, data)
	local TocData = self.DestTOC[self.NetDestCurItem]
	local _, class = strsplit(TOC_SEP, TocData)
	
	DataStore:ImportClassReference(class, data)
--	Altoholic:Print(format(L["Reference data received (%s) !"], class))
	self:RequestNext(sender)
end


-- *** DataStore Event Handlers ***
function addon:DATASTORE_GUILD_MAIL_RECEIVED(event, sender, recipient)
	if Altoholic_UI_Options.Mail.GuildMailWarning then
		addon:Print(format(L["%s|r has received a mail from %s"], format("%s%s", colors.green, recipient), format("%s%s", colors.green, sender)))
	end
end

function addon:DATASTORE_GLOBAL_MAIL_EXPIRY(event, threshold)
	-- at least one mail has expired
	
	local lastWarning = Altoholic_UI_Options.Mail.LastExpiryWarning
	local timeToNext = Altoholic_UI_Options.Mail.TimeToNextWarning
	local now = time()
	
	if (now - lastWarning) < (timeToNext * 3600) then	-- has enough time passed ?
		return		-- no ? exit !
	end
	
	AltoMessageBox:SetHeight(130)
	AltoMessageBox.Text:SetHeight(60)
	AltoMessageBox:SetHandler(function(self, button)
			if button then
				addon:ToggleUI()
				AltoholicTabSummary.MenuItem4:Item_OnClick()
			end
		end)
	
	AltoMessageBox:SetText(format("%sAltoholic: %s\n%s\n%s\n\n%s", colors.teal, colors.white, 
		L["Mail is about to expire on at least one character."],
		L["Refer to the activity pane for more details."],
		L["Do you want to view it now ?"]))
	
	AltoMessageBox:Show()
	
	Altoholic_UI_Options.Mail.LastExpiryWarning = now
end

function addon:DATASTORE_MAIL_EXPIRY(event, character, key, threshold, numExpiredMails)
	-- if option then
		-- local _, _, name = strsplit(".", key)
		-- addon:Print(format("%d mails will expire in less than %d days on %s", numExpiredMails, threshold, name)
 	-- end
end

function addon:DATASTORE_GUILD_LEFT(event)
	if addon.Summary then
		addon.Summary:Update()
	end
end