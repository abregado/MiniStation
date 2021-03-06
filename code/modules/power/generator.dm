// dummy generator object for testing

/*/obj/machinery/power/generator/verb/set_amount(var/g as num)
	set src in view(1)

	gen_amount = g

*/

/obj/machinery/power/generator
	name = "thermoelectric generator"
	desc = "It's a high efficiency thermoelectric generator."
	icon_state = "teg"
	anchored = 1
	density = 1
	use_power = 0

	var/obj/machinery/atmospherics/binary/circulator/circ1
	var/obj/machinery/atmospherics/binary/circulator/circ2

	var/lastgen = 0
	var/lastgenlev = -1


/obj/machinery/power/generator/initialize()

	circ1 = null
	circ2 = null

	circ1 = locate(/obj/machinery/atmospherics/binary/circulator) in get_step(src,WEST)
	circ2 = locate(/obj/machinery/atmospherics/binary/circulator) in get_step(src,EAST)
	connect_to_network()

	if(circ1)
		circ1.side = 1
		circ1.update_icon()
	if(circ2)
		circ2.side = 2
		circ2.update_icon()

	if(!circ1 || !circ2)
		stat |= BROKEN

	update_icon()


/obj/machinery/power/generator/update_icon()

	if(stat & (NOPOWER|BROKEN))
		overlays.Cut()
	else
		overlays.Cut()

		if(lastgenlev != 0)
			overlays += image('icons/obj/power.dmi', "teg-op[lastgenlev]")

#define GENRATE 800		// generator output coefficient from Q

/obj/machinery/power/generator/process()

	if(!circ1 || !circ2)
		return

	lastgen = 0

	if(powernet)
		//world << "circ1 and circ2 pass"

		var/datum/gas_mixture/cold_air = circ1.return_transfer_air()
		var/datum/gas_mixture/hot_air = circ2.return_transfer_air()

		//world << "hot_air = [hot_air]; cold_air = [cold_air];"

		if(cold_air && hot_air)

			//world << "hot_air = [hot_air] temperature = [hot_air.temperature]; cold_air = [cold_air] temperature = [hot_air.temperature];"

			//world << "coldair and hotair pass"
			var/cold_air_heat_capacity = cold_air.heat_capacity()
			var/hot_air_heat_capacity = hot_air.heat_capacity()

			var/delta_temperature = hot_air.temperature - cold_air.temperature

			//world << "delta_temperature = [delta_temperature]; cold_air_heat_capacity = [cold_air_heat_capacity]; hot_air_heat_capacity = [hot_air_heat_capacity]"

			if(delta_temperature > 0 && cold_air_heat_capacity > 0 && hot_air_heat_capacity > 0)
				var/efficiency = 0.65

				var/energy_transfer = delta_temperature*hot_air_heat_capacity*cold_air_heat_capacity/(hot_air_heat_capacity+cold_air_heat_capacity)

				var/heat = energy_transfer*(1-efficiency)
				lastgen = energy_transfer*efficiency

				//world << "lastgen = [lastgen]; heat = [heat]; delta_temperature = [delta_temperature]; hot_air_heat_capacity = [hot_air_heat_capacity]; cold_air_heat_capacity = [cold_air_heat_capacity];"

				hot_air.temperature = hot_air.temperature - energy_transfer/hot_air_heat_capacity
				cold_air.temperature = cold_air.temperature + heat/cold_air_heat_capacity

				//world << "POWER: [lastgen] W generated at [efficiency*100]% efficiency and sinks sizes [cold_air_heat_capacity], [hot_air_heat_capacity]"

				add_avail(lastgen)
		// update icon overlays only if displayed level has changed

		if(hot_air)
			circ2.air1.merge(hot_air)

		if(cold_air)
			circ1.air1.merge(cold_air)

	var/genlev = max(0, min( round(11*lastgen / 100000), 11))
	if(genlev != lastgenlev)
		lastgenlev = genlev
		update_icon()

	src.updateDialog()

/obj/machinery/power/generator/attack_hand(mob/user)
	if(..())
		user << browse(null, "window=teg")
		return
	interact(user)

/obj/machinery/power/generator/proc/get_menu(var/include_link = 1)
	var/t = ""
	if(!powernet)
		t += "<span class='bad'>Unable to connect to the power network!</span>"
	else if(circ1 && circ2)

		t += "<div class='statusDisplay'>"

		t += "Output: [round(lastgen)] W"

		t += "<BR>"

		t += "<B><font color='blue'>Cold loop</font></B><BR>"
		t += "Temperature Inlet: [round(circ1.air2.temperature, 0.1)] K / Outlet: [round(circ1.air1.temperature, 0.1)] K<BR>"
		t += "Pressure Inlet: [round(circ1.air2.return_pressure(), 0.1)] kPa /  Outlet: [round(circ1.air1.return_pressure(), 0.1)] kPa<BR>"

		t += "<B><font color='red'>Hot loop</font></B><BR>"
		t += "Temperature Inlet: [round(circ2.air2.temperature, 0.1)] K / Outlet: [round(circ2.air1.temperature, 0.1)] K<BR>"
		t += "Pressure Inlet: [round(circ2.air2.return_pressure(), 0.1)] kPa / Outlet: [round(circ2.air1.return_pressure(), 0.1)] kPa<BR>"

		t += "</div>"
	else
		t += "<span class='bad'>Unable to locate all parts!</span>"
	if(include_link)
		t += "<BR><A href='?src=\ref[src];close=1'>Close</A>"

	return t

/obj/machinery/power/generator/interact(mob/user)

	user.set_machine(src)

	//user << browse(t, "window=teg;size=460x300")
	//onclose(user, "teg")

	var/datum/browser/popup = new(user, "teg", "Thermo-Electric Generator", 460, 300)
	popup.set_content(get_menu())
	popup.set_title_image(user.browse_rsc_icon(src.icon, src.icon_state))
	popup.open()
	return 1


/obj/machinery/power/generator/Topic(href, href_list)
	..()
	if( href_list["close"] )
		usr << browse(null, "window=teg")
		usr.unset_machine()
		return 0
	return 1


/obj/machinery/power/generator/power_change()
	..()
	update_icon()

/obj/item/weapon/paper/generator
	name = "paper - 'generator instructions'"
	info = "<h2>How to setup the Thermo-Generator</h2><ol>	<li>To the top right is a room full of canisters; to the bottom there is a room full of pipes. Connect C02 canisters to the pipe room's top connector ports.</li>	<li>Connect 3 plasma and 2 oxygen canisters to the bottom ports of the pipe room.</li>	<li>Turn on all the pumps in the room except for the one connected to the yellow pipe and red pipe, no adjustments to the pump strength needed.</li>	<li>Look into the camera monitor to see the burn chamber. When it is full of plasma, press the igniter button.</li>	<li>Setup the SMES cells in the North West of Engineering and set an input of half the max; and an output that is half the input.</li></ol>Well done, you should have a functioning generator generating power. If the right side of the generator stops working, it means there is too much pressure and you need to turn on the pump that is connected to the red and yellow pipes to release the pressure. Make sure you don't take out too much pressure though.. "