log.info("[Toggle HUD Settings] started loading")

local CONFIG_PATH = "toggle_hud_settings.json"

local config = {
  version = "1.0.0",
  isModDisabled = false,
  isChatNotificationsDisabled = false,
  isHiddenMode = false,
}

local hudWhenModDisabled = {
  ["CLOCK"] = 1,
  ["COMPANION"] = 0,
  ["CONTROL"] = 0,
  ["GUIDE"] = 0,
  ["HEALTH"] = 1,
  ["MINIMAP"] = 1,
  ["NAME_ACCESSIBLE"] = 0,
  ["NAME_OTHER"] = 0,
  ["NOTICE"] = 0,
  ["PROGRESS"] = 0,
  ["SHARPNESS"] = 1,
  ["SHORTCUT_GAMEPAD"] = 1,
  ["SHORTCUT_KEYBOARD"] = 1,
  ["SLIDER_BULLET"] = 0,
  ["SLIDER_ITEM"] = 0,
  ["SLINGER"] = 0,
  ["STAMINA"] = 1,
  ["TARGET"] = 0,
  ["WEAPON"] = 1
}

local hudWithL1Pressed = {
  ["CLOCK"] = 0,
  ["COMPANION"] = 0,
  ["CONTROL"] = 0,
  ["GUIDE"] = 0,
  ["HEALTH"] = 1,
  ["MINIMAP"] = 0,
  ["NAME_ACCESSIBLE"] = 0,
  ["NAME_OTHER"] = 0,
  ["NOTICE"] = 0,
  ["PROGRESS"] = 0,
  ["SHARPNESS"] = 1,
  ["SHORTCUT_GAMEPAD"] = 1,
  ["SHORTCUT_KEYBOARD"] = 1,
  ["SLIDER_BULLET"] = 0,
  ["SLIDER_ITEM"] = 0,
  ["SLINGER"] = 0,
  ["STAMINA"] = 1,
  ["TARGET"] = 0,
  ["WEAPON"] = 1
}

local minimalisticHud = {
  ["CLOCK"] = 3,
  ["COMPANION"] = 0,
  ["CONTROL"] = 3,
  ["GUIDE"] = 3,
  ["HEALTH"] = 1,
  ["MINIMAP"] = 3,
  ["NAME_ACCESSIBLE"] = 0,
  ["NAME_OTHER"] = 0,
  ["NOTICE"] = 0,
  ["PROGRESS"] = 3,
  ["SHARPNESS"] = 1,
  ["SHORTCUT_GAMEPAD"] = 1,
  ["SHORTCUT_KEYBOARD"] = 1,
  ["SLIDER_BULLET"] = 0,
  ["SLIDER_ITEM"] = 3,
  ["SLINGER"] = 0,
  ["STAMINA"] = 1,
  ["TARGET"] = 0,
  ["WEAPON"] = 1
}

local hiddenHud = {
  ["CLOCK"] = 3,
  ["COMPANION"] = 3,
  ["CONTROL"] = 3,
  ["GUIDE"] = 3,
  ["HEALTH"] = 3,
  ["MINIMAP"] = 3,
  ["NAME_ACCESSIBLE"] = 0,
  ["NAME_OTHER"] = 3,
  ["NOTICE"] = 0,
  ["PROGRESS"] = 3,
  ["SHARPNESS"] = 3,
  ["SHORTCUT_GAMEPAD"] = 1,
  ["SHORTCUT_KEYBOARD"] = 1,
  ["SLIDER_BULLET"] = 3,
  ["SLIDER_ITEM"] = 3,
  ["SLINGER"] = 3,
  ["STAMINA"] = 3,
  ["TARGET"] = 3,
  ["WEAPON"] = 3
}

if json ~= nil then
  file = json.load_file(CONFIG_PATH)
  if file ~= nil then
      config = file
  else
      json.dump_file(CONFIG_PATH, config)
  end
end

local function generate_enum()
  local t = sdk.find_type_definition("app.GUIHudDef.TYPE")
  if not t then return {} end

  local fields = t:get_fields()
  local enum = {}

  for i, field in ipairs(fields) do
      if field:is_static() then
          local name = field:get_name()
          local raw_value = field:get_data(nil)

          log.info(name .. " = " .. tostring(raw_value))

          enum[name] = raw_value
      end
  end

  return enum
