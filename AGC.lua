-- DCS 机场地面控制
-- DCS Airfield Ground Controller
-- Version 1.0
-- By Dennic

agc  = {}


-- 最大停止移动时间（秒）
-- maxStopTime (Seconds)
agc.maxStopTime = 60

-- 最大滑行速度和警示滑行速度（节）
-- maxTexiSpeed and noticeTexiSpeed (Knots)
agc.maxTexiSpeed = 40
agc.noticeTexiSpeed = 30

-- 警示音
-- notification
agc.playSound = true -- 是否开启超速提示音
agc.soundNotice = "notice.ogg"

-- 第一个"%i"是当前值, 第二个"%i"是限制值
-- the first "%i" is for current value, and the secend is for limit value
agc.stoppedNotice = "【注意】 你已停止移动 %i 秒！\n在滑行道或跑道上停止移动超过 %i 秒，你将会被取消飞行资格。"
agc.overspeedNotice = "【注意】你当前速度 %i 节。即将超速，请控制速度！\n地面滑行速度严禁超过 %i 节，否则你将会被取消飞行资格。"

-- 最高监测高度（离地高度）
-- max monitor altitude (AGL)
agc.maxAlt = 10

agc.BlueTexiway = {

    {
        name = "BlueTexiway1",
        maxAlt = 10 -- ( 可选参数 ) 区域监测高度，将会覆盖 "agc.maxAlt" 。    Will override "agc.maxAlt" for this area.
    },
    {
        name = "BlueTexiway2",
    },
    {
        name = "BlueTexiway3",
    },
    {
        name = "BlueTexiway4",
    },
    {
        name = "BlueTexiway5",
    },

}

agc.BlueRamp = {

    {
        name = "BlueRamp1",
    },
    {
        name = "BlueRamp2",
    },
    {
        name = "BlueRamp3",
    },
    {
        name = "BlueRamp4",
    },
    {
        name = "BlueRamp5",
    },

}

agc.BlueRunway = {

    {
        name = "BlueRunway1",
    },
    {
        name = "BlueRunway2",
    },
    {
        name = "BlueRunway3",
    },
    {
        name = "BlueRunway4",
    },
    {
        name = "BlueRunway5",
    },

}

agc.RedTexiway = {

    {
        name = "RedTexiway1",
    },
    {
        name = "RedTexiway2",
    },
    {
        name = "RedTexiway3",
    },
    {
        name = "RedTexiway4",
    },
    {
        name = "RedTexiway5",
    },

}

agc.RedRamp = {

    {
        name = "RedRamp1",
    },
    {
        name = "RedRamp2",
    },
    {
        name = "RedRamp3",
    },
    {
        name = "RedRamp4",
    },
    {
        name = "RedRamp5",
    },

}

agc.RedRunway = {

    {
        name = "RedRunway1",
    },
    {
        name = "RedRunway2",
    },
    {
        name = "RedRunway3",
    },
    {
        name = "RedRunway4",
    },
    {
        name = "RedRunway5",
    },

}


function agc.getActiveUnit(_unitName)

    if _unitName == nil then
        return nil
    end

    local _unit = Unit.getByName(_unitName)

    if _unit ~= nil and _unit:isActive() and _unit:getLife() > 0 then

        return _unit
    end

    return nil
    
end






agc.playSoundUnits = {}

function agc.noticeSound(_unit , _remove)

    if _remove == false then
        if agc.playSoundUnits[tostring(_unit:getID())] then
            agc.playSoundUnits[tostring(_unit:getID())] = nil
        end
    else
        if not agc.playSoundUnits[tostring(_unit:getID())] then
            agc.playSoundUnits[tostring(_unit:getID())] = _unit
        end
    end
            
end

function agc.playNoticeSound()

    for _,_unit in pairs(agc.playSoundUnits) do
        if _unit then
            trigger.action.outSoundForGroup(_unit:getGroup():getID(), agc.soundFile )
            agc.noticeSound(_unit , false)
        end
    end
    mist.scheduleFunction(agc.playNoticeSound, nil, timer.getTime() + 1)
end




function agc.displayNotice(_unit, _text, _time, _type, _playsound)

    local msg = {} 
    msg.text = _text
    msg.displayTime = _time
    msg.msgFor = {units = { _unit:getName() }}
    msg.name = _unit:getName() .. _type
    mist.message.add(msg)
    
    if _playsound and agc.playSound then
        agc.noticeSound(_unit)
    end
    
