reactor = peripheral.wrap("Back")
monitor = peripheral.wrap("Bottom")
redstoneOutputDirection = "Right"

burnRate = 0
burnRateLimit = 20

isReactorOn = false

dangerLevels = {
    NONE = -1,
    GOOD = 0,
    BAD = 1,
    RISKY = 2,
    CRITICAL = 3,
}
dangerLevel = dangerLevels.NONE
lastDangerState = dangerLevel

heatingRate = -1

damage = -1
coolant = -1
fuel = -1
heatedCoolant = -1
waste = -1

function handleChanges()
    handleDamage()
    handleCoolant()
    handleFuel()
    handleHeatedCoolant()
    handleWaste()
    handleHeatingRate()
    handleDangerState()
    handleReactorState()
    handleRateLimit()
    handleBurnRate()
end

function hasDamageChanged()
    return damage ~= reactor.getDamagePercent()
end

function handleDamage()
    if (not hasDamageChanged())
    then
        return
    end
    damage = reactor.getDamagePercent()
    displayDamage()
end

function hasCoolantChanged()
    return coolant ~= reactor.getCoolantFilledPercentage()
end

function handleCoolant()
    if (not hasCoolantChanged())
    then
        return
    end
    coolant = reactor.getCoolantFilledPercentage()
    displayCoolant()
end

function hasFuelChanged()
    return fuel ~= reactor.getFuelFilledPercentage()
end

function handleFuel()
    if (not hasFuelChanged())
    then
        return
    end
    fuel = reactor.getFuelFilledPercentage()
    displayFuel()
end

function hasHeatedCoolantChanged()
    return heatedCoolant ~= reactor.getHeatedCoolantFilledPercentage()
end

function handleHeatedCoolant()
    if (not hasHeatedCoolantChanged())
    then
        return
    end
    heatedCoolant = reactor.getHeatedCoolantFilledPercentage()
    displayHeatedCoolant()
end

function hasWastChanged()
    return waste ~= reactor.getWasteFilledPercentage()
end

function handleWaste()
    if (not hasWastChanged())
    then
        return
    end
    waste = reactor.getWasteFilledPercentage()
    displayWaste()
end

function hasHeatingRateChanged()
    return heatingRate ~= reactor.getHeatingRate()
end

function handleHeatingRate()
    if (not hasHeatingRateChanged())
    then
        return
    end
    heatingRate = reactor.getHeatingRate()
    displayHeatingRate()
end

function hasDangerStateChanged()
    return lastDangerState ~= dangerLevel
end

function handleDangerState()
    hasDangerStateChanged()
    if (not hasDangerStateChanged())
    then
        return
    end
    lastDangerState = dangerLevel
    displayDangerLevel()
end

function hasReactorStateChanged()
    return isReactorOn ~= reactor.getStatus()
end

function handleReactorState()
    if (not hasReactorStateChanged())
    then
        return
    end
    isReactorOn = reactor.getStatus()
    displayReactorState()
end

function handleRateLimit()
    displayBurnRateLimit()
end

function burnRateChanged()
    return burnRate ~= reactor.getBurnRate()
end

function handleBurnRate()
    if (not burnRateChanged())
    then
        return
    end
    burnRate = reactor.getBurnRate()
    displayBurnRate()
end

function setDangerState(newState)
    dangerLevel = newState
end

function getDangerLevel()
    return dangerLevel
end

function setRedstoneOutput(value)
    redstone.setOutput(redstoneOutputDirection, value)
end

function turnReactorOn()
    setRedstoneOutput(true)
end

function turnReactorOff()
    setRedstoneOutput(false)
end

function decreaseBurnRateLimit()
    burnRateLimit = burnRateLimit - 0.1
end

function increaseBurnRate()
    if (reactor.getBurnRate() + 0.1 > burnRateLimit)
    then
        reactor.setBurnRate(burnRateLimit)
        return
    end
    reactor.setBurnRate(reactor.getBurnRate() + 0.1)
end

function decreaseBurnRate()
    if (reactor.getBurnRate() < 0.2)
    then
        return
    end
    reactor.setBurnRate(reactor.getBurnRate() - 0.1)
end

function getCoolantDangerLevel()
    if (reactor.getCoolantFilledPercentage() < 0.1)
    then
        return dangerLevels.CRITICAL
    end
    if (reactor.getCoolantFilledPercentage() < 0.5)
    then
        return dangerLevels.RISKY
    end
    if (reactor.getCoolantFilledPercentage() < 0.8)
    then 
        return dangerLevels.BAD
    end
    return dangerLevels.GOOD
end

function getHeatedCoolantDangerLevel()
    if (reactor.getHeatedCoolantFilledPercentage() >= 0.9)
    then
        return dangerLevels.CRITICAL
    end
    if (reactor.getHeatedCoolantFilledPercentage() >= 0.8)
    then
        return dangerLevels.RISKY
    end
    return dangerLevels.GOOD
end

function getWasteDangerLevel()
    if (reactor.getWasteFilledPercentage() >= 0.9)
    then
        return dangerLevels.CRITICAL
    end
    if (reactor.getWasteFilledPercentage() >= 0.8)
    then
        return dangerLevels.RISKY
    end
    return dangerLevels.GOOD
end

function getDamageDangerLevel()
    if (reactor.getDamagePercent() > 50)
    then
        return dangerLevels.CRITICAL
    end
    if (reactor.getDamagePercent() > 0)
    then
        return dangerLevels.RISKY
    end
    return dangerLevels.GOOD
