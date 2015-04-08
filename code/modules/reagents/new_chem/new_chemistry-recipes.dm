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
			result_amount = 1

		lube
			name = "Space Lube"
			id = "lube"
			result = "lube"
			required_reagents = list("water" = 1, "silicon" = 2)
			result_amount = 1
			mix_message = "The solution mixes into an oily substance."

		lsd
			name = "Lysergic Acid Diethylamide"
			id = "lsd"
			result = "lsd"
			required_reagents = list()
			result_amount = 1

		mdma
			name = "Ecstasy"
			id = "mdma"
			result = "mdma"
			required_reagents = list()
			result_amount = 1

		bz_78
			name = "BZ 78"
			id = "bz_78"
			result = "bz_78"
			required reagents = list()
			result_amount = 1

		nitroglycerin
			name = "Nitroglycerin"
			id = "nitroglycerin"
			result = "nitroglycerin"
			required_reagents = list()
			result_amount = 1
////////////////////////////////////////////////////////////////////////////////////
		sotalol
			name = "Sotalol
			id = "sotalol"
			result = "sotalol"
			required_reagents = list()
			result_amount = 1

		cortisolulase
			name = "Cortisolulase"
			id = "cortisolulase"
			result = "cortisolulase"
			required_reagents = list()
			result_amount = 1

		aluminum_sulfate
			name = "Aluminum Sulfate"
			id = "aluminum_sulfate"
			result = "aluminum_sulfate"
			required_reagents = list()
			result_amount = 1

		chitosan
			name = "Chitosan"
			id = "chitosan"
			result = "chitosan"
			required_reagents = list()
			result_amount = 1

		kelotane
			name = "Kelotane"
			id = "kelotane"
			result = "kelotane"
			required_reagents = list()
			result_amount = 1

		silvadene
			name = "Silvadene"
			id = "silvadene"
			result = "silvadene"
			required_reagents = list()
			result_amount = 1

		salbutamol
			name = "Salbutamol"
			id = "salbutamol"
			result = "salbutamol"
			required_reagents = list()
			result_amount = 1

		oxy_suspension
			name = "Lipid-Oxygen Suspension"
			id = "oxy_suspension"
			result = "oxy_suspension"
			required_reagents = list()
			result_amount = 1

		medellamniscine
			name = "Medellamniscine"
			id = "medellamniscine"
			result = "medellamniscine"
			required_reagents = list()
			result_amount = 1

		active_charcoal
			name = "Activated Charcoal"
			id = "active_charcoal"
			result = "active_charcoal"
			required_reagents = list()
			result_amount = 1

		paracetamol
			name = "Paracetamol"
			id = "paracetamol"
			result = "paracetamol"
			required_reagents = list()
			result_amount = 1

		codeine
			name = "Codeine"
			id = "codeine"
			result = "codeine"
			required_reagents = list()
			result_amount = 1

		morphine
			name = "Morphine"
			id = "morphine"
			result = "morphine"
			required_reagents = list()
			result_amount = 1

		dimethyl_mercury
			name = "Dimethyl Mercury"
			id = "dimethyl_mercury"
			result = "dimethyl_mercury"
			required_reagents = list()
			result_amount = 1

		potassium_iodide
			name = "Potassium Iodide"
			id = "potassium_iodide"
			result = "potassium_iodide"
			required_reagents = list()
			result_amount = 1

		arithrazine
			name = "Arithrazine"
			id = "arithrazine"
			result = "arithrazine"
			required_reagents = list()
			result_amount = 1

		mannitol
			name = "Mannitol"
			id = "mannitol"
			result = "mannitol
			required_reagents = list()
			result_amount = 1
			secondary_results = list("sorbitol" = 1)

		atropine
			name = "Atropine"
			id = "atropine"
			result = "atropine"
			required_reagents = list()
			result_amount = 1

		ephedrine
			name = "Ephedrine"
			id = "ephedrine"
			result = "ephedrine"
			required_reagents = list()
			result_amount = 1

		epinepherine
			name = "Epinepherine"
			id = "epinepherine
			result = "epinepherine"
			required_reagents = list()
			result_amount = 1

		midazolam
			name = "Midazolam"
			id = "midazolam"
			result = "midazolam"
			required_reagents = list()
			result_amount = 1

		cryoxadone
			name = "Cryoxadone"
			id = "cryoxadone"
			result = "cryoxadone"
			required_reagents = list()
			result_amount = 1

		clonexadone
			name = "Clonexadone"
			id = "clonexadone"
			result = "clonexadone"
			required_reagents = list()
			result_amount = 1

		rezadone
			name = "Rezadone"
			id = "rezadone"
			result = "rezadone"
			required_reagents = list()
			result_amount = 1

		saline
			name = "Saline Flush"
			id = "saline"
			result = "saline"
			required_reagents = list("water" = 2, "sodium_chloride" = 1)
			result_amount = 1

		space_cleaner
			name = "Space Cleaner"
			id = "space_cleaner"
			result = "space_cleaner"
			required_reagents = list("sodium_hypochlorite" = 1, "water" = 1, "ammonia" = 1)
			result_amount = 1

		orexin
			name = "Orexin-Z"
			id = "orexin"
			result = "orexin"
			required_reagents = list("blood" = 4, "sacid" = 1)
			result_amount = 1
