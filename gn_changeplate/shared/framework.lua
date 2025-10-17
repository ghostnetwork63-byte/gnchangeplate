local Framework = {}

local cfg = rawget(_G, 'Config') or {}
local frameworkName = (cfg.Framework or 'ESX')
Framework.name = frameworkName

-- Resolución de objetos framework en server y client
if IsDuplicityVersion() then
	if frameworkName == 'ESX' then
		local status, obj = pcall(function()
			return exports['es_extended']:getSharedObject()
		end)
		ESX = status and obj or ESX
	elseif frameworkName == 'QBCore' then
		local status, obj = pcall(function()
			return exports['qb-core']:GetCoreObject()
		end)
		QBCore = status and obj or QBCore
	end
else
	if frameworkName == 'ESX' then
		CreateThread(function()
			while ESX == nil do
				TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
				Wait(100)
			end
		end)
	elseif frameworkName == 'QBCore' then
		CreateThread(function()
			while QBCore == nil do
				TriggerEvent('QBCore:GetObject', function(obj) QBCore = obj end)
				if QBCore == nil and exports and exports['qb-core'] then
					QBCore = exports['qb-core']:GetCoreObject()
				end
				Wait(100)
			end
		end)
	end
end

function Framework.getName()
	return Framework.name
end

-- Server-side helpers
if IsDuplicityVersion() then
	function Framework.registerUsableItem(itemName, cb)
		if frameworkName == 'ESX' then
			if ESX and ESX.RegisterUsableItem then
				ESX.RegisterUsableItem(itemName, function(source)
					cb(source)
				end)
			end
		elseif frameworkName == 'QBCore' then
			if QBCore and QBCore.Functions and QBCore.Functions.CreateUseableItem then
				QBCore.Functions.CreateUseableItem(itemName, function(source, item)
					cb(source)
				end)
			end
		end
	end

	function Framework.removeItem(src, itemName, count)
		count = count or 1
		if frameworkName == 'ESX' then
			local xPlayer = ESX.GetPlayerFromId(src)
			if xPlayer then
				xPlayer.removeInventoryItem(itemName, count)
				return true
			end
		elseif frameworkName == 'QBCore' then
			local xPlayer = QBCore.Functions.GetPlayer(src)
			if xPlayer then
				xPlayer.Functions.RemoveItem(itemName, count)
				TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[itemName], 'remove')
				return true
			end
		end
		return false
	end

	function Framework.hasItem(src, itemName, count)
		count = count or 1
		if frameworkName == 'ESX' then
			local xPlayer = ESX.GetPlayerFromId(src)
			if not xPlayer then return false end
			local item = xPlayer.getInventoryItem(itemName)
			return item and item.count and item.count >= count
		elseif frameworkName == 'QBCore' then
			local xPlayer = QBCore.Functions.GetPlayer(src)
			if not xPlayer then return false end
			local item = xPlayer.Functions.GetItemByName(itemName)
			return item and item.amount and item.amount >= count
		end
		return false
	end

	function Framework.notify(src, msg, typ)
		TriggerClientEvent('gn_changeplate:notify', src, msg, typ)
	end
else
	-- client notify
	RegisterNetEvent('gn_changeplate:notify', function(msg, typ)
		local mode = cfg.Notify or 'auto'
		if mode == 'auto' then
			mode = (frameworkName == 'ESX') and 'esx' or 'qb'
		end
		if mode == 'esx' and ESX and ESX.ShowNotification then
			ESX.ShowNotification(msg)
		elseif mode == 'qb' and QBCore and QBCore.Functions and QBCore.Functions.Notify then
			QBCore.Functions.Notify(msg, typ or 'primary')
		else
			-- fallback chat
			BeginTextCommandThefeedPost('STRING')
			AddTextComponentSubstringPlayerName(msg)
			EndTextCommandThefeedPostTicker(false, false)
		end
	end)
end

-- Exponer global
_G.GN_Framework = Framework
