local Tunnel = module("frp_lib", "lib/Tunnel")
local Proxy = module("frp_lib", "lib/Proxy")

API = Proxy.getInterface("API")


-- send to jail and register in database
RegisterServerEvent('JAIL:sendToJail')
AddEventHandler('JAIL:sendToJail', function(userId, jailTime)
	local src = source

	local targetUser = API.GetUserFromUserId(userId)
	local targetSourceId = targetUser:GetSource()
	local targetCharId = targetUser:GetCharacterId()

	if targetCharId then
		jailPlayerFromCharId( targetSourceId, targetCharId, jailTime )
	end
end)

function jailPlayerFromCharId(playerId, charId, jailTime)
	local playerHasInfraction = CheckPlayerJail(charId)[1]

	if not playerHasInfraction then
		local jailTime = jailTime * 60
		if SetPlayerToJail(charId, jailTime) then
			if playerId then
				TriggerClientEvent('JAIL:jail', playerId, tonumber(jailTime))

				exports.ox_inventory:AddItem(playerId, 'vitamin', 2)
				exports.ox_inventory:AddItem(playerId, 'carrot_cake', 2)
			end
		end
	else
		local newJailTime = playerHasInfraction.jail_time + jailTime
		UpdateJailPlayer(charId, newJailTime)
		TriggerClientEvent('JAIL:jail', playerId, newJailTime)
	end
end

function jailFromPlayerId(playerId, jailTime)
	if playerId then
		local User     = API.GetUserFromSource(playerId)
		local charId   = User:GetCharacterId()

		jailPlayerFromCharId( playerId, charId, jailTime )
	end
end
exports('jailFromPlayerId', jailFromPlayerId)

RegisterServerEvent('JAIL:checkJail')
AddEventHandler('JAIL:checkJail', function(src)
	local src = src or source

	local targetUser = API.GetUserFromSource(src)
	local targetCharId = targetUser:GetCharacterId()

	local playerHasInfraction = CheckPlayerJail(targetCharId)[1]

	if playerHasInfraction then
		TriggerClientEvent('JAIL:jail', src, playerHasInfraction.jail_time)
	end
end)

RegisterServerEvent('JAIL:unjailRequest')
AddEventHandler('JAIL:unjailRequest', function(targetCharId)
	if not targetCharId then
		local targetUser = API.GetUserFromSource(source)
		targetCharId = targetUser:GetCharacterId()
	end


	if targetCharId ~= nil then
		removePlayerFromPrision(targetCharId)
	end
end)


RegisterServerEvent('JAIL:updateRemaining')
AddEventHandler('JAIL:updateRemaining', function(jailTime)
	local _source = source

	jailTime      = tonumber(jailTime)

	local User    = API.GetUserFromSource(_source)
	local charId  = User:GetCharacterId()

	if jailTime > 0 then
		UpdateJailPlayer(charId, jailTime)
	else
		removePlayerFromPrision(charId)
	end
end)

RegisterServerEvent("JAIL:JobReawardMoney", function()
	local _source = source

	local User    = API.GetUserFromSource(_source)
	local charId  = User:GetCharacterId()

	local reward  = (math.random(3, 10) / 100)

	exports.ox_inventory:AddItem(_source, 'money', reward + 0.01)
	cAPI.Notify(_source, "success", i18n.translate("info.rewardMoney", reward), 3500)
end)

function RemoveItems(playerId)
	for i = 1, #Config.itemsToRemove do
		local itemHash = Config.itemsToRemove[i]

		local Item     = exports.ox_inventory:GetItem(playerId, itemHash)

		if Item then
			exports.ox_inventory:RemoveItem(playerId, itemHash, Item.count)
		end
	end
end

function removePlayerFromPrision(charId)
	if charId then
		local User     = API.GetUserFromCharId(charId)
		local playerId = User:GetSource()

		if RemoveJailPlayer(charId) then
			Wait(1000)
			TriggerClientEvent('JAIL:unjail', playerId)
		end
	end
end

function unjailFromPlayerId(playerId)
	if playerId then
		local User     = API.GetUserFromSource(playerId)
		local charId   = User:GetCharacterId()
		local playerId = User:GetSource()

		if RemoveJailPlayer(charId) then
			Wait(1000)
			TriggerClientEvent('JAIL:unjail', playerId)
		end
	end
end

exports('unjailFromPlayerId', unjailFromPlayerId)

AddEventHandler('FRP:onCharacterLoaded', function(User, CharacterId)
	local source = User:GetSource()

	Wait(5000)

	TriggerEvent("JAIL:checkJail", source)
end)

--[[ Inicializar o 'Inventory Player' dos players que já estavam online enquanto o script foi reiniciado ]]
--[[ Só server para debug, porque não verifica se o user tem um character ativo. ]]
CreateThread(function()
	Wait(2000)

	for _, playerId in ipairs(GetPlayers()) do
		if playerId then
			TriggerEvent("JAIL:checkJail", tonumber(playerId))
		end
	end
end)
