local common = x_require("common")

local YaPlayer = common.newClass(function (data)
    return { gTName = "Player", gTId = data.player:GetId() }
end)

YaPlayer.enableInput = function (self, b)
    local avatar = self.avatar
    if avatar == nil then
        return
    end
    avatar:enableInput(b)
end

YaPlayer.isInputEnabled = function (self)
    local avatar = self.avatar
    if avatar == nil then
        return true
    end
    return avatar:isInputEnabled()
end

YaPlayer.getServerProperty = function (self, key)
    return self.player:GetPlayerProperty(key)
end

YaPlayer.setServerProperty = function (self, key, value)
    self.player:SetPlayerProperty(key, value)
end

YaPlayer.removeServerProperty = function (self, key)
    self.player:RemovePlayerProperty(key)
end

YaPlayer.getServerPropertyKeys = function (self)
    return self.player:GetPlayerPropertyKeys()
end

YaPlayer.getEntityId = function (self)
    if self.entityId == nil then
        if self:isBotPlayer() then
            self.entityId = self.player:GetEntityId()
        else
            self.entityId = self.player:GetEntity().EntityId
        end
    end
    return self.entityId
end

YaPlayer.getActNum = function (self)
    if self.actNum == nil then
        self.actNum = self.player:GetId()
    end
    return self.actNum
end

YaPlayer.getName = function (self)
    if self.name == nil then
        self.name = self.player:GetName()
    end
    return self.name
end

YaPlayer.isAIPlayer = function (self)
    return self.isAI
end

YaPlayer.isBotPlayer = function (self)
    return self.isBot
end

YaPlayer.getAvatar = function (self)
    return self.avatar
end

local exports = YaPlayer