local Tunnel = module("vrp", "lib/Tunnel")
local Proxy = module("vrp", "lib/Proxy")

vRP = Proxy.getInterface("vRP")
vRPclient = Tunnel.getInterface("vRP", "vrp_addons_gcphone")

local PhoneNumbers = {}

RegisterServerEvent('vrp_addons_gcphone:startCall')
AddEventHandler('vrp_addons_gcphone:startCall', function(number, message, coords, permission)
    local user_id = vRP.getUserId({source})
	local players = vRP.getUsersByPermission({permission})
	for k, player_id in pairs(players) do
		local player = vRP.getUserSource({player_id})
		getPhoneNumber(source, function(n)
		
			local mess = 'Da #' ..n .. ' : ' ..message
			if coords ~= nil then
				mess = mess.. ', Coordinate: ' ..coords.x.. ', ' ..coords.y 
			end
			
			TriggerEvent('gcPhone:_internalAddMessage', number, n, mess, 0, function(smsMess)
				TriggerClientEvent("gcPhone:receiveMessage", player, smsMess)
			end)
		end)
	end

    --vRP.sendServiceAlert({source, number, coords.x, coords.y, coords.z, message})
end)

function getPhoneNumber(source, cb) 
	local user_id = vRP.getUserId({source})
	if user_id == nil then
		cb(nil)
	end
	MySQL.Async.fetchAll('SELECT * FROM vrp_user_identities WHERE user_id = @user_id',{
		['@user_id'] = user_id
	}, function(result)
		cb(result[1].phone)
	end)
end


--[[AddEventHandler('vrp_addons_gcphone:startCall', function(number, message, coords)
	local source = source
	if PhoneNumbers[number] ~= nil then
		getPhoneNumber(source, function(phone) 
			notifyAlertSMS(number, {
				message = message,
				coords = coords,
				numero = phone,
			}, PhoneNumbers[number].sources)
		end)
	end
end)

AddEventHandler('esx_phone:registerNumber', function(number, type, sharePos, hasDispatch, hideNumber, hidePosIfAnon)
	local hideNumber = hideNumber or false
	local hidePosIfAnon = hidePosIfAnon or false

	PhoneNumbers[number] = {
		type = type,
		sources = {},
		alerts = {}
	}
end)


AddEventHandler('vRP:playerJoinGroup', function(user_id, group, gtype)
	local source = vRP.getUserSource({user_id})
	if PhoneNumbers[group] ~= nil then
		TriggerEvent('vrp_addons_gcphone:addSource', group, source)
	end
end)

AddEventHandler("vRP:playerLeaveGroup", function(user_id, group, gtype)
	local source = vRP.getUserSource({user_id})
	if PhoneNumbers[group] ~= nil then
		TriggerEvent('vrp_addons_gcphone:removeSource', group, source)
	end
end)

AddEventHandler('esx:setJob', function(source, job, lastJob)
	if PhoneNumbers[lastJob.name] ~= nil then
		TriggerEvent('esx_addons_gcphone:removeSource', lastJob.name, source)
	end

	if PhoneNumbers[job.name] ~= nil then
		TriggerEvent('esx_addons_gcphone:addSource', job.name, source)
	end
end)

AddEventHandler('vrp_addons_gcphone:addSource', function(number, source)
	PhoneNumbers[number].sources[tostring(source)] = true
	print(PhoneNumbers[number].sources[tostring(source)])
end)

AddEventHandler('vrp_addons_gcphone:removeSource', function(number, source)
	PhoneNumbers[number].sources[tostring(source)] = nil
end)

RegisterServerEvent('gcPhone:sendMessage')
AddEventHandler('gcPhone:sendMessage', function(number, message)
    if PhoneNumbers[number] ~= nil then
		getPhoneNumber(source, function(phone) 
			notifyAlertSMS(number, {
				message = message,
				numero = phone,
			}, PhoneNumbers[number].sources)
		end)
    end
end)


AddEventHandler("vRP:playerSpawn",function(user_id, source, first_spawn)
	local group = vRP.getUserGroupByType({user_id, "job"})
	print(group)
	local array = {"Capitano", "Tenente", "Sergente", "Agente", "Cadetto"}
	if array == group then
		if PhoneNumbers[number] ~= nil then
			TriggerEvent('vrp_addons_gcphone:addSource', "Polizia", source)
		end
	end
end)

AddEventHandler('esx:playerLoaded', function(source)

	local xPlayer = ESX.GetPlayerFromId(source)

	MySQL.Async.fetchAll('SELECT * FROM users WHERE identifier = @identifier',{
		['@identifier'] = xPlayer.identifier
	}, function(result)

		local phoneNumber = result[1].phone_number
		xPlayer.set('phoneNumber', phoneNumber)

		if PhoneNumbers[xPlayer.job.name] ~= nil then
			TriggerEvent('vrp_addons_gcphone:addSource', xPlayer.job.name, source)
		end
	end)
end)

AddEventHandler('playerDropped', function(source, reason)
	local user_id = vRP.getUserId({source})
	local group = vRP.getUserGroupByType({user_id, "job"})
	
	local array = {"Capitano", "Tenente", "Sergente", "Agente", "Cadetto"}
	if array == group then
		getPhoneNumber(source, function(number)
			if PhoneNumbers[number] ~= nil then
				TriggerEvent('vrp_addons_gcphone:addSource', "Polizia", source)
			end
		end)
	end
end)


AddEventHandler('esx:playerDropped', function(source)
	local xPlayer = ESX.GetPlayerFromId(source)
	if PhoneNumbers[xPlayer.job.name] ~= nil then
		TriggerEvent('vrp_addons_gcphone:removeSource', xPlayer.job.name, source)
	end
end)



RegisterServerEvent('vrp_addons_gcphone:send')
AddEventHandler('vrp_addons_gcphone:send', function(number, message, _, coords)
	local source = source
	if PhoneNumbers[number] ~= nil then
		getPhoneNumber(source, function(phone) 
			notifyAlertSMS(number, {
				message = message,
				coords = coords,
				numero = phone,
			}, PhoneNumbers[number].sources)
		end)
	end
end)]]