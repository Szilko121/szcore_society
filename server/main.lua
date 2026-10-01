local function registerSzCoreCallback(name, fn)
    CreateThread(function()
        local deadline = GetGameTimer() + 15000

        while GetGameTimer() < deadline do
            if GetResourceState('szcore') == 'started' then
                local ok, success, err = pcall(function()
                    return exports['szcore']:CreateCallback(name, fn)
                end)

                if ok and success ~= false then
                    return
                end

                if ok and success == false then
                    print(('[%s] SzCore callback registration rejected: %s (%s)'):format(
                        GetCurrentResourceName(),
                        tostring(name),
                        tostring(err)
                    ))
                    return
                end
            end

            Wait(100)
        end

        print(('[%s] SzCore callback registration timed out: %s'):format(
            GetCurrentResourceName(),
            tostring(name)
        ))
    end)
end

local S = {}
local actionRate = {}
local function account(name) return 'society:' .. name end
local function getDef(kind,name) return kind == 'gang' and exports.szcore:GetGang(name) or exports.szcore:GetJob(name) end
local function onlineByCid(cid) return exports.szcore:GetPlayerByCitizenId(cid) end
local function rate(src,key,ms)
    local now=GetGameTimer(); actionRate[src]=actionRate[src] or {}
    local p=actionRate[src][key] or 0; if now-p<ms then return false end
    actionRate[src][key]=now; return true
end
local function societyRow(name) return MySQL.single.await('SELECT * FROM szcore_societies WHERE name=?',{name}) end
local function access(source,name,write)
    local p=exports.szcore:GetPlayer(source); if not p then return nil,'player_not_found' end
    local row=societyRow(name); if not row then return nil,'society_not_found' end
    local group=row.society_type=='gang' and p.PlayerData.gang or p.PlayerData.job
    if not group or group.name~=name then return nil,'not_member' end
    if write and SzCoreSocietyConfig.bossOnly and not group.boss then return nil,'not_boss' end
    return p,row,group
end
local function charName(row) return ((row.firstname or '')..' '..(row.lastname or '')):gsub('^%s+',''):gsub('%s+$','') end
local function decorateMember(row,kind,name)
    local p=onlineByCid(row.citizenid)
    local def=getDef(kind,name); local grade=def and def.grades[tonumber(row.grade) or 0]
    row.online=p~=nil; row.source=p and p.PlayerData.source or nil
    row.name=row.name or row.citizenid; row.gradeLabel=grade and (grade.name or grade.label) or tostring(row.grade)
    return row
end
function S.ensure(name,label,kind)
    if type(name)~='string' or name=='' then return false end
    kind=(kind=='gang') and 'gang' or 'job'
    exports.szcore:EnsureAccount(account(name),'society',name,label or name,0,false)
    MySQL.prepare.await([[INSERT INTO szcore_societies (name,label,society_type,account_id) VALUES (?,?,?,?)
      ON DUPLICATE KEY UPDATE label=VALUES(label),society_type=VALUES(society_type)]],{name,label or name,kind,account(name)})
    return true
end
function S.get(name)
    local s=societyRow(name); if not s then return nil end
    s.account=exports.szcore:GetAccount(s.account_id)
    local rows=MySQL.query.await([[SELECT m.*,c.firstname,c.lastname FROM szcore_society_members m
      LEFT JOIN szcore_characters c ON c.citizenid=m.citizenid WHERE m.society=? ORDER BY m.grade DESC,c.firstname,c.lastname]],{name}) or {}
    for i=1,#rows do rows[i].name=charName(rows[i]);decorateMember(rows[i],s.society_type,name) end
    s.members=rows
    return s
end
function S.deposit(name,value,actor)
    local n=math.floor(tonumber(value) or 0);if n<=0 then return false,'invalid_amount' end
    return exports.szcore:ChangeAccountBalance(account(name),n,'society_deposit',actor)
end
function S.withdraw(name,value,actor)
    local n=math.floor(tonumber(value) or 0);if n<=0 then return false,'invalid_amount' end
    return exports.szcore:ChangeAccountBalance(account(name),-n,'society_withdraw',actor)