end

function handleDangerLevel()
    dangerLevel = math.max(
        getCoolantDangerLevel(),
        getHeatedCoolantDangerLevel(),
        getWasteDangerLevel(),
        getDamageDangerLevel()
    )
end

function handleReactor()
    handleDangerLevel()

    if (isReactorOn)
    then
        if (getDangerLevel() == dangerLevels.GOOD)
        then
            increaseBurnRate()
        end
        if (getDangerLevel() >= dangerLevels.BAD)
        then
            if (hasDangerStateChanged())
            then
                decreaseBurnRateLimit()
            end
            decreaseBurnRate()
        end
        if (getDangerLevel() >= dangerLevels.RISKY)
        then
            turnReactorOff()
        end
    else
        if (getDangerLevel() == dangerLevels.GOOD)
        then
            turnReactorOn()
        end
    end

    handleChanges()
end

function displayEnvLoss()
    monitor.setCursorPos(1,0)
    monitor.clearLine()
    monitor.write("Environment Loss " .. reactor.getEnvironmentalLoss())
end

function displayReactorState()
    monitor.setCursorPos(1,1)
    monitor.clearLine()
    monitor.write("Reactor          ")
    
    if (reactor.getStatus())
    then
        monitor.blit("Online", "dddddd", "ffffff")
    else
        monitor.blit("Offline", "eeeeeee", "fffffff")
    end
end

function displayDangerLevel()
    monitor.setCursorPos(1,2)
    monitor.clearLine()
    monitor.write("DangerLevel      ")

    if (dangerLevel == dangerLevels.GOOD)
    then
        monitor.blit("Good", "dddd", "ffff")
    elseif (dangerLevel == dangerLevels.BAD)
    then
        monitor.blit("Bad", "444", "fff")
    elseif (dangerLevel == dangerLevels.RISKY)
    then
        monitor.blit("Risky", "11111", "fffff")
    elseif (dangerLevel == dangerLevels.CRITICAL)
    then
        monitor.blit("Critical", "eeeeeeee", "ffffffff")
    end
end

function displayBurnRateLimit()
    monitor.setCursorPos(1,3)
    monitor.clearLine()
    monitor.write("Burn Rate Limit  " .. burnRateLimit .. " " .. "mB/t")
end

function displayBurnRate()
    monitor.setCursorPos(1,4)
    monitor.clearLine()
    monitor.write("Burn Rate        " .. reactor.getBurnRate() .. " " .. "mB/t")
end

function displayHeatingRate()
    monitor.setCursorPos(1,5)
    monitor.clearLine()
    monitor.write("Heating Rate     " .. reactor.getHeatingRate() .. " " .. "mB/t")
end

function getPercentageDangerColor(percentageDangerLevel, length)
    if (percentageDangerLevel == dangerLevels.GOOD)
    then
        return string.rep("d", length)
    elseif (percentageDangerLevel == dangerLevels.BAD)
    then
        return string.rep("4", length)
    elseif (percentageDangerLevel == dangerLevels.RISKY)
    then
        return string.rep("1", length)
    elseif (percentageDangerLevel == dangerLevels.CRITICAL)
    then
        return string.rep("e", length)
    end
    return ""
end

function displayCoolant()
    percent = math.floor(math.abs(reactor.getCoolantFilledPercentage()*100)) .. "%"
    percentColor = getPercentageDangerColor(getCoolantDangerLevel(), string.len(percent))
    percentBackground = string.rep("f", string.len(percent))
    monitor.setCursorPos(1,6)
    monitor.clearLine()
    monitor.write("Coolant          ")
    monitor.blit(percent, percentColor, percentBackground)
end

function displayFuel()
    monitor.setCursorPos(1,7)
    monitor.clearLine()
    monitor.write("Fuel             " .. math.floor(math.abs(reactor.getFuelFilledPercentage()*100)) .. "%")
end

function displayHeatedCoolant()
    percent = math.floor(math.abs(reactor.getHeatedCoolantFilledPercentage()*100)) .. "%"
    percentColor = getPercentageDangerColor(getHeatedCoolantDangerLevel(), string.len(percent))
    percentBackground = string.rep("f", string.len(percent))
    monitor.setCursorPos(1,8)
    monitor.clearLine()
    monitor.write("Heated Coolant   ")
    monitor.blit(percent, percentColor, percentBackground)
end

function displayWaste()
    percent = math.floor(math.abs(reactor.getWasteFilledPercentage()*100)) .. "%"
    percentColor = getPercentageDangerColor(getWasteDangerLevel(), string.len(percent))
    percentBackground = string.rep("f", string.len(percent))
    monitor.setCursorPos(1,9)
    monitor.clearLine()
    monitor.write("Waste            ")
    monitor.blit(percent, percentColor, percentBackground)
end

function displayDamage()
    percent = reactor.getDamagePercent() .. "%"
    percentColor = getPercentageDangerColor(getDamageDangerLevel(), string.len(percent))
    percentBackground = string.rep("f", string.len(percent))
    monitor.setCursorPos(1,10)
    monitor.clearLine()
    monitor.write("Damage           ")
    monitor.blit(percent, percentColor, percentBackground)
end

function start()
    turnReactorOn()
    turnReactorOff()
    reactor.setBurnRate(burnRateLimit)
    monitor.setTextScale(0.5)

    handleChanges()
end

start()
while true
do
    handleReactor()
end
