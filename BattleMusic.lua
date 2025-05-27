-- BattleMusic Addon

local _G, _ = _G or getfenv()
local lingering = false
local emptywarning = false
local isLingerActive = false
local isMusicPlaying = false
local lingerHandler = nil

-- Settings
local CONFIG_FRAME_NAME = "bmusic_config"
local NR_OF_COLUMNS = 2
local INPUT_HEIGHT = 20
local INPUT_WIDTH = 156
local SPACING_X = 18
local SPACING_Y = 45

local playlist = {}
local playlistLength = table.getn(playlist)

-- On addon loaded
local addonLoaded = CreateFrame("Frame")
addonLoaded:RegisterEvent("ADDON_LOADED")
addonLoaded:SetScript("OnEvent", function()
    if arg1 == "BattleMusic" then
        if battleMusic == nil then
            battleMusic = {}
            battleMusic.track = false
            battleMusic.linger = 5
            battleMusic.debug = false
        end

        CONFIG_SETTINGS_BMUSIC = {
            [1] = {"Display Track Name in Chat", "bm_track", battleMusic.track, false, "track"},
            [2] = {"Linger time (seconds)", "bm_lingerTime", battleMusic.linger, 5, "linger"},
            [3] = {"Display Debug Info in Chat", "bm_debug", battleMusic.debug, false, "debug"},
        }
    end
end)

-- Zone change stops music
local zoneChange = CreateFrame("Frame")
zoneChange:RegisterEvent("ZONE_CHANGED_NEW_AREA")
zoneChange:SetScript("OnEvent", function()
    StopMusic()
    isMusicPlaying = false
    if battleMusic.debug then
        DEFAULT_CHAT_FRAME:AddMessage("[DEBUG]: Loading Screen Clear", 1, 0, 1)
    end
end)

-- Combat start
local combatStart = CreateFrame("Frame")
combatStart:RegisterEvent("PLAYER_REGEN_DISABLED")
combatStart:SetScript("OnEvent", function()
    if isLingerActive and lingerHandler then
        if battleMusic.debug then
            DEFAULT_CHAT_FRAME:AddMessage("[DEBUG]: Combat resumed. Cancelling lingering stop.", 1, 0, 1)
        end
        lingerHandler:SetScript("OnUpdate", nil)
        isLingerActive = false
        lingering = false
    end

    if playlistLength <= 0 and not emptywarning then
        DEFAULT_CHAT_FRAME:AddMessage("BattleMusic ERROR: No songs in playlist!", 1, 0, 0)
         DEFAULT_CHAT_FRAME:AddMessage("Be sure to add your .mp3 files to Interface\\AddOns\\BattleMusic\\music\\ and run the playlist updater.")
        emptywarning = true
    end

    if not isMusicPlaying and playlistLength > 0 then
        local a = math.random(1, playlistLength)
        local b = [[Interface\AddOns\BattleMusic\music\]] .. playlist[a]

        if battleMusic.track then
            DEFAULT_CHAT_FRAME:AddMessage("Playing track: " .. playlist[a])
        end

        if battleMusic.debug then
            DEFAULT_CHAT_FRAME:AddMessage("[DEBUG]: Number of Tracks: " .. playlistLength, 1, 0, 1)
            DEFAULT_CHAT_FRAME:AddMessage("[DEBUG]: Track Number Selected: " .. a, 1, 0, 1)
            DEFAULT_CHAT_FRAME:AddMessage("[DEBUG]: File Path: " .. b, 1, 0, 1)
        end

        PlayMusic(b)
        isMusicPlaying = true
    end

    if battleMusic.linger > 0 then
        lingering = true
    end
end)