end

local hudSettingsMapper = generate_enum()

local guiManager = sdk.get_managed_singleton("app.GUIManager")
local hudDisplayManager = guiManager:get_field("_HudDisplayManager")

local status = ""

local function minimizeHUD()
  for key, value in pairs(minimalisticHud) do
    hudDisplayManager:call("setHudDisplay", hudSettingsMapper[key], value)
  end
  if config.isChatNotificationsDisabled then
    hudDisplayManager:call("setHudDisplay", 11, 3) -- 11 = Chat notifications / 3 = Hidden
  end
end

local function hideHUD()
  for key, value in pairs(hiddenHud) do
    hudDisplayManager:call("setHudDisplay", hudSettingsMapper[key], value)
  end
  if config.isChatNotificationsDisabled then
    hudDisplayManager:call("setHudDisplay", 11, 3) -- 11 = Chat notifications / 3 = Hidden
  end
end

local function restoreHUD()
  for key, value in pairs(hudWithL1Pressed) do
    hudDisplayManager:call("setHudDisplay", hudSettingsMapper[key], value)
  end
end

local function restoreHUDModDisabled()
  for key, value in pairs(hudWhenModDisabled) do
    hudDisplayManager:call("setHudDisplay", hudSettingsMapper[key], value)
  end
end

local function restoreDefaultHUD()
  for key, value in pairs(hudSettingsMapper) do
    hudDisplayManager:call("setHudDisplay", value, 1) -- 1 = Default
  end
end

-- local function showHudCustomSettings()
--   if imgui.tree_node("Custom Hud Settings") then 
--     for key, value in pairs(hudWithL1Pressed) do
--       imgui.text(tostring(key) .. ": " .. tostring(value))
--     end
--     imgui.tree_pop()
--   end
-- end

-- local function showHudSettingsMapper()
--   if imgui.tree_node("Hud Settings Mapper") then 
--     for key, value in pairs(hudSettingsMapper) do
--       imgui.text(tostring(key) .. ": " .. tostring(value))
--     end
--     imgui.tree_pop()
--   end
-- end

sdk.hook(
    sdk.find_type_definition("app.GUI020008PartsPallet"):get_method("open"),
    function() end,
    function() 
      if config.isModDisabled then return end
      restoreHUD()
    end
)

sdk.hook(
    sdk.find_type_definition("app.GUI020008PartsPallet"):get_method("close"),
    function() end,
    function() 
      if config.isModDisabled then return end
      if config.isHiddenMode then
        hideHUD()
      else
        minimizeHUD()
      end
    end
)

re.on_draw_ui(
  function()
    if imgui.tree_node("HUD Toggle Mod") then
      local doWrite = false
      changed, value = imgui.checkbox("Disable mod", config.isModDisabled)
      if changed then
        doWrite = true
        config.isModDisabled = value
        if config.isModDisabled then
          restoreHUDModDisabled()
        else
          minimizeHUD()
        end
      end

      changed, value = imgui.checkbox("Hide Chat Notifications", config.isChatNotificationsDisabled)
      if changed then
        doWrite = true
        config.isChatNotificationsDisabled = value
        restoreHUD()
        minimizeHUD()
      end

      changed, value = imgui.checkbox("Hide All (except chat notifications)", config.isHiddenMode)
      if changed then
        doWrite = true
        config.isHiddenMode = value
        if config.isHiddenMode then
          hideHUD()
        else
          minimizeHUD()
        end
      end

      if imgui.button("Restore Custom HUD") then
        restoreHUD()
      end
  
      if imgui.button("Restore Default HUD") then
        restoreDefaultHUD()
      end

      if string.len(status) > 0 then
        imgui.text("Status: " .. status)
      end

      -- showHudCustomSettings()
      -- showHudSettingsMapper()

      if doWrite then
        json.dump_file(CONFIG_PATH, config)
      end

      imgui.tree_pop()
    end
  end
)

log.info("[Toggle HUD Settings] finished loading")
