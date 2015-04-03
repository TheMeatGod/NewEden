/*
An attempt to make "candles" that when lit supply a small amount of the a given gas into the environment.  The basic functionality is there,
but there is still a lot of work to do before they're ready to be put into the game. -Brodt7258
*/

/obj/item/weapon/special_candle

	name = "Gas Candle"
	desc = "Designed to release gas of a specified type when ignited."

	force = 3.0
	throwforce = 5.0
	throw_speed = 2
	throw_range = 5

	w_class = 2.0
	icon = 'icons/obj/gascandle.dmi'
	icon_state = "candle"
	var/icon_name
	var/wrapped = 1
	var/lit = 0
	var/burnt = 0
	var/burn_time = 500
	var/gas_type = 0
	var/chem_volume = 30

	var/obj/item/device/assembly_holder/rig = null

	New()
		..()
		create_reagents(chem_volume) // making the candle a chemical holder with a maximum volume of 30


	Del()
		..()
		del(reagents)


	proc/ignite(var/flavor_text = "[usr] lights the [name].") 	//Change icon, add to process list.  Handles explosions.  Explosion sizes may need balancing
		if(!src.lit)
			var/turf/candle_turf = get_turf(src)
			var/area/A = get_area(candle_turf)

			src.lit = 1
			src.luminosity = 3

			icon_state = "[icon_name]_lit"
			update_icon()

			src.force = 20
			src.damtype = "fire"

			if(src.gas_type == 1)
				if(reagents.get_reagent_amount("plasma")) // the plasma explodes when exposed to fire
					var/log_str = "[src] detonated in <A HREF='?_src_=holder;adminplayerobservecoodjump=1;X=[candle_turf.x];Y=[candle_turf.y];Z=[candle_turf.z]'>[A.name]</a> "
					log_str += " Last touched by: [src.fingerprintslast]"
					bombers += log_str
					message_admins(log_str, 0, 1)
					log_game(log_str)

					var/datum/effect/effect/system/reagents_explosion/e = new()
					e.set_up(round(reagents.get_reagent_amount("plasma") / 1.5, 1), get_turf(src), 0, 0)
					e.start()
					del(src)
					return
				if(reagents.get_reagent_amount("fuel")) // the fuel explodes, too, but much less violently
					var/log_str = "[src] detonated in <A HREF='?_src_=holder;adminplayerobservecoodjump=1;X=[candle_turf.x];Y=[candle_turf.y];Z=[candle_turf.z]'>[A.name]</a> "
					log_str += " Last touched by: [src.fingerprintslast]"
					bombers += log_str
					message_admins(log_str, 0, 1)
					log_game(log_str)

					var/datum/effect/effect/system/reagents_explosion/e = new()
					e.set_up(round(reagents.get_reagent_amount("fuel") / 2.5, 1), get_turf(src), 0, 0)
					e.start()
					del(src)
					return

			if(src.gas_type == 2)
				if(reagents.get_reagent_amount("plasma") || reagents.get_reagent_amount("fuel"))
					var/log_str = "[src] detonated in <A HREF='?_src_=holder;adminplayerobservecoodjump=1;X=[candle_turf.x];Y=[candle_turf.y];Z=[candle_turf.z]'>[A.name]</a> "
					log_str += " Last touched by: [src.fingerprintslast]"
					bombers += log_str
					message_admins(log_str, 0, 1)
					log_game(log_str)

					var/datum/gas_mixture/plasma_dump = new /datum/gas_mixture
					plasma_dump.temperature = 400
					plasma_dump.toxins = 200
					loc.assume_air(plasma_dump)

					var/turf/T = get_turf(src.loc)
					if(T)
						T.hotspot_expose(700,125)
						explosion(T, -1, -1, 2, 0)
					del(src)
					return



			if(usr)
				message_admins("[key_name_admin(usr)] ignited [src] at ([loc.x],[loc.y],[loc.z]).(<A HREF='?_src_=holder;adminplayerobservecoodjump=1;X=[loc.x];Y=[loc.y];Z=[loc.z]'>JMP</a>)")
				log_game("[key_name(usr)] ignited [src] at ([loc.x],[loc.y],[loc.z]).")

			else
				flavor_text = "<span class='warning'>The [name] ignites due to extreme heat!</span>"
				message_admins("[src] ignited by heat at ([loc.x],[loc.y],[loc.z]).(<A HREF='?_src_=holder;adminplayerobservecoodjump=1;X=[loc.x];Y=[loc.y];Z=[loc.z]'>JMP</a>)")
				log_game("[src] ignited by heat at ([loc.x],[loc.y],[loc.z]).")

			var/turf/T = get_turf(src)
			T.visible_message(flavor_text)
			processing_objects.Add(src)

		return


	attack_self(mob/user as mob) //Unwrap the candle, making it ready for ignition

		if(wrapped)
			wrapped = 0
			icon_state = "[icon_name]_unwrapped"
			src.update_icon()

			usr << "\red<B>You unwrap the [src.name], now it's ready to light</B>"
			return

		if(rig)
			if(!isigniter(rig.a_left))
				rig.a_left.activate()

			if(!isigniter(rig.a_right))
				rig.a_right.activate()

			user << "<span class='warning'>You prime \the [name]!</span>"

			msg_admin_attack("[user.name] ([user.ckey]) primed \a [src] (<A HREF='?_src_=holder;adminplayerobservecoodjump=1;X=[user.x];Y=[user.y];Z=[user.z]'>JMP</a>)")
			add_fingerprint(user)
			if(iscarbon(user))
				var/mob/living/carbon/C = user
				C.throw_mode_on()

			return

		if(lit)
			usr << "\red<B>Careful, you might burn yourself!</B>"
			return

		if(!wrapped)
			usr << "\red<B>You need something to ignite this with!</B>"
			return


	attackby(obj/item/weapon/W as obj, mob/user as mob) //check if it's a tool that can ignite other objects
		..()

		if(!wrapped && !lit && !burnt)
			if(istype(W, /obj/item/weapon/weldingtool))
				var/obj/item/weapon/weldingtool/WT = W
				if(WT.isOn())//Badasses dont get blinded while lighting their cig with a welding tool
					src.ignite("<span class='notice'>[user] casually lights the [name] with [W], what a badass.</span>")

			else if(istype(W, /obj/item/weapon/lighter/zippo))
				var/obj/item/weapon/lighter/zippo/Z = W
				if(Z.lit)
					src.ignite("<span class='rose'>With a single flick of their wrist, [user] smoothly lights their [name] with the [W]. Damn they're cool.</span>")

			else if(istype(W, /obj/item/weapon/lighter))
				var/obj/item/weapon/lighter/L = W
				if(L.lit)
					src.ignite("<span class='notice'>After some fiddling, [user] manages to light the [name] with [W].</span>")

			else if(istype(W, /obj/item/weapon/match))
				var/obj/item/weapon/match/M = W
				if(M.lit)
					src.ignite("<span class='notice'>[user] lights the [name] with their [W].</span>")

			else if(istype(W, /obj/item/weapon/melee/energy/sword))
				var/obj/item/weapon/melee/energy/sword/S = W
				if(S.active)
					src.ignite("<span class='warning'>[user] swings their [W], nearly chopping off their own hand. They light the [name] in the process.</span>")

			else if(istype(W, /obj/item/device/assembly/igniter))
				src.ignite("<span class='notice'>[user] fiddles with [W], and manages to light the [name].</span>")

			else if (istype(W,/obj/item/device/assembly_holder))
				if (rig)
					user << "\red There is another device in the way."
					return ..()
				user.visible_message("[user] begins rigging [W] to \the [src].", "You begin rigging [W] to \the [src]")
				if(do_after(user, 20))
					user.visible_message("\blue [user] rigs [W] to \the [src].", "\blue  You rig [W] to \the [src]")

					var/obj/item/device/assembly_holder/H = W
					if (istype(H.a_left,/obj/item/device/assembly/igniter) || istype(H.a_right,/obj/item/device/assembly/igniter))

						message_admins("[key_name_admin(user)] rigged [src] at ([loc.x],[loc.y],[loc.z]) for detonation.")
						log_game("[key_name(user)] rigged [src] at ([loc.x],[loc.y],[loc.z]) for detonation.")
						bombers += "[key_name(user)] rigged [src] at ([loc.x],[loc.y],[loc.z]) for detonation."

					rig = W
					user.drop_item()
					W.loc = src

					overlays += "detonator"

			else
				usr << "\red<B>I don't think this is how the instructions say to do it...</B>"

			user.update_inv_l_hand(0)
			user.update_inv_r_hand(1)
			return ..()

		else if(wrapped)
			usr << "\red<B>This might work better if you removed the wrapper...</B>"
		else
			usr << "\red<B>How is this supposed to work?</B>"


	afterattack(obj/item/weapon/reagent_containers/glass/glass, mob/user as mob, proximity)
		..()

		if(!wrapped)
			if(!proximity) return
			if(istype(glass))	//you can dip candle into beakers
				var/transfered = glass.reagents.trans_to(src, chem_volume)
				if(transfered)	//if reagents were transfered, show the message
					user << "<span class='notice'>You dip \the [src] into \the [glass].</span>"
				else			//if not, either the beaker was empty, or the candle was full
					if(!glass.reagents.total_volume)
						user << "<span class='notice'>[glass] is empty.</span>"
					else
						user << "<span class='notice'>[src] is full.</span>"

		else
			user << "<span class='notice'>Try unwrapping your [src] first.</span>"


	process() 		//every tick, transfer gas into the air, check if there's any left inside it.
		var/turf/location = get_turf(src)

		if(lit)

			var/datum/gas_mixture/gas_per_tick = new /datum/gas_mixture
			gas_per_tick.temperature = T0C + 20

			switch(gas_type) //I couldn't think of a nicer way to do this.
				if(1)
					gas_per_tick.oxygen = 1
					gas_per_tick.update_values()
				if(2)
					gas_per_tick.toxins = 1
					gas_per_tick.update_values()
					gas_per_tick.temperature = 400
				if(3)
					gas_per_tick.nitrogen = 1
					gas_per_tick.update_values()
				if(4)
					gas_per_tick.carbon_dioxide = 1
					gas_per_tick.update_values()
				if(5)
					var/datum/gas/sleeping_agent/trace_gas = new
					gas_per_tick.trace_gases += trace_gas
					trace_gas.moles = 1
					gas_per_tick.update_values()

			loc.assume_air(gas_per_tick)
			burn_time--

		if(burn_time < 1) 	//If there's nothing in it, stop processing and switch to the burnt out icon
			src.die()

		if(location && lit)		//Also, start fires if there is flammable stuff around, likely to interact interestingly with the plasma varient...
			location.hotspot_expose(700, 5)

		return

	proc/die()
		src.icon_state = "[icon_name]_burnt"
		src.update_icon()

		src.luminosity = 0
		src.lit = 0
		src.burnt = 1
		processing_objects.Remove(src)


	temperature_expose(datum/gas_mixture/air, temperature, volume) //Allow candles to be ignited by hot environments
		if(!lit && !wrapped && (temperature > T0C+400))
			src.ignite()
		return ..()

	examine()
		set src in view()
		..()
		if (!(usr in view(2)) && usr!=src.loc) return

		usr << "<span class='notice'>it is currently [wrapped ? "wrapped up in its packaging." : "unwrapped."]"

		if(rig)
			usr << "<span class='notice'>There is some kind of device rigged to the candle."

		if(src.reagents.total_volume)
			usr << "<span class='notice'>It seems to be soaked in some kind of fluid."



