-- itayoHub Loader v2.1 — Layer 2: auto-update + version checker
-- Download dari GitHub, fallback chain kena takedown
-- Auto-update kalo version.txt lebih baru

local VERSION = "2.0"
local REPO = "itayohub/itayohub"
local BRANCH = "main"

local CHEAT_SOURCES = {
    "https://raw.githubusercontent.com/" .. REPO .. "/" .. BRANCH .. "/itayohub.lua",
    "https://raw.githubusercontent.com/" .. REPO .. "/backup/itayohub.lua",
    "https://gitlab.com/" .. REPO .. "/-/raw/main/itayohub.lua",
    "https://pastebin.com/raw/CHANGE_ME",
}

local VERSION_URL = "https://raw.githubusercontent.com/" .. REPO .. "/" .. BRANCH .. "/version.txt"

print("╔══════════════════════════════════╗")
print("║     itayoHub Loader v" .. VERSION .. "       ║")
print("╚══════════════════════════════════╝")

-- Version check
local function getLatestVersion()
    local ok, ver = pcall(function()
        return game:HttpGet(VERSION_URL)
    end)
    if ok and ver then
        ver = ver:match("[%d.]+")
        return ver or VERSION
    end
    return VERSION
end

local latestVer = getLatestVersion()
if latestVer ~= VERSION then
    print("itayoHub: Update tersedia v" .. latestVer .. " (lo: v" .. VERSION .. ")")
    print("itayoHub: Download versi terbaru...")
else
    print("itayoHub: Versi terbaru v" .. VERSION)
end

-- Download dari source chain
local function download()
    for _, url in ipairs(CHEAT_SOURCES) do
        local ok, code = pcall(function()
            return game:HttpGet(url)
        end)
        if ok and code and #code > 1000 then
            return code, url
        end
    end
    return nil, nil
end

local code, usedUrl = download()
if code then
    local sourceName = usedUrl:match("github%.com/(.+)") or usedUrl:match("gitlab%.com/(.+)") or usedUrl
    print("itayoHub: Loaded from " .. sourceName)
    loadstring(code)()
else
    print("╔══════════════════════════════════╗")
    print("║  GAGAL download itayoHub!        ║")
    print("║  Cek: github.com/" .. REPO .. "    ║")
    print("║  Atau hubungi support.           ║")
    print("╚══════════════════════════════════╝")
end
