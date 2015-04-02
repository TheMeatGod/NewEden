datum
	chemical_reaction
		var/name = null
		var/id = null
		var/result = null
		var/list/required_reagents = new/list()
		var/list/required_catalysts = new/list()

		var/atom/required_container = null // the container required for the reaction to happen
		var/required_other = 0 // an integer required for the reaction to happen

		var/result_amount = 0
		var/secondary = 0 // set to nonzero if secondary reaction
		var/list/secondary_results = list()		//additional reagents produced by the reaction

		var/required_temp = 0
		var/mix_message = "The solution begins to bubble."

		proc
			on_reaction(var/datum/reagents/holder, var/created_volume)
				return

		explosion_potassium
			name = "Explosion"
			id = "explosion_potassium"
			result = null
			required_reagents = list("water" = 1, "potassium" = 1)
			result_amount = 2
			on_reaction(var/datum/reagents/holder, var/created_volume)
				var/datum/effect/effect/system/reagents_explosion/e = new()
				e.set_up(round (created_volume/10, 1), holder.my_atom, 0, 0)
				e.holder_damage(holder.my_atom)
				if(isliving(holder.my_atom))
					e.amount *= 0.5
					var/mob/living/L = holder.my_atom
					if(L.stat!=DEAD)
						e.amount *= 0.5
				e.start()
				holder.clear_reagents()
				return

		emp_pulse
			name = "EMP Pulse"
			id = "emp_pulse"
			result = null
			required_reagents = list("uranium" = 1, "iron" = 1) // Yes, laugh, it's the best recipe I could think of that makes a little bit of sense
			result_amount = 2

			on_reaction(var/datum/reagents/holder, var/created_volume)
				var/location = get_turf(holder.my_atom)
				// 100 created volume = 4 heavy range & 7 light range. A few tiles smaller than traitor EMP grandes.
				// 200 created volume = 8 heavy range & 14 light range. 4 tiles larger than traitor EMP grenades.
				empulse(location, round(created_volume / 24), round(created_volume / 14), 1)
				holder.clear_reagents()
				return

		water
			name = "Water"
			id = "water"
			result = "water"
			required_reagents = list("oxygen" = 1, "hydrogen" = 2)
			required_container = //beaker that can hold gases safely
			result_amount = 1

		lube