//SPECIFIC ITEM TYPES BELOW, FUNCTIONAL CODE ABOVE!!!!



	oxygen_candle 	//Main item type, a candle that is very useful for restoring O2 in an area where it has been depleted

		name = "Emergency O2 Candle"
		desc = "A candle that produces a small supply of oxygen for a very long time when lit.  Useful in emergencies.  See, NT does care!"
		icon_name = "oxygen_candle"
		icon_state = "oxygen_candle_wrapped"
		item_state = "oxygen_candle"
		gas_type = 1


	plasma_candle 	//A "secret" item, mostly for traitors to cause havoc with.  No possible friendly uses...

		name = "Plasma Candle"
		desc = "This is a horrible idea!"
		icon_name = "plasma_candle"
		icon_state = "plasma_candle_wrapped"
		item_state = "oxygen_candle"
		gas_type = 2

	nitrogen_candle //Because why not?

		name = "Nitrogen Candle"
		desc = "Because why not?"
		icon_name = "nitrogen_candle"
		icon_state = "nitrogen_candle_wrapped"
		item_state = "oxygen_candle"
		gas_type = 3

	carbondioxide_candle //See above comment

		name = "Carbon Dioxide Candle"
		desc = "Probably not the most effective item..."
		icon_name = "carbondioxide_candle"
		icon_state = "carbondioxide_candle_wrapped"
		item_state = "oxygen_candle"
		gas_type = 4

	nitrous_candle //This may have some applications...

		name = "Nitrous Oxide Candle"
		desc = "Who needs the dentist?"
		icon_name = "nitrous_candle"
		icon_state = "nitrous_candle_wrapped"
		item_state = "oxygen_candle"
		gas_type = 5