//////////////////////////////////////////////////////////////////////////////////////////////
		vx
			name = "VX Agent"
			id = "vx"
			result = "vx"
			required_reagents = list("methyl_phosphonous_dichloride" = 6, "dimethyl_mercury" = 2)
			result_amount = 1

		phosphorus_trichloride
			name = "Phosphorus Trichloride"
			id = "phosphorus_trichloride"
			result = "phosphorus_trichloride"
			required_reagents = list("phosphorus" = 1, "chlorine" = 3)
			result_amount = 1

		methyl_phosphonous_dichloride
			name = "Methyl Phosphonous Dichloride"
			id = "methyl_phosphonous_dichloride"
			result = "methyl_phosphonous_dichloride"
			required_reagents = list("ethanol" = 2, "phosphorus_trichloride" = 1)
			required_temp = 300
			result_amount = 1

		potassium_chloride
			name = "Potassium Chloride"
			id = "potassium_chloride"
			result = "potassium_chloride"
			required_reagents = list("potassium" = 1, "chlorine" = 1)
			required_temp = 380
			result_amount = 1

		ammonia
			name = "Ammonia"
			id = "ammonia"
			result = "ammonia"
			required_reagents = list("nitrogen" = 1, "hydrogen" = 3)
			required_catalysts = list("iron" = 1)
			required_temp = 400
			result_amount = 1

		ethanol
			name = "Ethanol"
			id = "ethanol"
			result = "ethanol"
			required_reagents = list("glucose" = 1)
			required_catalysts = list("yeast" = 1)
			result_amount = 1

		acetylene
			name = "Acetylene"
			id = "acetylene"
			result = "acetylene"
			requred_reagents = list("ethanol" = 1, "carbon" = 2)
			required_temp = 420
			result_amount = 2

		oxy_acetylene
			name = "Oxy Acetylene"
			id = "oxy_acetylene"
			result = "oxy_acetylene"
			required_reagents = list("acetylene" = 1, "oxygen" = 1)
			result_amount = 1

		ethyamines
			name = "Ethylamine"
			id = "ethylamine"
			result = "ethylamine"
			required_reagents = list("ethanol" = 1, "ammonia" = 1)
			required_catalysts = list("silica" = 1)
			result_amount = 1
			secondary_results = list("diethylamine" = 1, "triethylamine" = 1)

		thermite
			name = "Thermite"
			id = "thermite"
			result = "thermite
			required_reagents = list("iron" = 1, "aluminum" = 1)
			result_amount = 1

		thermate
			name = "Thermate"
			id = "thermate"
			result = "thermate
			required_reagents = list("thermite" = 1, "orexin" = 1)
			required_temp = 350
			result_amount = 1

		carbon_dioxide
			name = "Carbon Dioxide"
			id = "carbon_dioxide"
			result = "carbon_dioxide"
			required_reagents = list("carbon" = 1, "oxygen" = 2)
			result_amount = 1

		carbon_monoxide
			name = "Carbon Monoxide"
			id = "carbon_monoxide"
			result = "carbon_monoxide"
			required_reagents = list("carbon_dioxide" = 1)
			required_catalysts = list("iron" = 1)
			required_temp = 390
			result_amount = 1

		acetonitrile
			name = "Acetonitrile"
			id = "acetonitrile"
			result = "acetonitrile"
			required_reagents = list("ammonia" = 1, "carbon_monoxide" = 1, "hydrogen" = 2)
			result_amount = 1
			secondary_results = list("oxygen" = 1)

		pyridine
			name = "Pyridine"
			id = "pyridine"
			result = "pyridine"
			required_reagents = list("acetonitrile" = 1, "acetylene" = 2)
			required_catalysts = list("nickel" = 1)
			result_amount = 1

		nicotine
			name = "Nicotine"
			id = "nicotine"
			result = "nicotine"
			required_reagents = list("pyridine" = 1, "ammonia" = 1)
			result_amount = 1

		generic
			name = ""
			id = ""
			result = ""
			required_reagents = list()
			result_amount = 1