end
function S.hire(name,citizenid,grade,actor,primary)
    local row=societyRow(name); if not row then return false,'society_not_found' end
    grade=tonumber(grade) or 0;local def=getDef(row.society_type,name);if not def or not def.grades[grade] then return false,'invalid_group' end
    local online=onlineByCid(citizenid);local ok,err
    local kind=row.society_type=='gang' and 'gangs' or 'jobs'
    if online then ok,err=online.addGroup(kind,name,grade,false,primary==true)
    else ok,err=exports.szcore:AddOfflineGroup(citizenid,row.society_type,name,grade,false,primary==true) end
    if not ok then return false,err end
    MySQL.prepare.await([[INSERT INTO szcore_society_members (society,citizenid,grade) VALUES (?,?,?)
      ON DUPLICATE KEY UPDATE grade=VALUES(grade)]],{name,citizenid,grade})
    exports.szcore:Audit('society.hire',actor or 'system',citizenid,{society=name,grade=grade})
    return true
end
function S.fire(name,citizenid,actor)
    local row=societyRow(name);if not row then return false,'society_not_found' end
    local p=onlineByCid(citizenid);local ok=true;local kind=row.society_type=='gang' and 'gangs' or 'jobs'
    if p then
        local bucket=p.PlayerData.groups and p.PlayerData.groups[kind];local member=bucket and bucket[name]
        if member then
            if member.primary then
                if row.society_type=='gang' then p.setGang('none',0) else p.setJob('unemployed',0,false) end
            end
            ok=p.removeGroup(kind,name)~=false
        end
    else
        local data=exports.szcore:GetOfflinePlayerData(citizenid);if not data then return false,'player_not_found' end
        if row.society_type=='job' and data.job==name then exports.szcore:SetOfflineJob(citizenid,'unemployed',0,false) end
        if row.society_type=='gang' and data.gang==name then exports.szcore:SetOfflineGang(citizenid,'none',0) end
        local removed,err=exports.szcore:RemoveOfflineGroup(citizenid,row.society_type,name);if removed==false and err~='not_member' then ok=false end
    end
    if not ok then return false,'group_update_failed' end
    MySQL.update.await('DELETE FROM szcore_society_members WHERE society=? AND citizenid=?',{name,citizenid})
    exports.szcore:Audit('society.fire',actor or 'system',citizenid,{society=name})
    return true
end
function S.setGrade(name,citizenid,grade,actor)
    local row=societyRow(name); if not row then return false,'society_not_found' end
    grade=tonumber(grade) or 0;local def=getDef(row.society_type,name);if not def or not def.grades[grade] then return false,'invalid_grade' end
    local p=onlineByCid(citizenid);local ok;local kind=row.society_type=='gang' and 'gangs' or 'jobs'
    if p then
        local member=p.PlayerData.groups and p.PlayerData.groups[kind] and p.PlayerData.groups[kind][name];if not member then return false,'not_member' end
        if member.primary then
            if row.society_type=='gang' then ok=p.setGang(name,grade) else ok=p.setJob(name,grade,p.PlayerData.job.onduty) end
        else ok=p.addGroup(kind,name,grade,member.duty,false) end
    else
        local data=exports.szcore:GetOfflinePlayerData(citizenid);if not data then return false,'player_not_found' end
        if row.society_type=='job' and data.job==name then ok=exports.szcore:SetOfflineJob(citizenid,name,grade,data.job_duty==true or data.job_duty==1)
        elseif row.society_type=='gang' and data.gang==name then ok=exports.szcore:SetOfflineGang(citizenid,name,grade)
        else ok=exports.szcore:AddOfflineGroup(citizenid,row.society_type,name,grade,false,false) end
    end
    if not ok then return false,'group_update_failed' end
    MySQL.prepare.await([[INSERT INTO szcore_society_members (society,citizenid,grade) VALUES (?,?,?)
      ON DUPLICATE KEY UPDATE grade=VALUES(grade)]],{name,citizenid,grade})
    exports.szcore:Audit('society.grade',actor or 'system',citizenid,{society=name,grade=grade})
    return true
