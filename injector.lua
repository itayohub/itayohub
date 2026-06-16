-- itayoHub Loader v1.0 — Layer 1: injector
-- Ini doang yg di-paste user ke executor
-- Ukuran: ~700 byte, gampang di-rehost kalo kena DMCA

local LAYERS = {
    primary  = "https://raw.githubusercontent.com/itayohub/itayohub/main/loader.lua",
    fallback = "https://raw.githubusercontent.com/itayohub/itayohub/main/itayohub.lua",
}

local function try(url)
    local ok, result = pcall(function()
        return game:HttpGet(url)
    end)
    return ok and result or nil
end

-- Coba primary loader dulu, fallback ke langsung
local code = try(LAYERS.primary) or try(LAYERS.fallback)
if code then
    loadstring(code)()
else
    print("itayoHub: Gagal download loader. Cek koneksi atau hubungi support.")
end
