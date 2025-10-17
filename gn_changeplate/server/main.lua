local ITEM = Config.ItemName

CreateThread(function()
	while _G.GN_Framework == nil do Wait(50) end
	local FW = _G.GN_Framework
	FW.registerUsableItem(ITEM, function(source)
		if not FW.hasItem(source, ITEM, 1) then
			FW.notify(source, 'No tienes el objeto necesario', 'error')
			return
		end
		TriggerClientEvent('gn_changeplate:useItem', source)
	end)
end)

RegisterNetEvent('gn_changeplate:consumeItem', function()
	local src = source
	if Config.ConsumeItem then
		local FW = _G.GN_Framework
		if FW then
			FW.removeItem(src, ITEM, 1)
		end
	end
end)
