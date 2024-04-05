local component=require("component")
local os=require("os")
local computer=require("computer")
local tty=require("tty")
local term=require("term")
local mi=component.me_interface
local inet=component.internet
local fs=component.filesystem
local br=component.br_reactor

local reset="\027[0m"
local red="\027[31m"
local green="\027[32m"
local yellow="\027[33m"
local blue="\027[34m"
local magenta="\027[35m"
local cyan="\027[36m"

local displayitems={"minecraft:diamond","industrialforegoing:plastic","minecraft:gold_ingot","bigreactors:ingotyellorium"}
local displayfluids={"xpjuice","latex","oil","lubricant","liquiddeuterium","liquidtritium"}
--[[
local displayfluids={}
for i,j in ipairs(mi.getFluidsInNetwork()) do
    displayfluids[#displayfluids+1]=j["name"]
end
]]--

local function log(name,info,color)
    term.clearLine()
    print(string.format("%s%s%s: %s",color,name,reset,info))
end

local function new_line()
    term.clearLine()
    print()
end

tty.clear()
while (true) do
    tty.setCursor(0,0)
    local items=mi.getItemsInNetwork()
    local fluids=mi.getFluidsInNetwork()
    local cpus=mi.getCpus()
    local idlecpus=0
    local busycpus=0
    for i,j in ipairs(cpus) do
        if j["busy"] then
            busycpus=busycpus+1
        end
    end
    idlecpus=#cpus-busycpus
    log("Applied Energistics 2 ME Network Status","",magenta)
    new_line()
    log("Energy Usage",string.format("%.1f AE/t",mi.getAvgPowerUsage()),cyan)
    log("Crafting CPUs(Idle / Busy / Total)",string.format("%d %s/%s %d %s/%s %d",idlecpus,yellow,reset,busycpus,yellow,reset,#cpus),cyan)
    new_line()
    log("Items","",green)
    for i,j in ipairs(items) do
        for k,v in pairs(displayitems) do
            if j["name"]==v then
                local size=items[i]["size"]
                log(string.format("%s (%s)",items[i]["label"],v),string.format("%.1fk(%d)",size/1000,size),cyan)
            end
        end
    end
    new_line()
    log("Fluids","",green)
    for i,j in ipairs(fluids) do
        for k,v in pairs(displayfluids) do
            if j["name"]==v then
                local amount=fluids[i]["amount"]
                log(string.format("%s (%s)",fluids[i]["label"],v),string.format("%.1f Bucket(s)(%.0f mB)",amount/1000,amount),cyan)
            end
        end
    end
    new_line()
    log("Big Reactors Status","",magenta)
    new_line()
    log("Energy Output",string.format("%.0f RF/t",br.getEnergyProducedLastTick()),cyan)
    log("Fuel Burnup Rate",string.format("%.1f mB/t",br.getFuelConsumedLastTick()),cyan)
    log("Fuel Reactivity",string.format("%.1f%%",br.getFuelReactivity()),cyan)
    log("Core Temperature",string.format("%.1f C",br.getFuelTemperature()),cyan)
    log("Casing Temperature",string.format("%.1f C",br.getCasingTemperature()),cyan)
    new_line()
    log("OpenComputers Server Status","",magenta)
    new_line()
    log("Minecraft Date & Time(1970-01-01 06:00 when the world was created)",os.date("%Y-%m-%d %H:%M"),cyan)
    log("Uptime",string.format("%.1fs",computer.uptime()),cyan)
    local totalmem=computer.totalMemory()
    local usedmem=totalmem-computer.freeMemory()
    log("Memory",string.format("%.1f KiB %s/%s %.1f KiB",usedmem/1024,yellow,reset,totalmem/1024),cyan)
    log("Energy",string.format("%.1f RF %s/%s %.1f RF",computer.energy()*10,yellow,reset,computer.maxEnergy()*10),cyan)
    new_line()
    log("Filesystems","",green)
    for i,j in component.list("filesystem") do
        local fs=component.proxy(i)
        local mountopts="rw"
        if fs.isReadOnly() then
            mountopts="ro"
        end
        log(fs.getLabel(),string.format("%.1f KiB %s/%s %.1f KiB %s",fs.spaceUsed()/1024,yellow,reset,fs.spaceTotal()/1024,mountopts),cyan)
    end
    new_line()
    log("Real Server Status","",magenta)
    new_line()
    local req=inet.request("http://127.0.0.1:19198/sysinfo")
    req.read()
    term.write("\r\027[2K" .. req.read())
    os.sleep(5)
end
