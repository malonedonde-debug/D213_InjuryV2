Config = {}

-- Notification System: "ox_lib" or "vms_notify" or "esx"
Config.NotificationType = "ox_lib" 

-- Health threshold to trigger the injury system (GTA health: 100 is dead, 200 is full)
Config.InjuryThreshold = 140 

-- Visuals
Config.ScreenEffect = "DeathFailOut" -- Examples (CarDamageHit, MP_Killstreak, CarPitstopComplete)
Config.WalkStyle = "move_m@injured"

-- Movement Speed Modifiers (1.0 is default)
Config.MoveSpeedMultiplier = 0.7 

-- Bleed Settings
Config.BleedInterval = 23000 -- 15 seconds
Config.BleedDamage = 2       -- HP to lose every interval

-- Stumble Settings
Config.StumbleInterval = 20000 -- Every 20 seconds
Config.StumbleDuration = 2000  -- How long the stumble lasts (ms)

-- Leg Shot Settings
Config.LegShotStumbleDuration = 1000 -- How long they fall if shot in leg
Config.LegBones = {
    [11816] = "Waist / Pelvis",
    [58271] = "Left Leg",
    [63931] = "Left Calf",
    [14201] = "Left Foot",
    [52301] = "Left Foot",
    [2108] = "Right Foot",
    [36864] = "Right Leg",
    [51826] = "Right Calf",
    [20781] = "Right Foot",
    [35502] = "Right Foot"
}
-- Debug
Config.Debug = true 

-- Test Command Settings
Config.TestCommand = {
    Enabled = false,
    CommandName = "injurytest",
    Restricted = "admin", -- Set to false for everyone, or "admin" for ESX group check
    Peds = {
        { label = "Balla", model = "g_m_y_ballasout_01" },
        { label = "Vago", model = "g_m_y_vagos_01" },
        { label = "Police", model = "s_m_y_cop_01" }
    },
    Weapons = {
        { label = "Pistol", hash = "weapon_pistol" },
        { label = "SMG", hash = "weapon_smg" },
        { label = "Carbine", hash = "weapon_carbinerifle" },
        { label = "Glock 19", hash = "weapon_g19" }
    }
}