-- Combat end
local combatEnd = CreateFrame("Frame")
combatEnd:RegisterEvent("PLAYER_REGEN_ENABLED")
combatEnd:SetScript("OnEvent", function()
    if battleMusic.linger <= 0 then
        StopMusic()
        isMusicPlaying = false
        if battleMusic.debug then
            DEFAULT_CHAT_FRAME:AddMessage("[DEBUG]: No Linger. Ending Music.", 1, 0, 1)
        end
    else
        if not lingerHandler then
            lingerHandler = CreateFrame("Frame")
        end

        local lingerStartTime = GetTime()
        local lingerDuration = battleMusic.linger
        local lingerDebugShown = false
        isLingerActive = true

        lingerHandler:SetScript("OnUpdate", function(self, elapsed)
            if battleMusic.debug and not lingerDebugShown then
                DEFAULT_CHAT_FRAME:AddMessage("[DEBUG]: Combat Ended. Lingering for " .. lingerDuration .. " seconds", 1, 0, 1)
                lingerDebugShown = true
            end

            if GetTime() - lingerStartTime >= lingerDuration then
                StopMusic()
                isMusicPlaying = false
                if battleMusic.debug then
                    DEFAULT_CHAT_FRAME:AddMessage("[DEBUG]: Linger ended after " .. lingerDuration .. " seconds", 1, 0, 1)
                end
                lingerHandler:SetScript("OnUpdate", nil)
                lingering = false
                isLingerActive = false
            end
        end)
    end
end)

local function CreateCheckbox(text, name, column, row, data, isColor)

    local currentEditBox

    if(not _G[CONFIG_FRAME_NAME..name])then
        currentEditBox = CreateFrame("CheckButton", CONFIG_FRAME_NAME.."_"..name, _G[CONFIG_FRAME_NAME], "OptionsCheckButtonTemplate")
    end

    _G[CONFIG_FRAME_NAME.."_"..name.."Text"]:SetText(text)

    currentEditBox:SetPoint(
        "TOPLEFT",
        17 + ((INPUT_WIDTH + SPACING_X) * (column)),
        -20 - (row * SPACING_Y)
    )
    currentEditBox:SetChecked(data)
    currentEditBox:Show()
end

local function SaveData()
    for k,v in pairs(CONFIG_SETTINGS_BMUSIC)do

        local frame = _G[CONFIG_FRAME_NAME.."_"..v[2]]
       
        -- frame is a checkbox  
        if(type(v[4]) == "boolean")then

            local isChecked = frame:GetChecked() or false
            battleMusic[v[5]] = isChecked

        else
            local input_data = frame:GetText()
            if(input_data == "" or input_data == "nil")then
                input_data = nil
            end

            if(v[6])then
                input_data = loadstring("return " .. input_data)()
                battleMusic[v[5]] = input_data
            else
                battleMusic[v[5]] = tonumber(input_data) or input_data
            end
        end
    end

end

local function ResetData()
    for k,v in pairs(CONFIG_SETTINGS_BMUSIC)do

        local frame = _G[CONFIG_FRAME_NAME.."_"..v[2]]

        if( type(v[4]) == "table" ) then
            local table_string = ""
            for kk,vv in pairs(v[4])do
                table_string = table_string .. tostring(vv) .. ", "
            end
            table_string =  string.sub(table_string, 1, -3)
            frame:SetText("{"..table_string.."}")
        elseif(type(v[4]) == "boolean")then

            local isChecked = v[4]
            frame:SetChecked(isChecked)

        else
            frame:SetText(tostring(v[4]))
        end

    end
end


--CONFIG FRAME--

local function CreateInputField(text, name, column, row, data, isColor)
    
    local currentEditBox

    if(not _G[CONFIG_FRAME_NAME..name])then
        currentEditBox = CreateFrame("EditBox", CONFIG_FRAME_NAME.."_"..name, _G[CONFIG_FRAME_NAME], "InputBoxTemplate")
        currentEditBox.text = currentEditBox:CreateFontString("", "OVERLAY");
        currentEditBox:SetScript("OnEnterPressed", function()
          
        end)
    end
    currentEditBox:SetHeight(40)
    currentEditBox:SetWidth(INPUT_WIDTH)
    currentEditBox:SetPoint(
        "TOPLEFT",
        24 + ((INPUT_WIDTH + SPACING_X) * (column)),
        -20 - (row * SPACING_Y)
    )
    currentEditBox:SetAutoFocus(false)
    currentEditBox:SetScript("OnEscapePressed", function()
        this:ClearFocus()
    end)
    currentEditBox.text:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
    currentEditBox.text:SetPoint("TOPLEFT", -3, 4)
    currentEditBox.text:SetText(text)
    if(type(data) == "table")then
        
        local table_string = ""
        for kk,vv in pairs(data)do
            table_string = table_string .. tostring(vv) .. ", "
        end
        table_string =  string.sub(table_string, 1, -3)
        currentEditBox:SetText("{"..table_string.."}")
        currentEditBox:SetTextColor(unpack(data))
    else
        currentEditBox:SetText(tostring(data))
    end

    currentEditBox:Show()
    currentEditBox.text:Show()

    if(isColor)then
        currentEditBox:SetScript("OnMouseUp", function() 
            CustomColorPicker(currentEditBox)
        end)
    end
