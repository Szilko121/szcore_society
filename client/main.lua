local opened=false
local current=nil
local function notify(text,typ) exports.szcore_ui:Notify({description=text,type=typ or 'info'}) end
local function inferSociety()
    local p=exports.szcore:GetPlayerData()
    if p.job and p.job.boss then return p.job.name end
    if p.gang and p.gang.boss then return p.gang.name end
end
local function refresh()
    if not current then return end
    local data,err=exports.szcore:AwaitCallback('szcore_society:dashboard',current)
    if not data then notify(err or 'Nincs hozzáférés.','error');return end
    SendNUIMessage({action='data',data=data})
end
local function open(name)
    name=name or inferSociety();if not name then return notify('Nincs kezelhető szervezeted.','error') end
    local data,err=exports.szcore:AwaitCallback('szcore_society:dashboard',name)
    if not data then return notify(err or 'Nincs hozzáférés.','error') end
    current=name;opened=true;SetNuiFocus(true,true);SendNUIMessage({action='open',data=data})
end
local function close() opened=false;current=nil;SetNuiFocus(false,false);SendNUIMessage({action='close'}) end
RegisterCommand(SzCoreSocietyConfig.command,function()if SzCoreSocietyConfig.allowCommandAnywhere then open()else notify('A vezetői panelt a kijelölt ponton használhatod.','error')end end,false)
RegisterKeyMapping(SzCoreSocietyConfig.command,'SzCore vezetői panel','keyboard',SzCoreSocietyConfig.key)
RegisterNUICallback('close',function(_,cb)close();cb({ok=true})end)
RegisterNUICallback('refresh',function(_,cb)refresh();cb({ok=true})end)
RegisterNUICallback('action',function(data,cb)
    local ok,err=exports.szcore:AwaitCallback('szcore_society:action',current,data.action,data)
    if ok then refresh();notify('Művelet sikeres.','success') else notify(err or 'A művelet sikertelen.','error') end
    cb({ok=ok,error=err})
end)
local managementZones={}
local function buildManagementZones()
    if GetResourceState('szcore_interact')~='started' then return end
    for _,id in ipairs(managementZones) do exports.szcore_interact:RemoveZone(id) end;managementZones={}
    for name,points in pairs(SzCoreSocietyConfig.menus or {}) do for i,c in ipairs(points) do
        managementZones[#managementZones+1]=exports.szcore_interact:AddSphereZone({name=('szcore_society_%s_%d'):format(name,i),coords=c,radius=1.3,distance=2.0,groups={[name]=0},options={{label='Vezetői panel',icon='briefcase',callback=function()open(name)end}}})
    end end
end
AddEventHandler('onClientResourceStart',function(res)if res=='szcore_interact' or res==GetCurrentResourceName() then SetTimeout(800,buildManagementZones)end end)
exports('OpenSociety',open)
