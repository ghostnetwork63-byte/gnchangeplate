Config = {}

-- Framework puede ser 'ESX' o 'QBCore'
Config.Framework = 'ESX'

-- Nombre del item que activará el cambio de matrícula
Config.ItemName = 'changeplate'

-- Si true, consume 1 item al cambiar la matrícula correctamente
Config.ConsumeItem = true

-- Máximo de caracteres permitidos
Config.MaxLength = 7

-- Distancia máxima al vehículo para permitir usar
Config.MaxDistance = 2.5

-- Umbral de ángulo (grados) para considerar que estás detrás del coche
Config.BehindAngleDegrees = 60

-- Tipo de menú para introducir la matrícula: 'ox_lib', 'qb-input', 'native'
Config.Menu = 'ox_lib'

-- Animaciones configurables
Config.Animations = {
	Crouch = { dict = 'amb@medic@standing@kneel@base', anim = 'base', time = 1500 },
	Touch = { dict = 'mini@repair', anim = 'fixing_a_ped', time = 2200 }
}

-- Notificaciones: 'auto' (elige según framework), 'esx', 'qb', 'chat'
Config.Notify = 'auto'