end
function S.transactions(name,limit)return exports.szcore:GetAccountTransactions(account(name),math.min(tonumber(limit) or 50,SzCoreSocietyConfig.maxTransactionHistory))end
local function dashboard(source,name)
    local p,row,group=access(source,name,false);if not p then return nil,row end
    local s=S.get(name); local def=getDef(row.society_type,name); local grades={}
    if def and def.grades then
        for grade,g in pairs(def.grades) do grades[#grades+1]={grade=tonumber(grade),label=g.name or g.label or tostring(grade),boss=g.boss==true} end
        table.sort(grades,function(a,b)return a.grade<b.grade end)
    end
    local candidates={}
    for _,sid in ipairs(exports.szcore:GetPlayerSources()) do
        if sid~=source and exports.szcore:ValidateDistance(source,sid,SzCoreSocietyConfig.nearbyHireDistance) then
            local q=exports.szcore:GetPlayer(sid)
            if q then candidates[#candidates+1]={source=sid,citizenid=q.PlayerData.citizenid,name=q.PlayerData.name} end
        end
    end
    return {society={name=row.name,label=row.label,type=row.society_type},balance=(s.account and tonumber(s.account.balance)) or 0,canManage=group.boss==true,members=s.members,grades=grades,candidates=candidates,transactions=S.transactions(name,50),player={cash=p.PlayerData.money.cash,bank=p.PlayerData.money.bank,job=p.PlayerData.job,gang=p.PlayerData.gang}}
end
local function action(source,name,action,data)
    if not rate(source,'action',180) then return false,'rate_limited' end
    local p,row=access(source,name,true);if not p then return false,row end
    data=type(data)=='table' and data or {}
    if action=='deposit' then
        local n=math.floor(tonumber(data.amount) or 0);if n<=0 then return false,'invalid_amount' end
        return exports.szcore:TransferMoney({kind='player',id=p.PlayerData.citizenid,account='bank'},{kind='account',id=account(name)},n,'society_deposit',p.PlayerData.citizenid)
    elseif action=='withdraw' then
        local n=exports.szcore:ValidateInteger(data.amount,1,9000000000000);if not n then return false,'invalid_amount' end
        return exports.szcore:TransferMoney({kind='account',id=account(name)},{kind='player',id=p.PlayerData.citizenid,account='bank'},n,'society_withdraw',p.PlayerData.citizenid)
    elseif action=='hire' then
        local target=tonumber(data.source);if not target or not exports.szcore:ValidateDistance(source,target,SzCoreSocietyConfig.nearbyHireDistance) then return false,'target_too_far' end
        local q=exports.szcore:GetPlayer(target);if not q then return false,'player_not_found' end
        return S.hire(name,q.PlayerData.citizenid,tonumber(data.grade) or 0,p.PlayerData.citizenid,false)
    elseif action=='fire' then
        if data.citizenid==p.PlayerData.citizenid then return false,'cannot_fire_self' end
        return S.fire(name,tostring(data.citizenid or ''),p.PlayerData.citizenid)
    elseif action=='grade' then
        if data.citizenid==p.PlayerData.citizenid then return false,'cannot_grade_self' end
        return S.setGrade(name,tostring(data.citizenid or ''),tonumber(data.grade),p.PlayerData.citizenid)
    end
    return false,'invalid_action'
end
CreateThread(function()
    while not exports.szcore:IsReady()do Wait(100)end
    for name,job in pairs(exports.szcore:GetJobs()) do if name~='unemployed' then S.ensure(name,job.label,'job') end end
    for name,gang in pairs(exports.szcore:GetGangs()) do if name~='none' then S.ensure(name,gang.label,'gang') end end
end)
registerSzCoreCallback('szcore_society:dashboard',dashboard)
registerSzCoreCallback('szcore_society:action',action)
exports('EnsureSociety',S.ensure);exports('GetSociety',S.get);exports('Deposit',S.deposit);exports('Withdraw',S.withdraw)
exports('Hire',S.hire);exports('Fire',S.fire);exports('SetGrade',S.setGrade);exports('GetTransactions',S.transactions)
AddEventHandler('playerDropped',function()actionRate[source]=nil end)
