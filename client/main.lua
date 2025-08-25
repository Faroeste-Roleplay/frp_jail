local IsJailed = false
local unjail = false

JailTime = 0
local prisionCoords = vec3(3336.743, -696.573, 43.987)

local prisionCenterCoords = vec3(3282.816, -642.5102, 40.342)

RegisterNetEvent('JAIL:jail')
AddEventHandler('JAIL:jail', function(jailTime)
	
	if IsJailed then -- don't allow multiple jails
		if jailTime - JailTime <= 100 then
			return
		else
			JailTime = jailTime
			return
		end
	end

	JailTime = jailTime

	local playerPed = PlayerPedId()
	
	TriggerEvent("texas:notify:native", i18n.translate("info.jailed", string.format("%.0f", tonumber(JailTime / 60))), 5000)

	IsJailed = true

	TriggerEvent("JAIL:client:startTimers")

	if DoesEntityExist(playerPed) then
		Citizen.CreateThread(function()
			
			local pP = PlayerPedId()

			RemovePlayerComponents()
		
			Wait(100)

			DoScreenFadeOut(500)
			
			Wait(500)
			
			SetPlayerPrisonerCloths()
		
			StartPlayerTeleport(PlayerId(), prisionCoords, 0.0 + 0.0001, true, true, true)
		
			-- SetEntityCoords(playerPed, 2929.51, -1252.1, 41.30)
		
			while IsPlayerTeleportActive() do
				Citizen.Wait(500)
			end
		
			DoScreenFadeIn(500)

			unjail = false

			while JailTime > 0 and not unjail do
				playerPed = PlayerPedId()

				local playerCoords = GetEntityCoords(playerPed)

				RemoveAllPedWeapons(PlayerPedId(), false, true)

				if IsPedInAnyVehicle(playerPed, false) then
					ClearPedTasksImmediately(playerPed)
				end

				TriggerServerEvent('JAIL:updateRemaining', JailTime)

				-- Is the player trying to escape?

				if JailTime <= 40 and JailTime > 10 then
					TriggerEvent("texas:notify:native", i18n.translate("info.last_one_minute"), 4000)					
				end

				if #(playerCoords - prisionCenterCoords) > 300 then
					SetEntityCoords(playerPed, prisionCoords)

					TriggerEvent("texas:notify:native", i18n.translate("info.bad_react", 10), 7000)
					JailTime = JailTime + (10 * 60)
				end				
				
				Citizen.Wait(20000)
			end

			TriggerServerEvent('JAIL:unjailRequest')
			IsJailed = false
		end)
	end
end)

local componentsToRemove = 
{
	0x9B2C8B89,
	0x5FC29285,
	0xEABE0032,
	0x662AC34,
	0x7505EF42,
	0x777EC6EF,
	0x1D4C528A,
	0x485EE834,
	0x2026C46D,
	0x9925C067,
}

function RemovePlayerComponents()
	local playerPed = PlayerPedId()

	for i = 1, #componentsToRemove do
		Citizen.InvokeNative(0xD710A5007C2AC539, playerPed, componentsToRemove[i], 0) -- Set target category, here the hash is for hats
		Citizen.InvokeNative(0xCC8CA3E88256E58F, playerPed, 0, 1, 1, 1, 0) -- Actually remove the component
	end		
end

function SetPlayerPrisonerCloths()
	local playerPed = PlayerPedId()
	
	if IsPedMale(playerPed) then
		Citizen.InvokeNative(0xD3A7B003ED343FD9, playerPed,0x5BA76CCF,true,true,true) -- CAMISA
		Citizen.InvokeNative(0xD3A7B003ED343FD9, playerPed,0x216612F0,true,true,true) -- CALÇA
		Citizen.InvokeNative(0xD3A7B003ED343FD9, playerPed,0xF082E23A,true,true,true) -- SAPATO
	else
		Citizen.InvokeNative(0xD3A7B003ED343FD9, playerPed,0x6AB27695,true,true,true) -- CAMISA
		Citizen.InvokeNative(0xD3A7B003ED343FD9, playerPed,0x75BC0CF5,true,true,true) -- PANTS
		Citizen.InvokeNative(0xD3A7B003ED343FD9, playerPed,0x56906647,true,true,true) -- SAPATO
	end
end

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)

		if JailTime > 1 and IsJailed then

			DrawTxt(i18n.translate('info.time_remain', tonumber(string.format("%.0f", JailTime))), 0.70, 0.95, 0.4, 0.4, true, 255, 255, 255, 150, false)

		end
	end
end)

local updateRemaining


AddEventHandler("JAIL:client:startTimers",function()
	Citizen.CreateThread(function()
		while IsJailed and JailTime >= 0 do
			Citizen.Wait(1000)
			if JailTime >= 0 then
				JailTime = JailTime - 1
			end
		end
	end)
end)

local playerWasPunished = false
local doctorsAlerted = false


Citizen.CreateThread(function()
	while true do
		Citizen.Wait(2500)

		if JailTime > 1 and IsJailed then
			local playerPed = PlayerPedId()
			local playerCoords = GetEntityCoords(playerPed)

			local closestPed, closestDist = GetClosestPed(playerCoords)

			if closestPed and closestDist <= 5 then
				local isPlayerInCombat = Citizen.InvokeNative(0x4859F1FC66A6278E, playerPed, closestPed) -- IS_PED_IN_COMBAT

				if isPlayerInCombat then
					if not playerWasPunished then
						TriggerEvent("texas:notify:native", i18n.translate("info.bad_react", 5), 7000)
						JailTime = JailTime + (5 * 60)
						
						playerWasPunished = true

						Wait(10000)

						playerWasPunished = false
					end
				end
			end


			if IsEntityDead(playerPed) then
				if not doctorsAlerted then
					TriggerServerEvent("ml_doctorjob:alert_me", playerCoords)
					doctorsAlerted = true
				end
			else
				doctorsAlerted = false
			end

		end

	end
end)


RegisterNetEvent('JAIL:unjail')
AddEventHandler('JAIL:unjail', function(source)	
	unjail = true
	JailTime = 0
	IsJailed = false
	working = false

	local playerPed = PlayerPedId()
	RemovePlayerComponents()

	ClearGpsMultiRoute()

	for k, v in pairs(Rocks) do
		DeleteObject(v)
	end
	
	DoScreenFadeOut(500)

	Wait(500)

	StartPlayerTeleport(PlayerId(), 2929.51, -1252.1, 41.30, 0.0 + 0.0001, true, true, true)

	-- SetEntityCoords(playerPed, 2929.51, -1252.1, 41.30)

    TriggerServerEvent("redemrp_clothing:loadClothes", 1)

	while IsPlayerTeleportActive() do
		Citizen.Wait(500)
	end

	DoScreenFadeIn(500)

	TriggerEvent("texas:notify:native", i18n.translate("info.jail_finished"), 5000)
end)

