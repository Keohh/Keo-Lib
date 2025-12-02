Citizen.CreateThread(function()
    while true do
		Citizen.Wait(1)
		if IsPedOnFoot(GetPlayerPed(-1)) then 
			DisplayRadar(false)
		elseif IsPedInAnyVehicle(GetPlayerPed(-1), true) then
			DisplayRadar(true)
		end
    end
end)