end









agc.stoppedUnits = {}

function agc.noticeStopped()

    for _,_unitObj in pairs(agc.stoppedUnits) do
        if _unitObj then
            local _newTime = _unitObj.stopTime + 1
            local _unit = _unitObj.unit
            if _newTime > agc.maxStopTime then
                _unitObj = nil
                _unit:destroy()
            else
                agc.displayNotice(_unit, string.format(agc.stoppedNotice, _newTime, agc.maxStopTime), 1, "noticeUnitStopped", false)
                _unitObj.stopTime = _newTime
            end
        end
    end
    
    mist.scheduleFunction(agc.noticeStopped, nil, timer.getTime() + 1)
end

function agc.unitStopped(_unit, _isStopped)

    if _isStopped then
        if not agc.stoppedUnits[tostring(_unit:getID())] then
            agc.stoppedUnits[tostring(_unit:getID())] = {unit = _unit,stopTime = 0}
        end
    else
        if agc.stoppedUnits[tostring(_unit:getID())] then
            agc.stoppedUnits[tostring(_unit:getID())] = nil
        end
    end
            
end







function agc.checkTraffic()

    local _bluePlanes = mist.makeUnitTable({"[blue][plane]"})
    local _redPlanes = mist.makeUnitTable({"[red][plane]"})
    local _overspeedUnit = {}
    local _noticeUnit = {}
    local _stoppedUnit = {}

    for _,_blueTexiway in pairs(agc.BlueTexiway) do
        if _blueTexiway.polygon then
        
            local _units = mist.getUnitsInPolygon(_bluePlanes, _blueTexiway.polygon, _blueTexiway.maxAlt)
            for __,_unit in pairs(_units) do
            
                if _unit:isActive() and _unit:getLife() > 0 then
                    local _unitData = mist.utils.unitToWP( _unit )
                    local _unitSpeed = math.floor(mist.utils.mpsToKnots(_unitData["speed"]))
                    if _unitSpeed == 0 then
                        _stoppedUnit[#_stoppedUnit+1] = _unit
                    elseif _unitSpeed > agc.noticeTexiSpeed and _unitSpeed <= agc.maxTexiSpeed then
                        _noticeUnit[#_noticeUnit+1] = {unit = _unit,speed = _unitSpeed}
                    elseif _unitSpeed > agc.maxTexiSpeed then
                        _overspeedUnit[#_overspeedUnit+1] = _unit
                    else
                        agc.unitStopped(_unit, false)
                    end
                end
            end
        end
    end
    
    for _,_redTexiway in pairs(agc.RedTexiway) do
        if _redTexiway.polygon then
        
            local _units = mist.getUnitsInPolygon(_redPlanes, _redTexiway.polygon, _redTexiway.maxAlt)
            for __,_unit in pairs(_units) do
            
                if _unit:isActive() and _unit:getLife() > 0 then
                    local _unitData = mist.utils.unitToWP( _unit )
                    local _unitSpeed = math.floor(mist.utils.mpsToKnots(_unitData["speed"]))
                    if _unitSpeed == 0 then
                        _stoppedUnit[#_stoppedUnit+1] = _unit
                    elseif _unitSpeed > agc.noticeTexiSpeed and _unitSpeed <= agc.maxTexiSpeed then
                        _noticeUnit[#_noticeUnit+1] = {unit = _unit,speed = _unitSpeed}
                    elseif _unitSpeed > agc.maxTexiSpeed then
                        _overspeedUnit[#_overspeedUnit+1] = _unit
                    else
                        agc.unitStopped(_unit, false)
                    end
                end
            end
        end
    end
    
    for _,_blueRamp in pairs(agc.BlueRamp) do
        if _blueRamp.polygon then
        
            local _units = mist.getUnitsInPolygon(_bluePlanes, _blueRamp.polygon, _blueRamp.maxAlt)
            for __,_unit in pairs(_units) do
            
                if _unit:isActive() and _unit:getLife() > 0 then
                    local _unitData = mist.utils.unitToWP( _unit )
                    local _unitSpeed = math.floor(mist.utils.mpsToKnots(_unitData["speed"]))
                    if _unitSpeed > agc.noticeTexiSpeed and _unitSpeed <= agc.maxTexiSpeed then
                        _noticeUnit[#_noticeUnit+1] = {unit = _unit,speed = _unitSpeed}
                    elseif _unitSpeed > agc.maxTexiSpeed then
                        _overspeedUnit[#_overspeedUnit+1] = _unit
                    end
                end
            end
        end
    end
    
    for _,_redRamp in pairs(agc.RedRamp) do
        if _redRamp.polygon then
        
            local _units = mist.getUnitsInPolygon(_redPlanes, _redRamp.polygon, _redRamp.maxAlt)
            for __,_unit in pairs(_units) do
            
                if _unit:isActive() and _unit:getLife() > 0 then
                    local _unitData = mist.utils.unitToWP( _unit )
                    local _unitSpeed = math.floor(mist.utils.mpsToKnots(_unitData["speed"]))
                    if _unitSpeed > agc.noticeTexiSpeed and _unitSpeed <= agc.maxTexiSpeed then
                        _noticeUnit[#_noticeUnit+1] = {unit = _unit,speed = _unitSpeed}
                    elseif _unitSpeed > agc.maxTexiSpeed then
                        _overspeedUnit[#_overspeedUnit+1] = _unit
                    end
                end
            end
        end
    end

    for _,_blueRunway in pairs(agc.BlueRunway) do
        if _blueRunway.polygon then
        
            local _units = mist.getUnitsInPolygon(_bluePlanes, _blueRunway.polygon, _blueRunway.maxAlt)
            for __,_unit in pairs(_units) do
            
                if _unit:isActive() and _unit:getLife() > 0 then
                    local _unitData = mist.utils.unitToWP( _unit )
                    local _unitSpeed = math.floor(mist.utils.mpsToKnots(_unitData["speed"]))
                    if _unitSpeed == 0 then
                        _stoppedUnit[#_stoppedUnit+1] = _unit
                    else
                        agc.unitStopped(_unit, false)
                    end
                end
            end
        end
    end

    for _,_redRunway in pairs(agc.RedRunway) do
        if _redRunway.polygon then
        
            local _units = mist.getUnitsInPolygon(_redPlanes, _redRunway.polygon, _redRunway.maxAlt)
            for __,_unit in pairs(_units) do
            
                if _unit:isActive() and _unit:getLife() > 0 then
                    local _unitData = mist.utils.unitToWP( _unit )
                    local _unitSpeed = math.floor(mist.utils.mpsToKnots(_unitData["speed"]))
                    if _unitSpeed == 0 then
                        _stoppedUnit[#_stoppedUnit+1] = _unit
                    else
                        agc.unitStopped(_unit, false)
                    end
                end
            end
        end
    end
    
    for _,_unit in pairs(_overspeedUnit) do
        _unit:destroy()
    end
    
    for _,_unit in pairs(_noticeUnit) do
        agc.displayNotice(_unit.unit, string.format(agc.overspeedNotice, _unit.speed, agc.maxTexiSpeed), 1, "noticeTexiSpeed", true)
    end
    
    for _,_unit in pairs(_stoppedUnit) do
        agc.unitStopped(_unit, true)
    end
    
    
    mist.scheduleFunction(agc.checkTraffic, {}, timer.getTime() + 0.1)

end





function agc.checkEjection(_unit)

    local _unitPos = _unit:getPosition().p
    local _unitSide = _unit:getCoalition()
    
    if _unitSide == 1 then -- Red
    
        for _,_redTexiway in pairs(agc.RedTexiway) do
            if _redTexiway.polygon then
                if mist.pointInPolygon(_unitPos, _redTexiway.polygon, _redTexiway.maxAlt) then
                    return true
                end
            end
        end
        
        for _,_redRamp in pairs(agc.RedRamp) do
            if _redRamp.polygon then
                if mist.pointInPolygon(_unitPos, _redRamp.polygon, _redRamp.maxAlt) then
                    return true
                end
            end
        end
        
        for _,_redRunway in pairs(agc.RedRunway) do
            if _redRunway.polygon then
                if mist.pointInPolygon(_unitPos, _redRunway.polygon, _redRunway.maxAlt) then
                    return true
                end
            end
        end
    
    
    
    
    elseif _unitSide == 2 then -- Blue
        
        for _,_blueTexiway in pairs(agc.BlueTexiway) do
            if _blueTexiway.polygon then
                if mist.pointInPolygon(_unitPos, _blueTexiway.polygon, _blueTexiway.maxAlt) then
                    return true
                end
            end
        end
        
        for _,_blueRamp in pairs(agc.BlueRamp) do
            if _blueRamp.polygon then
                if mist.pointInPolygon(_unitPos, _blueRamp.polygon, _blueRamp.maxAlt) then
                    return true
                end
            end
        end
        
        for _,_blueRunway in pairs(agc.BlueRunway) do
            if _blueRunway.polygon then
                if mist.pointInPolygon(_unitPos, _blueRunway.polygon, _blueRunway.maxAlt) then
                    return true
                end
            end
        end

    end
    
    return false
end


-- Handle world events
function agc.eventHandler(_event)

    if _event == nil or _event.initiator == nil then
        return false

    elseif _event.id == 6 then --ejection

        if  _event.initiator:getName() then

            if agc.checkEjection(_event.initiator) then
                _event.initiator:destroy()
            end

        end
        
    end
        
end











for _,_blueTexiway in pairs(agc.BlueTexiway) do

    if Group.getByName(_blueTexiway.name) then
        local _points = mist.getGroupPoints(_blueTexiway.name)
        _blueTexiway.polygon = _points
        local _landAlt = land.getHeight(_points[1])
        if _blueTexiway.maxAlt then
            _blueTexiway.maxAlt = _landAlt + _blueTexiway.maxAlt
        else
            _blueTexiway.maxAlt = _landAlt + agc.maxAlt
        end
    else
        _blueTexiway.polygon = nil
    end
    
end

for _,_blueRamp in pairs(agc.BlueRamp) do

    if Group.getByName(_blueRamp.name) then
        local _points = mist.getGroupPoints(_blueRamp.name)
        _blueRamp.polygon = _points
        local _landAlt = land.getHeight(_points[1])
        if _blueRamp.maxAlt then
            _blueRamp.maxAlt = _landAlt + _blueRamp.maxAlt
        else
            _blueRamp.maxAlt = _landAlt + agc.maxAlt
        end
    else
        _blueRamp.polygon = nil
    end
    
end

for _,_blueRunway in pairs(agc.BlueRunway) do

    if Group.getByName(_blueRunway.name) then
        local _points = mist.getGroupPoints(_blueRunway.name)
        _blueRunway.polygon = _points
        local _landAlt = land.getHeight(_points[1])
        if _blueRunway.maxAlt then
            _blueRunway.maxAlt = _landAlt + _blueRunway.maxAlt
        else
            _blueRunway.maxAlt = _landAlt + agc.maxAlt
        end
    else
        _blueRunway.polygon = nil
    end
    
end

for _,_redTexiway in pairs(agc.RedTexiway) do

    if Group.getByName(_redTexiway.name) then
        local _points = mist.getGroupPoints(_redTexiway.name)
        _redTexiway.polygon = _points
        local _landAlt = land.getHeight(_points[1])
        if _redTexiway.maxAlt then
            _redTexiway.maxAlt = _landAlt + _redTexiway.maxAlt
        else
            _redTexiway.maxAlt = _landAlt + agc.maxAlt
        end
    else
        _redTexiway.polygon = nil
    end
    
end

for _,_redRamp in pairs(agc.RedRamp) do

    if Group.getByName(_redRamp.name) then
        local _points = mist.getGroupPoints(_redRamp.name)
        _redRamp.polygon = _points
        local _landAlt = land.getHeight(_points[1])
        if _redRamp.maxAlt then
            _redRamp.maxAlt = _landAlt + _redRamp.maxAlt
        else
            _redRamp.maxAlt = _landAlt + agc.maxAlt
        end
    else
        _redRamp.polygon = nil
    end
    
end

for _,_redRunway in pairs(agc.RedRunway) do

    if Group.getByName(_redRunway.name) then
        local _points = mist.getGroupPoints(_redRunway.name)
        _redRunway.polygon = _points
        local _landAlt = land.getHeight(_points[1])
        if _redRunway.maxAlt then
            _redRunway.maxAlt = _landAlt + _redRunway.maxAlt
        else
            _redRunway.maxAlt = _landAlt + agc.maxAlt
        end
    else
        _redRunway.polygon = nil
    end
    
end




function agc.setNoticeSound(_filename)
    agc.soundFile = "l10n/DEFAULT/".._filename
end


mist.scheduleFunction(agc.checkTraffic, nil, timer.getTime() + 1)
mist.scheduleFunction(agc.noticeStopped, nil, timer.getTime() + 1)
if agc.playSound then
    agc.soundFile = "l10n/DEFAULT/"..agc.soundNotice
    mist.scheduleFunction(agc.playNoticeSound, nil, timer.getTime() + 1)
end

mist.addEventHandler(agc.eventHandler)