end

-- Generate config frame
SLASH_BMUSIC1 = "/bmusic"
SlashCmdList["BMUSIC"] = function(self, txt)
    local config_frame

    -- Create config frame if it doesn't exist
    if(not(_G[CONFIG_FRAME_NAME]))then
        
        local count_settings = 0
        for _ in pairs(CONFIG_SETTINGS_BMUSIC) do
            count_settings = count_settings + 1
        end

        config_frame = CreateFrame("frame", CONFIG_FRAME_NAME, UIParent)
        config_frame:SetWidth((24*2) + (NR_OF_COLUMNS * INPUT_WIDTH) + (SPACING_X * (NR_OF_COLUMNS - 1)))
        config_frame:SetHeight(40 + ((count_settings/NR_OF_COLUMNS) * INPUT_HEIGHT) + (INPUT_HEIGHT + SPACING_Y))
        config_frame:SetPoint("CENTER", 0, 0)
        config_frame:EnableMouse(true)
        config_frame:SetMovable(true)
        config_frame:RegisterForDrag("LeftButton")
        config_frame:SetScript("OnDragStart", function()
            this:StartMoving()
        end)
        config_frame:SetScript("OnDragStop", function()
            this:StopMovingOrSizing()
        end)

        config_frame:SetBackdrop({
            bgFile = "Interface/Tooltips/UI-Tooltip-Background",
            edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
            edgeSize = 24,
            insets={left=8, right=8, top=8, bottom=8}
        })
        config_frame:SetBackdropColor(
            0.1,
            0.1,
            0.1,
            0.8
        )

        local close_button = CreateFrame("Button", CONFIG_FRAME_NAME.."_close_button", config_frame, "UIPanelCloseButton")
        close_button:SetPoint("TOPRIGHT", -2, -2)

        local save_button = CreateFrame("Button", CONFIG_FRAME_NAME.."_save_button", config_frame, "OptionsButtonTemplate")
        save_button:SetPoint("BOTTOMRIGHT", -15, 14)
        save_button:SetText("Save")
        save_button:SetScript("OnClick", function()
            SaveData()
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00BattleMusic settings saved.|r")
        end)

        local reset_button = CreateFrame("Button", CONFIG_FRAME_NAME.."_reset_button", config_frame, "OptionsButtonTemplate")
        reset_button:SetPoint("BOTTOMLEFT", 15, 14)
        reset_button:SetText("Reset")
        reset_button:SetScript("OnClick", function()
            ResetData()
        end)

        local reload_button = CreateFrame("Button", CONFIG_FRAME_NAME.."_reload_button", config_frame, "OptionsButtonTemplate")
        reload_button:SetPoint("BOTTOMLEFT", 115, 14)
        reload_button:SetText("Reload UI")
        reload_button:SetScript("OnClick", function()
            ReloadUI()
        end)

        local column, row = 0, 0

        for k,v in pairs(CONFIG_SETTINGS_BMUSIC) do
            
            if(type(v[4]) == "boolean") then
                CreateCheckbox(v[1], v[2], column, row, v[3], v[6])
            else
                CreateInputField(v[1], v[2], column, row, v[3], v[6])
            end

            if(column > (NR_OF_COLUMNS - 2))then
                column = 0
                row = row + 1
            else
                column = column + 1
            end
        end

    else
        _G[CONFIG_FRAME_NAME]:Show()
    end

end

DEFAULT_CHAT_FRAME:AddMessage("|cffff0000BattleMusic|r |cffccccccLoaded|r |cffff0000!|r |cff888888(Type |cffffff00/bmusic|cff888888 to configure.)|r")

