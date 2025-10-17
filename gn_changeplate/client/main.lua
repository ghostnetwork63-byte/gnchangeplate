-- Cliente gn_changeplate

local function loadAnimDict(dict)
	RequestAnimDict(dict)
	while not HasAnimDictLoaded(dict) do
		Wait(10)
	end
end

local function getVehicleRearPosition(vehicle)
	-- Usa el hueso del parachoques trasero si existe, si no un offset genérico
	local bone = GetEntityBoneIndexByName(vehicle, 'bumper_r')
	if bone ~= -1 then
		return GetWorldPositionOfEntityBone(vehicle, bone)
	end
	local boot = GetEntityBoneIndexByName(vehicle, 'boot')
	if boot ~= -1 then
		return GetWorldPositionOfEntityBone(vehicle, boot)
	end
	-- Offset 2.2m hacia atrás desde el centro como fallback
	return GetOffsetFromEntityInWorldCoords(vehicle, 0.0, -2.2, 0.0)
end

local function isPlayerBehindVehicle(playerPed, vehicle)
	if vehicle == 0 or vehicle == nil then return false end
	local pCoords = GetEntityCoords(playerPed)
	local rearPos = getVehicleRearPosition(vehicle)
	local vForward = GetEntityForwardVector(vehicle)
	-- Vector desde la parte trasera hacia el jugador
	local rel = pCoords - rearPos
	local relNorm = rel / math.max(#(rel + vector3(0.0, 0.0, 0.0)), 0.001)
	local rearDir = -vForward
	local dot = relNorm.x * rearDir.x + relNorm.y * rearDir.y + relNorm.z * rearDir.z
	local threshold = math.cos((Config.BehindAngleDegrees or 60) * (math.pi/180.0))
	if dot < threshold then return false end
	local dist = #(pCoords - rearPos)
	return dist <= (Config.MaxDistance or 2.5)
end

local function getClosestVehicle(maxDist)
	local playerPed = PlayerPedId()
	local coords = GetEntityCoords(playerPed)
	local searchDist = maxDist or 6.0
	local closestVeh, closestRearDist = 0, searchDist
	local vehicles = GetGamePool('CVehicle')
	for _, veh in ipairs(vehicles) do
		if DoesEntityExist(veh) then
			local rearPos = getVehicleRearPosition(veh)
			local d = #(rearPos - coords)
			if d < closestRearDist then
				closestRearDist = d
				closestVeh = veh
			end
		end
	end
	return closestVeh, closestRearDist
end

local function sanitizePlate(input)
	if not input then return nil end
	-- quitar espacios y limitar
	local s = string.gsub(input, '%s+', '')
	-- solo letras y numeros
	s = string.upper(s)
	if not s:match('^%w+$') then return nil end
	if #s == 0 or #s > (Config.MaxLength or 7) then return nil end
	return s
end

local function qbInputAvailable()
	return exports and exports['qb-input'] and type(exports['qb-input'].ShowInput) == 'function'
end

local function inputPlate()
	local method = (Config.Menu or 'ox_lib')
	if method == 'ox_lib' and lib and type(lib.inputDialog) == 'function' then
		local res = lib.inputDialog('Nueva matrícula', {
			{ type = 'input', label = 'Texto (máx '..(Config.MaxLength or 7)..')', placeholder = 'AAA1234', required = true, max = (Config.MaxLength or 7) }
		})
		if res and res[1] then
			return sanitizePlate(res[1])
		end
	elseif (method == 'qb' or method == 'qb-input') and qbInputAvailable() then
		local res = exports['qb-input']:ShowInput({
			title = 'Nueva matrícula',
			submitText = 'Aceptar',
			inputs = {
				{ type = 'text', isRequired = true, name = 'plate', text = 'Texto (máx '..(Config.MaxLength or 7)..')', length = (Config.MaxLength or 7) },
			}
		})
		if res and res.plate then
			return sanitizePlate(res.plate)
		end
	end
	-- Fallback nativo
	AddTextEntry('GN_PLATE_INPUT', 'Introduce nueva matrícula (máx '..(Config.MaxLength or 7)..')')
	DisplayOnscreenKeyboard(1, 'GN_PLATE_INPUT', '', '', '', '', '', (Config.MaxLength or 7))
	while UpdateOnscreenKeyboard() == 0 do
		DisableAllControlActions(0)
		Wait(0)
	end
	if GetOnscreenKeyboardResult() then
		return sanitizePlate(GetOnscreenKeyboardResult())
	end
	return nil
end

-- Animación de agachado en bucle
local crouchPlaying = false
local function startCrouchLoop()
	local ped = PlayerPedId()
	local a = (Config.Animations and Config.Animations.Crouch) or { dict = 'amb@world_human_vehicle_mechanic@male@base', anim = 'base', time = 1200 }
	loadAnimDict(a.dict)
	TaskPlayAnim(ped, a.dict, a.anim, 8.0, -8.0, -1, 1, 0.0, false, false, false)
	crouchPlaying = true
end

local function stopCrouch()
	if not crouchPlaying then return end
	crouchPlaying = false
	ClearPedTasks(PlayerPedId())
end

local function playTouchPlate()
	local ped = PlayerPedId()
	local a = (Config.Animations and Config.Animations.Touch) or { dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@', anim = 'machinic_loop_mechandplayer', time = 1800 }
	loadAnimDict(a.dict)
	TaskPlayAnim(ped, a.dict, a.anim, 8.0, -8.0, a.time or 1800, 1, 0.0, false, false, false)
	Wait(a.time or 1800)
	ClearPedTasks(ped)
end

RegisterNetEvent('gn_changeplate:useItem', function()
	local ped = PlayerPedId()
	if IsPedInAnyVehicle(ped, false) then
		TriggerEvent('gn_changeplate:notify', 'Debes estar fuera del vehículo', 'error')
		return
	end
	local veh = 0
	veh = GetVehiclePedIsIn(ped, false)
	if veh ~= 0 then
		TriggerEvent('gn_changeplate:notify', 'Sal del vehículo para cambiar la matrícula', 'error')
		return
	end
	veh = 0
	veh = GetVehiclePedIsTryingToEnter(ped)
	if veh ~= 0 then veh = 0 end
	veh = select(1, getClosestVehicle((Config.MaxDistance or 2.5) + 2.0))
	if veh == 0 then
		TriggerEvent('gn_changeplate:notify', 'No hay vehículos cerca', 'error')
		return
	end
	if not isPlayerBehindVehicle(ped, veh) then
		TriggerEvent('gn_changeplate:notify', 'Debes colocarte detrás del vehículo', 'error')
		return
	end
	startCrouchLoop()
	local newPlate = inputPlate()
	stopCrouch()
	if not newPlate then
		TriggerEvent('gn_changeplate:notify', 'Entrada inválida o cancelada', 'error')
		return
	end
	playTouchPlate()
	SetVehicleNumberPlateText(veh, newPlate)
	TriggerEvent('gn_changeplate:notify', 'Matrícula cambiada a '..newPlate, 'success')
	TriggerServerEvent('gn_changeplate:consumeItem')
end)
