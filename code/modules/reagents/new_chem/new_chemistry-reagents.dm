#define SOLID 1
#define LIQUID 2
#define GAS 3
#define REAGENTS_OVERDOSE 30
#define REM REAGENTS_EFFECT_MULTIPLIER

//The reaction procs must ALWAYS set src = null, this detaches the proc from the object (the reagent)
//so that it can continue working when the reagent is deleted while the proc is still active.

//IF A REAGENT DOESNT HAVE A COMMENT THAT LOOKS LIKE:
//Replaces genericchem
//THEN A REPLACEMENT SHOULD BE FOUND EVENTUALLY


datum
	reagent
		var/name = "Reagent"
		var/id = "reagent"
		var/description = ""
		var/datum/reagents/holder = null
		var/reagent_state = SOLID
		var/list/data = null
		var/volume = 0
		var/nutriment_factor = 0
		var/custom_metabolism = REAGENTS_METABOLISM
		var/overdose = 0
		var/overdose_dam = 1
		var/scannable = 0 //shows up on health analyzers
		var/glass_icon_state = null
		var/glass_name = null
		var/glass_desc = null
		var/glass_center_of_mass = null
		//var/list/viruses = list()
		var/color = "#000000" // rgb: 0, 0, 0 (does not support alpha channels - yet!)
		var/secret = 0

		proc
			reaction_mob(var/mob/M, var/method=TOUCH, var/volume) //By default we have a chance to transfer some
				if(!istype(M, /mob/living))	return 0
				var/datum/reagent/self = src
				src = null										  //of the reagent to the mob on TOUCHING it.

				if(self.holder)		//for catching rare runtimes
					if(!istype(self.holder.my_atom, /obj/effect/effect/smoke/chem))
						// If the chemicals are in a smoke cloud, do not try to let the chemicals "penetrate" into the mob's system (balance station 13) -- Doohl

						if(method == TOUCH)

							var/chance = 1
							var/block  = 0

							for(var/obj/item/clothing/C in M.get_equipped_items())
								if(C.permeability_coefficient < chance) chance = C.permeability_coefficient
								if(istype(C, /obj/item/clothing/suit/bio_suit))
									// bio suits are just about completely fool-proof - Doohl
									// kind of a hacky way of making bio suits more resistant to chemicals but w/e
									if(prob(75))
										block = 1

								if(istype(C, /obj/item/clothing/head/bio_hood))
									if(prob(75))
										block = 1

							chance = chance * 100

							if(prob(chance) && !block)
								if(M.reagents)
									M.reagents.add_reagent(self.id,self.volume/2)
				return 1

			reaction_obj(var/obj/O, var/volume) //By default we transfer a small part of the reagent to the object
				src = null						//if it can hold reagents. nope!
				//if(O.reagents)
				//	O.reagents.add_reagent(id,volume/3)
				return

			reaction_turf(var/turf/T, var/volume)
				src = null
				return

			on_mob_life(var/mob/living/M as mob, var/alien)
				if(!istype(M, /mob/living))
					return //Noticed runtime errors from pacid trying to damage ghosts, this should fix. --NEO
				if( (overdose > 0) && (volume >= overdose))//Overdosing, wooo
					M.adjustToxLoss(overdose_dam)
				holder.remove_reagent(src.id, custom_metabolism) //By default it slowly disappears.
				return

			on_move(var/mob/M)
				return

			// Called after add_reagents creates a new reagent.
			on_new(var/data)
				return

			// Called when two reagents of the same are mixing.
			on_merge(var/data)
				return

			on_update(var/atom/A)
				return

		blood
			data = new/list("donor"=null,"viruses"=null,"species"="Human","blood_DNA"=null,"blood_type"=null,"blood_colour"= "#A10808","resistances"=null,"trace_chem"=null, "antibodies" = null)
			name = "Blood"
			id = "blood"
			reagent_state = LIQUID
			color = "#C80000" // rgb: 200, 0, 0

			glass_icon_state = "glass_red"
			glass_name = "glass of tomato juice"
			glass_desc = "Are you sure this is tomato juice?"

			reaction_mob(var/mob/M, var/method=TOUCH, var/volume)
				var/datum/reagent/blood/self = src
				src = null
				if(self.data && self.data["viruses"])
					for(var/datum/disease/D in self.data["viruses"])
						//var/datum/disease/virus = new D.type(0, D, 1)
						// We don't spread.
						if(D.spread_type == SPECIAL || D.spread_type == NON_CONTAGIOUS) continue

						if(method == TOUCH)
							M.contract_disease(D)
						else //injected
							M.contract_disease(D, 1, 0)
				if(self.data && self.data["virus2"] && istype(M, /mob/living/carbon))//infecting...
					var/list/vlist = self.data["virus2"]
					if (vlist.len)
						for (var/ID in vlist)
							var/datum/disease2/disease/V = vlist[ID]

							if(method == TOUCH)
								infect_virus2(M,V.getcopy())
							else
								infect_virus2(M,V.getcopy(),1) //injected, force infection!
				if(self.data && self.data["antibodies"] && istype(M, /mob/living/carbon))//... and curing
					var/mob/living/carbon/C = M
					C.antibodies |= self.data["antibodies"]

			on_merge(var/data)
				if(data["blood_colour"])
					color = data["blood_colour"]
				return ..()

			on_update(var/atom/A)
				if(data["blood_colour"])
					color = data["blood_colour"]
				return ..()

			reaction_turf(var/turf/simulated/T, var/volume)//splash the blood all over the place
				if(!istype(T)) return
				var/datum/reagent/blood/self = src
				src = null
				if(!(volume >= 3)) return

				if(!self.data["donor"] || istype(self.data["donor"], /mob/living/carbon/human))
					blood_splatter(T,self,1)
				else if(istype(self.data["donor"], /mob/living/carbon/monkey))
					var/obj/effect/decal/cleanable/blood/B = blood_splatter(T,self,1)
					if(B) B.blood_DNA["Non-Human DNA"] = "A+"
				else if(istype(self.data["donor"], /mob/living/carbon/alien))
					var/obj/effect/decal/cleanable/blood/B = blood_splatter(T,self,1)
					if(B) B.blood_DNA["UNKNOWN DNA STRUCTURE"] = "X*"
				return

/* Must check the transfering of reagents and their data first. They all can point to one disease datum.

			Del()
				if(src.data["virus"])
					var/datum/disease/D = src.data["virus"]
					D.cure(0)
				..()
*/
		vaccine
			//data must contain virus type
			name = "Vaccine"
			id = "vaccine"
			reagent_state = LIQUID
			color = "#C81040" // rgb: 200, 16, 64

			reaction_mob(var/mob/M, var/method=TOUCH, var/volume)
				var/datum/reagent/vaccine/self = src
				src = null
				if(self.data&&method == INGEST)
					for(var/datum/disease/D in M.viruses)
						if(istype(D, /datum/disease/advance))
							var/datum/disease/advance/A = D
							if(A.GetDiseaseID() == self.data)
								D.cure()
						else
							if(D.type == self.data)
								D.cure()

					M.resistances += self.data
				return

/* ELEMENTS */

		oxygen
			name = "Oxygen"
			id = "oxygen"
			description = "A colorless, odorless gas."
			reagent_state = GAS
			color = "#808080" // rgb: 128, 128, 128

			custom_metabolism = 0.01

			on_mob_life(var/mob/living/M as mob, var/alien)
				if(M.stat == 2) return
				if(alien && alien == IS_VOX)
					M.adjustToxLoss(REAGENTS_METABOLISM)
					holder.remove_reagent(src.id, REAGENTS_METABOLISM) //By default it slowly disappears.
					return
				..()

		copper
			name = "Copper"
			id = "copper"
			description = "A highly ductile metal."
			color = "#6E3B08" // rgb: 110, 59, 8

			custom_metabolism = 0.01

		nitrogen
			name = "Nitrogen"
			id = "nitrogen"
			description = "A colorless, odorless, tasteless gas."
			reagent_state = GAS
			color = "#808080" // rgb: 128, 128, 128

			custom_metabolism = 0.01

			on_mob_life(var/mob/living/M as mob, var/alien)
				if(M.stat == 2) return
				if(alien && alien == IS_VOX)
					M.adjustOxyLoss(-2*REM)
					holder.remove_reagent(src.id, REAGENTS_METABOLISM) //By default it slowly disappears.
					return
				..()

		hydrogen
			name = "Hydrogen"
			id = "hydrogen"
			description = "A colorless, odorless, nonmetallic, tasteless, highly combustible diatomic gas."
			reagent_state = GAS
			color = "#808080" // rgb: 128, 128, 128

			custom_metabolism = 0.01

		potassium
			name = "Potassium"
			id = "potassium"
			description = "A soft, low-melting solid that can easily be cut with a knife. Reacts violently with water."
			reagent_state = SOLID
			color = "#A0A0A0" // rgb: 160, 160, 160

			custom_metabolism = 0.01

		mercury
			name = "Mercury"
			id = "mercury"
			description = "A chemical element."
			reagent_state = LIQUID
			color = "#484848" // rgb: 72, 72, 72
			overdose = REAGENTS_OVERDOSE

			on_mob_life(var/mob/living/M as mob)
				if(!M) M = holder.my_atom
				if(M.canmove && !M.restrained() && istype(M.loc, /turf/space))
					step(M, pick(cardinal))
				if(prob(5)) M.emote(pick("twitch","drool","moan"))
				M.adjustBrainLoss(2)
				..()
				return

		sulfur
			name = "Sulfur"
			id = "sulfur"
			description = "A chemical element with a pungent smell."
			reagent_state = SOLID
			color = "#BF8C00" // rgb: 191, 140, 0

			custom_metabolism = 0.01

		carbon
			name = "Carbon"
			id = "carbon"
			description = "A chemical element, the building block of life."
			reagent_state = SOLID
			color = "#1C1300" // rgb: 30, 20, 0

			custom_metabolism = 0.01

			reaction_turf(var/turf/T, var/volume)
				src = null
				if(!istype(T, /turf/space))
					var/obj/effect/decal/cleanable/dirt/dirtoverlay = locate(/obj/effect/decal/cleanable/dirt, T)
					if (!dirtoverlay)
						dirtoverlay = new/obj/effect/decal/cleanable/dirt(T)
						dirtoverlay.alpha = volume*30
					else
						dirtoverlay.alpha = min(dirtoverlay.alpha+volume*30, 255)

		chlorine
			name = "Chlorine"
			id = "chlorine"
			description = "A chemical element with a characteristic odour."
			reagent_state = GAS
			color = "#808080" // rgb: 128, 128, 128
			overdose = REAGENTS_OVERDOSE

			on_mob_life(var/mob/living/M as mob)
				if(!M) M = holder.my_atom
				M.take_organ_damage(1*REM, 0)
				..()
				return

		fluorine
			name = "Fluorine"
			id = "fluorine"
			description = "A highly-reactive chemical element."
			reagent_state = GAS
			color = "#808080" // rgb: 128, 128, 128
			overdose = REAGENTS_OVERDOSE

			on_mob_life(var/mob/living/M as mob)
				if(!M) M = holder.my_atom
				M.adjustToxLoss(1*REM)
				..()
				return

		sodium
			name = "Sodium"
			id = "sodium"
			description = "A chemical element, readily reacts with water."
			reagent_state = SOLID
			color = "#808080" // rgb: 128, 128, 128

			custom_metabolism = 0.01

		phosphorus
			name = "Phosphorus"
			id = "phosphorus"
			description = "A chemical element, the backbone of biological energy carriers."
			reagent_state = SOLID
			color = "#832828" // rgb: 131, 40, 40

			custom_metabolism = 0.01

		lithium
			name = "Lithium"
			id = "lithium"
			description = "A chemical element, used as antidepressant."
			reagent_state = SOLID
			color = "#808080" // rgb: 128, 128, 128
			overdose = REAGENTS_OVERDOSE

			on_mob_life(var/mob/living/M as mob)
				if(!M) M = holder.my_atom
				if(M.canmove && !M.restrained() && istype(M.loc, /turf/space))
					step(M, pick(cardinal))
				if(prob(5)) M.emote(pick("twitch","drool","moan"))
				..()
				return

		iron
			name = "Iron"
			id = "iron"
			description = "Pure iron is a metal."
			reagent_state = SOLID
			color = "#353535"
			overdose = REAGENTS_OVERDOSE

		gold
			name = "Gold"
			id = "gold"
			description = "Gold is a dense, soft, shiny metal and the most malleable and ductile metal known."
			reagent_state = SOLID
			color = "#F7C430" // rgb: 247, 196, 48

		silver
			name = "Silver"
			id = "silver"
			description = "A soft, white, lustrous transition metal, it has the highest electrical conductivity of any element and the highest thermal conductivity of any metal."
			reagent_state = SOLID
			color = "#D0D0D0" // rgb: 208, 208, 208

		uranium
			name ="Uranium"
			id = "uranium"
			description = "A silvery-white metallic chemical element in the actinide series, weakly radioactive."
			reagent_state = SOLID
			color = "#B8B8C0" // rgb: 184, 184, 192

			on_mob_life(var/mob/living/M as mob)
				if(!M) M = holder.my_atom
				M.apply_effect(1,IRRADIATE,0)
				..()
				return

			reaction_turf(var/turf/T, var/volume)
				src = null
				if(volume >= 3)
					if(!istype(T, /turf/space))
						var/obj/effect/decal/cleanable/greenglow/glow = locate(/obj/effect/decal/cleanable/greenglow, T)
						if(!glow)
							new /obj/effect/decal/cleanable/greenglow(T)
						return

		aluminum
			name = "Aluminum"
			id = "aluminum"
			description = "A silvery white and ductile member of the boron group of chemical elements."
			reagent_state = SOLID
			color = "#A8A8A8" // rgb: 168, 168, 168

		silicon
			name = "Silicon"
			id = "silicon"
			description = "A tetravalent metalloid, silicon is less reactive than its chemical analog carbon."
			reagent_state = SOLID
			color = "#A8A8A8" // rgb: 168, 168, 168

		iodine
			name = "Iodine"
			id = "iodine"
			description = "A slippery solution."
			reagent_state = LIQUID
			color = "#C8A5DC"

		bromine
			name = "Bromine"
			id = "bromine"
			description = "A slippery solution."
			reagent_state = LIQUID
			color = "#C8A5DC"



/* Precursors and shit that nobody will really use outside synthesis */

		acetylene
			name = "Nitroglycerin"
			id = "nitroglycerin"
			description = "Nitroglycerin is a heavy, colorless, oily, explosive liquid obtained by nitrating glycerol."
			reagent_state = LIQUID
			color = "#808080" // rgb: 128, 128, 128

		sodium_hypochlorite
			name = "Nitroglycerin"
			id = "nitroglycerin"
			description = "Nitroglycerin is a heavy, colorless, oily, explosive liquid obtained by nitrating glycerol."
			reagent_state = LIQUID
			color = "#808080" // rgb: 128, 128, 128

		alunogen
			name = "Nitroglycerin"
			id = "nitroglycerin"
			description = "Nitroglycerin is a heavy, colorless, oily, explosive liquid obtained by nitrating glycerol."
			reagent_state = LIQUID
			color = "#808080" // rgb: 128, 128, 128

		sugar
			name = "Sugar"
			id = "sugar"
			description = "A white, odorless, crystalline powder with a sweet taste. Also known as sucrose"
			reagent_state = SOLID
			color = "#FFFFFF" // rgb: 255, 255, 255

			glass_icon_state = "iceglass"
			glass_name = "glass of sugar"
			glass_desc = "The organic compound commonly known as table sugar and sometimes called saccharose. This white, odorless, crystalline powder has a pleasing, sweet taste."

			on_mob_life(var/mob/living/M as mob)
				M.nutrition += 1*REM
				..()
				return

		glucose
			name = "Nitroglycerin"
			id = "nitroglycerin"
			description = "Nitroglycerin is a heavy, colorless, oily, explosive liquid obtained by nitrating glycerol."
			reagent_state = LIQUID
			color = "#808080" // rgb: 128, 128, 128

		fructose
			name = "Nitroglycerin"
			id = "nitroglycerin"
			description = "Nitroglycerin is a heavy, colorless, oily, explosive liquid obtained by nitrating glycerol."
			reagent_state = LIQUID
			color = "#808080" // rgb: 128, 128, 128

		phenol
			name = "Phenol"
			id = "phenol"
			description = "Used for certain medical recipes."
			reagent_state = LIQUID
			color = "#C8A5DC"

		ash
			name = "Ash"
			id = "ash"
			description = "Basic ingredient in a couple of recipes."
			reagent_state = LIQUID
			color = "#C8A5DC"

		acetone
			name = "Acetone"
			id = "acetone"
			description = "Common ingredient in other recipes."
			reagent_state = LIQUID
			color = "#C8A5DC"




/* Misc Chems */

		#define WATER_LATENT_HEAT 19000 // How much heat is removed when applied to a hot turf, in J/unit (19000 makes 120 u of water roughly equivalent to 4L)
		water
			name = "Water"
			id = "water"
			description = "A ubiquitous chemical substance that is composed of hydrogen and oxygen."
			reagent_state = LIQUID
			color = "#0064C8" // rgb: 0, 100, 200
			custom_metabolism = 0.01

			glass_icon_state = "glass_clear"
			glass_name = "glass of water"
			glass_desc = "The father of all refreshments."

			reaction_turf(var/turf/simulated/T, var/volume)
				if (!istype(T)) return

				//If the turf is hot enough, remove some heat
				var/datum/gas_mixture/environment = T.return_air()
				var/min_temperature = T0C + 100	//100C, the boiling point of water

				if (environment && environment.temperature > min_temperature) //abstracted as steam or something
					var/removed_heat = between(0, volume*WATER_LATENT_HEAT, -environment.get_thermal_energy_change(min_temperature))
					environment.add_thermal_energy(-removed_heat)
					if (prob(5))
						T.visible_message("\red The water sizzles as it lands on \the [T]!")

				else //otherwise, the turf gets wet
					if(volume >= 3)
						if(T.wet >= 1) return
						T.wet = 1
						if(T.wet_overlay)
							T.overlays -= T.wet_overlay
							T.wet_overlay = null
						T.wet_overlay = image('icons/effects/water.dmi',T,"wet_floor")
						T.overlays += T.wet_overlay

						src = null
						spawn(800)
							if (!istype(T)) return
							if(T.wet >= 2) return
							T.wet = 0
							if(T.wet_overlay)
								T.overlays -= T.wet_overlay
								T.wet_overlay = null

				//Put out fires.
				var/hotspot = (locate(/obj/fire) in T)
				if(hotspot)
					del(hotspot)
					if(environment)
						environment.react() //react at the new temperature

			reaction_obj(var/obj/O, var/volume)
				var/turf/T = get_turf(O)
				var/hotspot = (locate(/obj/fire) in T)
				if(hotspot && !istype(T, /turf/space))
					var/datum/gas_mixture/lowertemp = T.remove_air( T:air:total_moles )
					lowertemp.temperature = max( min(lowertemp.temperature-2000,lowertemp.temperature / 2) ,0)
					lowertemp.react()
					T.assume_air(lowertemp)
					del(hotspot)
				if(istype(O,/obj/item/weapon/reagent_containers/food/snacks/monkeycube))
					var/obj/item/weapon/reagent_containers/food/snacks/monkeycube/cube = O
					if(!cube.wrapped)
						cube.Expand()

			reaction_mob(var/mob/M, var/method=TOUCH, var/volume)
				if (istype(M, /mob/living/carbon/slime))
					var/mob/living/carbon/slime/S = M
					S.apply_water()

		water/holywater
			name = "Holy Water"
			id = "holywater"
			description = "An ashen-obsidian-water mix, this solution will alter certain sections of the brain's rationality."
			color = "#E0E8EF" // rgb: 224, 232, 239

			glass_icon_state = "glass_clear"
			glass_name = "glass of holy water"
			glass_desc = "An ashen-obsidian-water mix, this solution will alter certain sections of the brain's rationality."

			on_mob_life(var/mob/living/M as mob)
				if(ishuman(M))
					if((M.mind in ticker.mode.cult) && prob(10))
						M << "\blue A cooling sensation from inside you brings you an untold calmness."
						ticker.mode.remove_cultist(M.mind)
						for(var/mob/O in viewers(M, null))
							O.show_message(text("\blue []'s eyes blink and become clearer.", M), 1) // So observers know it worked.
				holder.remove_reagent(src.id, 10 * REAGENTS_METABOLISM) //high metabolism to prevent extended uncult rolls.
				return

		lube
			name = "Space Lube"
			id = "lube"
			description = "Lubricant is a substance introduced between two moving surfaces to reduce the friction and wear between them. giggity."
			reagent_state = LIQUID
			color = "#009CA8" // rgb: 0, 156, 168
			overdose = REAGENTS_OVERDOSE

			reaction_turf(var/turf/simulated/T, var/volume)
				if (!istype(T)) return
				src = null
				if(volume >= 1)
					if(T.wet >= 2) return
					T.wet = 2
					spawn(800)
						if (!istype(T)) return
						T.wet = 0
						if(T.wet_overlay)
							T.overlays -= T.wet_overlay
							T.wet_overlay = null
						return

		//Replaces space drugs
		lsd
			name = "Lysergic Acid"
			id = "lsd"
			description = "A psychedelic drug, most commonly known as acid."
			reagent_state = LIQUID
			color = "#60A584" // rgb: 96, 165, 132
			overdose = REAGENTS_OVERDOSE

			on_mob_life(var/mob/living/M as mob)
				if(!M) M = holder.my_atom
				M.druggy = max(M.druggy, 15)
				if(isturf(M.loc) && !istype(M.loc, /turf/space))
					if(M.canmove && !M.restrained())
						if(prob(10)) step(M, pick(cardinal))
				if(prob(7)) M.emote(pick("twitch","drool","moan","giggle"))
				holder.remove_reagent(src.id, 0.5 * REAGENTS_METABOLISM)
				return

		//Replaces serotrotium
		mdma
			name = "MDMA"
			id = "mdma"
			description = "A psychoactive drug, commonly known as ecstasy."
			reagent_state = SOLID
			color = "#202040" // rgb: 20, 20, 40
			overdose = REAGENTS_OVERDOSE

			on_mob_life(var/mob/living/M as mob)
				if(ishuman(M))
					if(prob(7)) M.emote(pick("twitch","drool","moan","gasp"))
					holder.remove_reagent(src.id, 0.25 * REAGENTS_METABOLISM)
				return

		mindbreaker
			name = "Mindbreaker Toxin"
			id = "mindbreaker"
			description = "A powerful hallucinogen, it can cause fatal effects in users."
			reagent_state = LIQUID
			color = "#B31008" // rgb: 139, 166, 233
			custom_metabolism = 0.05
			overdose = REAGENTS_OVERDOSE

			on_mob_life(var/mob/living/M)
				if(!M) M = holder.my_atom
				M.hallucination += 10
				..()
				return

		glycerol
			name = "Glycerol"
			id = "glycerol"
			description = "Glycerol is a simple polyol compound. Glycerol is sweet-tasting and of low toxicity."
			reagent_state = LIQUID
			color = "#808080" // rgb: 128, 128, 128

			custom_metabolism = 0.01

		nitroglycerin
			name = "Nitroglycerin"
			id = "nitroglycerin"
			description = "Nitroglycerin is a heavy, colorless, oily, explosive liquid obtained by nitrating glycerol."
			reagent_state = LIQUID
			color = "#808080" // rgb: 128, 128, 128

			custom_metabolism = 0.01

		//Used for cautery
		silver_nitrate
			name = "Nitroglycerin"
			id = "nitroglycerin"
			description = "Nitroglycerin is a heavy, colorless, oily, explosive liquid obtained by nitrating glycerol."
			reagent_state = LIQUID
			color = "#808080" // rgb: 128, 128, 128

/* Medical Chems and non-toxin poisons */

		//Replaces inaprovaline
		//Possible balance later? Not important at the moment
		sotalol
			name = "Sotalol"
			id = "sotalol"
			description = "Beta-blocker that normalizes heart functionality. Commonly used to stabilize patients."
			reagent_state = LIQUID
			color = "#00BFFF" // rgb: 200, 165, 220
			overdose = REAGENTS_OVERDOSE
			scannable = 1

			on_mob_life(var/mob/living/M as mob)
				if(!M) M = holder.my_atom
				if(volume > overdose)
					var/mob/living/carbon/human/H = M
					var/datum/organ/internal/heart/O = H.internal_organs_by_name["heart"]
					if(O && istype(O))
						O.damage += 0.2
				else
					if(M.losebreath >= 10)
						M.losebreath = max(10, M.losebreath-5)

				holder.remove_reagent(src.id, REAGENTS_METABOLISM)
				return

		//Replaces Bicardine
		//Fix effects - balance heal dmg with other bruteheal chems
		cortisolulase
			name = "Cortisolulase"
			id = "cortisolulase"
			description = "Enzyme used to speed up the decomposition of cortisol, thereby healing wounds faster."
			reagent_state = LIQUID
			color = "#BF0000"
			overdose = REAGENTS_OVERDOSE
			scannable = 1

			on_mob_life(var/mob/living/M as mob, var/alien)
				if(M.stat == 2.0)
					return
				if(!M) M = holder.my_atom
				if(alien != IS_DIONA)
					M.heal_organ_damage(2*REM,0)
				..()
				return

		//Also replaces Bicardine
		//Fix effects - balance heal dmg with other bruteheal chems
		aluminum_sulfate
			name = "Aluminum Sulfate"
			id = "aluminum_sulfate"
			description = "A double sulfate salt, and an effective antihemmorhagic agent."
			reagent_state = LIQUID
			color = "#BF0000"
			overdose = REAGENTS_OVERDOSE
			scannable = 1

			on_mob_life(var/mob/living/M as mob, var/alien)
				if(M.stat == 2.0)
					return
				if(!M) M = holder.my_atom
				if(alien != IS_DIONA)
					M.heal_organ_damage(2*REM,0)
				..()
				return

		//Our first secret chem!!
		//Fix effects - balance heal dmg with other bruteheal chems
		chitosan
			name = "Chitosan"
			id = "chitosan"
			description = "De-acetylated chitin. Has a variety of applications, including medicine and agriculture."
			reagent_state = LIQUID
			color = "#BF0000"
			overdose = REAGENTS_OVERDOSE
			scannable = 1
			secret = 1

			on_mob_life(var/mob/living/M as mob, var/alien)
				if(M.stat == 2.0)
					return
				if(!M) M = holder.my_atom
				if(alien != IS_DIONA)
					M.heal_organ_damage(2*REM,0)
				..()
				return

		//fix - balance w/ burnheal chems
		kelotane
			name = "Kelotane"
			id = "kelotane"
			description = "Kelotane is a drug used to treat burns."
			reagent_state = LIQUID
			color = "#FFA800" // rgb: 200, 165, 220
			overdose = REAGENTS_OVERDOSE
			scannable = 1

			on_mob_life(var/mob/living/M as mob)
				if(M.stat == 2.0)
					return
				if(!M) M = holder.my_atom
				//This needs a diona check but if one is added they won't be able to heal burn damage at all.
				M.heal_organ_damage(0,2*REM)
				..()
				return

		//Replaces dermaline
		//fix - balance w/ burnheal chems
		silvadene
			name = "Silvadene"
			id = "silvadene"
			description = "Chemical used for treating severe burns."
			reagent_state = LIQUID
			color = "#FF8000"
			overdose = REAGENTS_OVERDOSE
			scannable = 1

			on_mob_life(var/mob/living/M as mob, var/alien)
				if(M.stat == 2.0)
					return
				if(!M) M = holder.my_atom
				if(!alien || alien != IS_DIONA)
					M.heal_organ_damage(0,3*REM)
				..()
				return

		//Fix - balance w/ oxyloss chems
		salbutamol
			name = "Salbutamol"
			id = "salbutamol"
			description = "Prevents spasming of the bronchioles in the lungs. Used to aid in breathing."
			reagent_state = LIQUID
			color = "#C8A5DC"
			overdose = REAGENTS_OVERDOSE

			on_mob_life(var/mob/living/M as mob, var/alien)
				if(M.stat == 2.0)
					return
				if(!M) M = holder.my_atom
				if(alien && alien == IS_VOX)
					M.adjustToxLoss(2*REM)
				else if(!alien || alien != IS_DIONA)
					M.adjustOxyLoss(-2*REM)

				holder.remove_reagent("lexorin", 2*REM)
				..()
				return

		//Secret chem!!
		//Fix - balance w/ oxyloss chems
		oxy_suspension
			name = "Lipid-Oxygen Suspension"
			id = "oxy_suspension"
			description = "Suspension of oxygen in lipid-bilayers. Used to quickly oxygenate blood in emergencies."
			reagent_state = LIQUID
			color = "#0080FF"
			overdose = REAGENTS_OVERDOSE
			scannable = 1
			secret = 1

			on_mob_life(var/mob/living/M as mob, var/alien)
				if(M.stat == 2.0)
					return
				if(!M) M = holder.my_atom

				if(alien && alien == IS_VOX)
					M.adjustOxyLoss()
				else if(!alien || alien != IS_DIONA)
					M.adjustOxyLoss(-M.getOxyLoss())

				holder.remove_reagent("lexorin", 2*REM)
				..()
				return

		tricordrazine
			name = "Tricordrazine"
			id = "tricordrazine"
			description = "Tricordrazine is a highly potent stimulant, originally derived from cordrazine. Can be used to treat a wide range of injuries."
			reagent_state = LIQUID
			color = "#8040FF" // rgb: 200, 165, 220
			scannable = 1

			on_mob_life(var/mob/living/M as mob, var/alien)
				if(M.stat == 2.0)
					return
				if(!M) M = holder.my_atom
				if(!alien || alien != IS_DIONA)
					if(M.getOxyLoss()) M.adjustOxyLoss(-1*REM)
					if(M.getBruteLoss() && prob(80)) M.heal_organ_damage(1*REM,0)
					if(M.getFireLoss() && prob(80)) M.heal_organ_damage(0,1*REM)
					if(M.getToxLoss() && prob(80)) M.adjustToxLoss(-1*REM)
				..()
				return

		//Replaces antitox
		//BALANCE
		active_charcoal
			name = "Activated Charcoal"
			id = "active_charcoal"
			description = "A simple, general anti-toxin. Works by binding to harmful chemicals."
			reagent_state = LIQUID
			color = "#00A000" // rgb: 200, 165, 220
			scannable = 1

			on_mob_life(var/mob/living/M as mob, var/alien)
				if(!M) M = holder.my_atom
				if(!alien || alien != IS_DIONA)
					M.reagents.remove_all_type(/datum/reagent/toxin, 1*REM, 0, 1)
					M.drowsyness = max(M.drowsyness-2*REM, 0)
					M.hallucination = max(0, M.hallucination - 5*REM)
					M.adjustToxLoss(-2*REM)
				..()
				return

		paracetamol //See shock.dm - Same for all other painkillers
			name = "Paracetamol"
			id = "paracetamol"
			description = "Most probably know this as Tylenol, but this chemical is a mild, simple painkiller."
			reagent_state = LIQUID
			color = "#C8A5DC"
			overdose = 60
			scannable = 1
			custom_metabolism = 0.025 // Lasts 10 minutes for 15 units

			on_mob_life(var/mob/living/M as mob)
				if (volume > overdose)
					M.hallucination = max(M.hallucination, 2)
				..()
				return

		//Replaces tramadol
		//BALANCE
		codeine
			name = "Codeine"
			id = "codeine"
			description = "A simple, yet effective painkiller."
			reagent_state = LIQUID
			color = "#CB68FC"
			overdose = 30
			scannable = 1
			custom_metabolism = 0.025 // Lasts 10 minutes for 15 units

			on_mob_life(var/mob/living/M as mob)
				if (volume > overdose)
					M.hallucination = max(M.hallucination, 2)
				..()
				return

		//Replaces Oxycodone
		//BALANCE
		morphine
			name = "Morphine"
			id = "morphine"
			description = "An effective and very addictive painkiller."
			reagent_state = LIQUID
			color = "#800080"
			overdose = 20
			custom_metabolism = 0.25 // Lasts 10 minutes for 15 units

			on_mob_life(var/mob/living/M as mob)
				if (volume > overdose)
					M.druggy = max(M.druggy, 10)
					M.hallucination = max(M.hallucination, 3)
				..()
				return

		synaptizine
			name = "Synaptizine"
			id = "synaptizine"
			description = "Synaptizine is used to treat various diseases."
			reagent_state = LIQUID
			color = "#99CCFF" // rgb: 200, 165, 220
			custom_metabolism = 0.01
			overdose = REAGENTS_OVERDOSE
			scannable = 1

			on_mob_life(var/mob/living/M as mob)
				if(!M) M = holder.my_atom
				M.drowsyness = max(M.drowsyness-5, 0)
				M.AdjustParalysis(-1)
				M.AdjustStunned(-1)
				M.AdjustWeakened(-1)
				holder.remove_reagent("mindbreaker", 5)
				M.hallucination = max(0, M.hallucination - 10)
				if(prob(60))	M.adjustToxLoss(1)
				..()
				return

		//Replaces impedrezine
		//BALANCE
		dimethyl_mercury
			name = "Dimethyl Mercury"
			id = "dimethyl_mercury"
			description = "A highly toxic intermediate. Very destructive to the neural pathways."
			reagent_state = LIQUID
			color = "#C8A5DC" // rgb: 200, 165, 220
			overdose = REAGENTS_OVERDOSE

			on_mob_life(var/mob/living/M as mob)
				if(!M) M = holder.my_atom
				M.jitteriness = max(M.jitteriness-5,0)
				if(prob(80)) M.adjustBrainLoss(1*REM)
				if(prob(50)) M.drowsyness = max(M.drowsyness, 3)
				if(prob(10)) M.emote("drool")
				..()
				return

		//Replaces hyronalin
		//BALANCE
		potassium_iodide
			name = "Potassium Iodide"
			id = "potassium_iodide"
			description = "A common potassium salt. Often used to counter the effects of radiation poisoning."
			reagent_state = LIQUID
			color = "#408000" // rgb: 200, 165, 220
			custom_metabolism = 0.05
			overdose = REAGENTS_OVERDOSE
			scannable = 1

			on_mob_life(var/mob/living/M as mob)
				if(!M) M = holder.my_atom
				M.radiation = max(M.radiation-3*REM,0)
				..()
				return

		arithrazine
			name = "Arithrazine"
			id = "arithrazine"
			description = "Arithrazine is an unstable medication used for the most extreme cases of radiation poisoning."
			reagent_state = LIQUID
			color = "#008000" // rgb: 200, 165, 220
			custom_metabolism = 0.05
			overdose = REAGENTS_OVERDOSE

			on_mob_life(var/mob/living/M as mob)
				if(M.stat == 2.0)
					return  //See above, down and around. --Agouri
				if(!M) M = holder.my_atom
				M.radiation = max(M.radiation-7*REM,0)
				M.adjustToxLoss(-1*REM)
				if(prob(15))
					M.take_organ_damage(1, 0)
				..()
				return

		//Replaces alkysine
		//Fix - possible balance later
		mannitol
			name = "Mannitol"
			id = "mannitol"
			description = "An important sugar able to reduce swelling along the blood-brain barrier."
			color = "#C8A5DC"
			reagent_state = LIQUID
			custom_metabolism = 0.05
			overdose = REAGENTS_OVERDOSE
			scannable = 1

			on_mob_life(var/mob/living/M as mob)
				if(!M) M = holder.my_atom
				M.adjustBrainLoss(-3*REM)
				..()
				return

		//Poison - add heart dmg, eye dmg, twitch emotes, and weaken
		//BALANCE
		sorbitol
			name = "Sorbitol"
			id = "sorbitol"
			description = "An isomer of Mannitol. Often used as an intermediate for the alkane family of molecules. Can be poisonous"
			reagent_state = LIQUID
			overdose = REAGENTS_OVERDOSE
			scannable = 1

			on_mob_life(var/mob/living/M as mob)
				if(!M) M = holder.my_atom
				if(prob(10)) M.emote("drool")
				if(prob(25)) M.emote("twitch")
				if(ishuman(M))
					var/mob/living/carbon/human/H = M
					var/datum/organ/internal/eyes/E = H.internal_organs_by_name["eyes"]
					var/datum/organ/internal/heart/O = H.internal_organs_by_name["heart"]
					if(E && istype(E))
						if(prob(50))
							E.damage += 0.5
					if(O && istype(O))
						if(prob(30))
							O.damage += 0.5
				..()
				return

		imidazoline
			name = "Imidazoline"
			id = "imidazoline"
			description = "Heals eye damage"
			reagent_state = LIQUID
			color = "#C8A5DC" // rgb: 200, 165, 220
			overdose = REAGENTS_OVERDOSE
			scannable = 1

			on_mob_life(var/mob/living/M as mob)
				if(!M) M = holder.my_atom
				M.eye_blurry = max(M.eye_blurry-5 , 0)
				M.eye_blind = max(M.eye_blind-5 , 0)
				if(ishuman(M))
					var/mob/living/carbon/human/H = M
					var/datum/organ/internal/eyes/E = H.internal_organs_by_name["eyes"]
					if(E && istype(E))
						if(E.damage > 0)
							E.damage = max(E.damage - 1, 0)
				..()
				return

		peridaxon
			name = "Peridaxon"
			id = "peridaxon"
			description = "Used to encourage recovery of internal organs and nervous systems. Medicate cautiously."
			reagent_state = LIQUID
			color = "#561EC3" // rgb: 200, 165, 220
			overdose = 10
			scannable = 1

			on_mob_life(var/mob/living/M as mob)
				if(!M) M = holder.my_atom
				if(ishuman(M))
					var/mob/living/carbon/human/H = M

					//Peridaxon heals only non-robotic organs
					for(var/datum/organ/internal/I in H.internal_organs)
						if((I.damage > 0) && (I.robotic != 2))
							I.damage = max(I.damage - 0.20, 0)
				..()
				return

		//Replaces hyperzine
		//Fix - balance
		ephedrine
			name = "Ephedrine"
			id = "ephedrine"
			description = "A natural muscle stimulant found in the body."
			reagent_state = LIQUID
			color = "#FF3300" // rgb: 200, 165, 220
			custom_metabolism = 0.03
			overdose = REAGENTS_OVERDOSE/2

			on_mob_life(var/mob/living/M as mob)
				if(!M) M = holder.my_atom
				if(prob(5)) M.emote(pick("twitch","blink_r","shiver"))
				..()
				return

		//Replaces adrenaline
		epinepherine
			name = "Epinepherine"
			id = "epinepherine"
			description = "An organic and essential neurotransmitter. Aids in the body's 'Fight or Flight' response."
			reagent_state = LIQUID
			color = "#C8A5DC" // rgb: 200, 165, 220

			on_mob_life(var/mob/living/M as mob)
				if(!M) M = holder.my_atom
				M.SetParalysis(0)
				M.SetWeakened(0)
				M.adjustToxLoss(rand(3))
				..()
				return

		//Replaces sleep-toxin
		midazolam
			name = "Midazolam"
			id = "midazolam"
			description = "Common sedative. Often used as an anaesthetic, or in a lethal-injection cocktail."
			reagent_state = LIQUID
			color = "#009CA8"
			overdose = REAGENTS_OVERDOSE
			scannable = 1

			on_mob_life(var/mob/living/M as mob)
				if(!M) M = holder.my_atom
				if(!data) data = 1
				switch(data)
					if(1 to 12)
						if(prob(5))	M.emote("yawn")
					if(12 to 15)
						M.eye_blurry = max(M.eye_blurry, 10)
					if(15 to 49)
						if(prob(50))
							M.Weaken(2)
						M.drowsyness  = max(M.drowsyness, 20)
					if(50 to INFINITY)
						M.Weaken(20)
						M.drowsyness  = max(M.drowsyness, 30)
				data++
				..()
				return

		cryoxadone
			name = "Cryoxadone"
			id = "cryoxadone"
			description = "A chemical mixture with almost magical healing powers. Its main limitation is that the targets body temperature must be under 170K for it to metabolise correctly."
			reagent_state = LIQUID
			color = "#8080FF" // rgb: 200, 165, 220
			scannable = 1

			on_mob_life(var/mob/living/M as mob)
				if(!M) M = holder.my_atom
				if(M.bodytemperature < 170)
					M.adjustCloneLoss(-1)
					M.adjustOxyLoss(-1)
					M.heal_organ_damage(1,1)
					M.adjustToxLoss(-1)
				..()
				return

		clonexadone
			name = "Clonexadone"
			id = "clonexadone"
			description = "A liquid compound similar to that used in the cloning process. Can be used to 'finish' the cloning process when used in conjunction with a cryo tube."
			reagent_state = LIQUID
			color = "#80BFFF" // rgb: 200, 165, 220
			scannable = 1

			on_mob_life(var/mob/living/M as mob)
				if(!M) M = holder.my_atom
				if(M.bodytemperature < 170)
					M.adjustCloneLoss(-3)
					M.adjustOxyLoss(-3)
					M.heal_organ_damage(3,3)
					M.adjustToxLoss(-3)
				..()
				return

		rezadone
			name = "Rezadone"
			id = "rezadone"
			description = "A powder derived from fish toxin, this substance can effectively treat genetic damage in humanoids, though excessive consumption has side effects."
			reagent_state = SOLID
			color = "#669900" // rgb: 102, 153, 0
			overdose = REAGENTS_OVERDOSE
			scannable = 1

			on_mob_life(var/mob/living/M as mob)
				if(!M) M = holder.my_atom
				if(!data) data = 1
				data++
				switch(data)
					if(1 to 15)
						M.adjustCloneLoss(-1)
						M.heal_organ_damage(1,1)
					if(15 to 35)
						M.adjustCloneLoss(-2)
						M.heal_organ_damage(2,1)
						M.status_flags &= ~DISFIGURED
					if(35 to INFINITY)
						M.adjustToxLoss(1)
						M.make_dizzy(5)
						M.make_jittery(5)

				..()
				return

		spaceacillin
			name = "Spaceacillin"
			id = "spaceacillin"
			description = "An all-purpose antiviral agent."
			reagent_state = LIQUID
			color = "#C1C1C1" // rgb: 200, 165, 220
			custom_metabolism = 0.01
			overdose = REAGENTS_OVERDOSE
			scannable = 1

			on_mob_life(var/mob/living/M as mob)
				..()
				return

		ryetalyn
			name = "Ryetalyn"
			id = "ryetalyn"
			description = "Ryetalyn can cure all genetic abnomalities via a catalytic process."
			reagent_state = SOLID
			color = "#004000" // rgb: 200, 165, 220
			overdose = REAGENTS_OVERDOSE

			on_mob_life(var/mob/living/M as mob)
				if(!M) M = holder.my_atom

				var/needs_update = M.mutations.len > 0

				M.mutations = list()
				M.disabilities = 0
				M.sdisabilities = 0

				// Might need to update appearance for hulk etc.
				if(needs_update && ishuman(M))
					var/mob/living/carbon/human/H = M
					H.update_mutations()

				..()
				return

		thermite
			name = "Thermite"
			id = "thermite"
			description = "Thermite produces an aluminothermic reaction known as a thermite reaction. Can be used to melt walls."
			reagent_state = SOLID
			color = "#673910" // rgb: 103, 57, 16

			reaction_turf(var/turf/T, var/volume)
				src = null
				if(volume >= 5)
					if(istype(T, /turf/simulated/wall))
						var/turf/simulated/wall/W = T
						W.thermite = 1
						W.overlays += image('icons/effects/effects.dmi',icon_state = "#673910")
				return

			on_mob_life(var/mob/living/M as mob)
				if(!M) M = holder.my_atom
				M.adjustFireLoss(1)
				..()
				return


		thermate
			name = "Thermate"
			id = "thermate"
			description = "An enhanced, military-grade thermite. Can even melt floors."
			reagent_state = SOLID
			color = "#673910" // rgb: 103, 57, 16

			reaction_turf(var/turf/T, var/volume)
				src = null
				if(volume >= 2)
					if(istype(T, /turf/simulated/wall))
						var/turf/simulated/wall/W = T
						W.thermite = 1
						W.overlays += image('icons/effects/effects.dmi',icon_state = "#673910")
					if(istype(T, /turf/simulated/floor))
						var/turf/simulated/floor/F = T
						F.thermite = 1
						F.overlays += image('icons/effects/effects.dmi',icon_state = "#673910")
				return

			on_mob_life(var/mob/living/M as mob)
				if(!M) M = holder.my_atom
				M.adjustFireLoss(1)
				..()
				return

		virus_food
			name = "Virus Food"
			id = "virusfood"
			description = "A mixture of water, milk, and oxygen. Virus cells can use this mixture to reproduce."
			reagent_state = LIQUID
			nutriment_factor = 2 * REAGENTS_METABOLISM
			color = "#899613" // rgb: 137, 150, 19

			on_mob_life(var/mob/living/M as mob)
				if(!M) M = holder.my_atom
				M.nutrition += nutriment_factor*REM
				..()
				return

		//Replaces sterilizine
		saline
			name = "Saline Flush"
			id = "saline"
			description = "Sterilizes wounds in preparation for surgery."
			reagent_state = LIQUID
			color = "#C8A5DC" // rgb: 200, 165, 220

			//makes you squeaky clean
			reaction_mob(var/mob/living/M, var/method=TOUCH, var/volume)
				if (method == TOUCH)
					M.germ_level -= min(volume*20, M.germ_level)

			reaction_obj(var/obj/O, var/volume)
				O.germ_level -= min(volume*20, O.germ_level)

			reaction_turf(var/turf/T, var/volume)
				T.germ_level -= min(volume*20, T.germ_level)


		//Replaces fuel
		oxy_acetylene
			name = "Oxy Acetylene"
			id = "fuel"
			description = "Liquid mixture required for welders. Extremely flammable."
			reagent_state = LIQUID
			color = "#660000" // rgb: 102, 0, 0
			overdose = REAGENTS_OVERDOSE

			glass_icon_state = "dr_gibb_glass"
			glass_name = "glass of welder fuel"
			glass_desc = "Unless you are an industrial tool, this is probably not safe for consumption."

			reaction_obj(var/obj/O, var/volume)
				var/turf/the_turf = get_turf(O)
				if(!the_turf)
					return //No sense trying to start a fire if you don't have a turf to set on fire. --NEO
				new /obj/effect/decal/cleanable/liquid_fuel(the_turf, volume)
			reaction_turf(var/turf/T, var/volume)
				new /obj/effect/decal/cleanable/liquid_fuel(T, volume)
				return
			on_mob_life(var/mob/living/M as mob)
				if(!M) M = holder.my_atom
				M.adjustToxLoss(1)
				..()
				return

		space_cleaner
			name = "Space cleaner"
			id = "cleaner"
			description = "A compound used to clean things. Now with 50% more sodium hypochlorite!"
			reagent_state = LIQUID
			color = "#A5F0EE" // rgb: 165, 240, 238
			overdose = REAGENTS_OVERDOSE

			reaction_obj(var/obj/O, var/volume)
				if(istype(O,/obj/effect/decal/cleanable))
					del(O)
				else
					if(O)
						O.clean_blood()

			reaction_turf(var/turf/T, var/volume)
				if(volume >= 1)
					if(istype(T, /turf/simulated))
						var/turf/simulated/S = T
						S.dirt = 0
					T.clean_blood()
					for(var/obj/effect/decal/cleanable/C in T.contents)
						src.reaction_obj(C, volume)
						del(C)

					for(var/mob/living/carbon/slime/M in T)
						M.adjustToxLoss(rand(5,10))

			reaction_mob(var/mob/M, var/method=TOUCH, var/volume)
				if(iscarbon(M))
					var/mob/living/carbon/C = M
					if(C.r_hand)
						C.r_hand.clean_blood()
					if(C.l_hand)
						C.l_hand.clean_blood()
					if(C.wear_mask)
						if(C.wear_mask.clean_blood())
							C.update_inv_wear_mask(0)
					if(ishuman(M))
						var/mob/living/carbon/human/H = C
						if(H.head)
							if(H.head.clean_blood())
								H.update_inv_head(0)
						if(H.wear_suit)
							if(H.wear_suit.clean_blood())
								H.update_inv_wear_suit(0)
						else if(H.w_uniform)
							if(H.w_uniform.clean_blood())
								H.update_inv_w_uniform(0)
						if(H.shoes)
							if(H.shoes.clean_blood())
								H.update_inv_shoes(0)
						else
							H.clean_blood(1)
							return
					M.clean_blood()

		//Replaces leporazine
		orexin
			name = "Orexin-Z"
			id = "orexin"
			description = "A highly complex, synthetic protein. Used to regulate body temperature."
			reagent_state = LIQUID
			color = "#C8A5DC" // rgb: 200, 165, 220
			overdose = REAGENTS_OVERDOSE
			scannable = 1

			on_mob_life(var/mob/living/M as mob)
				if(!M) M = holder.my_atom
				if(M.bodytemperature > 310)
					M.bodytemperature = max(310, M.bodytemperature - (40 * TEMPERATURE_DAMAGE_COEFFICIENT))
				else if(M.bodytemperature < 311)
					M.bodytemperature = min(310, M.bodytemperature + (40 * TEMPERATURE_DAMAGE_COEFFICIENT))
				..()
				return

		cryptobiolin
			name = "Cryptobiolin"
			id = "cryptobiolin"
			description = "Cryptobiolin causes confusion and dizzyness."
			reagent_state = LIQUID
			color = "#000055" // rgb: 200, 165, 220
			overdose = REAGENTS_OVERDOSE

			on_mob_life(var/mob/living/M as mob)
				if(!M) M = holder.my_atom
				M.make_dizzy(1)
				if(!M.confused) M.confused = 1
				M.confused = max(M.confused, 20)
				holder.remove_reagent(src.id, 0.5 * REAGENTS_METABOLISM)
				..()
				return

		mutagen
			name = "Unstable mutagen"
			id = "mutagen"
			description = "Might cause unpredictable mutations. Keep away from children."
			reagent_state = LIQUID
			color = "#13BC5E" // rgb: 19, 188, 94

			reaction_mob(var/mob/living/carbon/M, var/method=TOUCH, var/volume)
				if(!..())	return
				if(!istype(M) || !M.dna)	return  //No robots, AIs, aliens, Ians or other mobs should be affected by this.
				src = null
				if((method==TOUCH && prob(33)) || method==INGEST)
					randmuti(M)
					if(prob(98))	randmutb(M)
					else			randmutg(M)
					domutcheck(M, null)
					M.UpdateAppearance()
				return
			on_mob_life(var/mob/living/carbon/M)
				if(!istype(M))	return
				if(!M) M = holder.my_atom
				M.apply_effect(10,IRRADIATE,0)
				..()
				return

		lexorin
			name = "Lexorin"
			id = "lexorin"
			description = "Lexorin temporarily stops respiration. Causes tissue damage."
			reagent_state = LIQUID
			color = "#C8A5DC" // rgb: 200, 165, 220
			overdose = REAGENTS_OVERDOSE

			on_mob_life(var/mob/living/M as mob)
				if(M.stat == 2.0)
					return
				if(!M) M = holder.my_atom
				if(prob(33))
					M.take_organ_damage(1*REM, 0)
				M.adjustOxyLoss(3)
				if(prob(20)) M.emote("gasp")
				..()
				return

		slimejelly
			name = "Slime Jelly"
			id = "slimejelly"
			description = "A gooey semi-liquid produced from one of the deadliest lifeforms in existence. SO REAL."
			reagent_state = LIQUID
			color = "#801E28" // rgb: 128, 30, 40

			on_mob_life(var/mob/living/M as mob)
				if(prob(10))
					M << "\red Your insides are burning!"
					M.adjustToxLoss(rand(20,60)*REM)
				else if(prob(40))
					M.heal_organ_damage(5*REM,0)
				..()
				return

		minttoxin
			name = "Mint Toxin"
			id = "minttoxin"
			description = "Useful for dealing with undesirable customers."
			reagent_state = LIQUID
			color = "#CF3600" // rgb: 207, 54, 0

			on_mob_life(var/mob/living/M as mob)
				if(!M) M = holder.my_atom
				if (FAT in M.mutations)
					M.gib()
				..()
				return

		potassium_chloride
			name = "Potassium Chloride"
			id = "potassium_chloride"
			description = "A delicious salt that stops the heart when injected into cardiac muscle."
			reagent_state = SOLID
			color = "#FFFFFF" // rgb: 255,255,255
			overdose = 30

			on_mob_life(var/mob/living/carbon/M as mob)
				var/mob/living/carbon/human/H = M
				if(H.stat != 1)
					if (volume >= overdose)
						if(H.losebreath >= 10)
							H.losebreath = max(10, H.losebreath-10)
						H.adjustOxyLoss(2)
						H.Weaken(10)
				..()
				return

/* Random shit that I'll probably reassign to a different catagory later. */

		nanites
			name = "Nanomachines"
			id = "nanites"
			description = "Microscopic construction robots."
			reagent_state = LIQUID
			color = "#535E66" // rgb: 83, 94, 102

			reaction_mob(var/mob/M, var/method=TOUCH, var/volume)
				src = null
				if( (prob(10) && method==TOUCH) || method==INGEST)
					M.contract_disease(new /datum/disease/robotic_transformation(0),1)

		xenomicrobes
			name = "Xenomicrobes"
			id = "xenomicrobes"
			description = "Microbes with an entirely alien cellular structure."
			reagent_state = LIQUID
			color = "#535E66" // rgb: 83, 94, 102

			reaction_mob(var/mob/M, var/method=TOUCH, var/volume)
				src = null
				if( (prob(10) && method==TOUCH) || method==INGEST)
					M.contract_disease(new /datum/disease/xeno_transformation(0),1)

		fluorosurfactant//foam precursor
			name = "Fluorosurfactant"
			id = "fluorosurfactant"
			description = "A perfluoronated sulfonic acid that forms a foam when mixed with water."
			reagent_state = LIQUID
			color = "#9E6B38" // rgb: 158, 107, 56

		foaming_agent// Metal foaming agent. This is lithium hydride. Add other recipes (e.g. LiH + H2O -> LiOH + H2) eventually.
			name = "Foaming agent"
			id = "foaming_agent"
			description = "A agent that yields metallic foam when mixed with light metal and a strong acid."
			reagent_state = SOLID
			color = "#664B63" // rgb: 102, 75, 99

		nicotine
			name = "Nicotine"
			id = "nicotine"
			description = "A highly addictive stimulant extracted from the tobacco plant."
			reagent_state = LIQUID
			color = "#181818" // rgb: 24, 24, 24

		ammonia
			name = "Ammonia"
			id = "ammonia"
			description = "A caustic substance commonly used in fertilizer or household cleaners."
			reagent_state = GAS
			color = "#404030" // rgb: 64, 64, 48

		ultraglue
			name = "Ultra Glue"
			id = "glue"
			description = "An extremely powerful bonding agent."
			color = "#FFFFCC" // rgb: 255, 255, 204

		diethylamine
			name = "Diethylamine"
			id = "diethylamine"
			description = "A secondary amine, mildly corrosive."
			reagent_state = LIQUID
			color = "#604030" // rgb: 96, 64, 48

		ethylredoxrazine	// FUCK YOU, ALCOHOL
			name = "Ethylredoxrazine"
			id = "ethylredoxrazine"
			description = "A powerful oxidizer that reacts with ethanol."
			reagent_state = SOLID
			color = "#605048" // rgb: 96, 80, 72
			overdose = REAGENTS_OVERDOSE

			on_mob_life(var/mob/living/M as mob)
				if(!M) M = holder.my_atom
				M.dizziness = 0
				M.drowsyness = 0
				M.stuttering = 0
				M.confused = 0
				M.reagents.remove_all_type(/datum/reagent/ethanol, 1*REM, 0, 1)
				..()
				return

/* TOXINS */

		toxin
			name = "Toxin"
			id = "toxin"
			description = "A toxic chemical."
			reagent_state = LIQUID
			color = "#CF3600" // rgb: 207, 54, 0
			var/toxpwr = 0.7 // Toxins are really weak, but without being treated, last very long.
			custom_metabolism = 0.1

			on_mob_life(var/mob/living/M as mob,var/alien)
				if(!M) M = holder.my_atom
				if(toxpwr)
					M.adjustToxLoss(toxpwr*REM)
				if(alien) ..() // Kind of a catch-all for aliens without the liver. Because this does not metabolize 'naturally', only removed by the liver.
				return

		toxin/amatoxin
			name = "Amatoxin"
			id = "amatoxin"
			description = "A powerful poison derived from certain species of mushroom."
			reagent_state = LIQUID
			color = "#792300" // rgb: 121, 35, 0
			toxpwr = 1

		toxin/phoron
			name = "Phoron"
			id = "phoron"
			description = "Phoron in its liquid form."
			reagent_state = LIQUID
			color = "#9D14DB"
			toxpwr = 3

			on_mob_life(var/mob/living/M as mob)
				if(!M) M = holder.my_atom
				holder.remove_reagent("inaprovaline", 2*REM)
				..()
				return
			reaction_obj(var/obj/O, var/volume)
				src = null
				/*if(istype(O,/obj/item/weapon/reagent_containers/food/snacks/egg/slime))
					var/obj/item/weapon/reagent_containers/food/snacks/egg/slime/egg = O
					if (egg.grown)
						egg.Hatch()*/
				if((!O) || (!volume))	return 0
				var/turf/the_turf = get_turf(O)
				the_turf.assume_gas("volatile_fuel", volume, T20C)
			reaction_turf(var/turf/T, var/volume)
				src = null
				T.assume_gas("volatile_fuel", volume, T20C)
				return

		toxin/cyanide //Fast and Lethal
			name = "Cyanide"
			id = "cyanide"
			description = "A highly toxic chemical."
			reagent_state = LIQUID
			color = "#CF3600" // rgb: 207, 54, 0
			toxpwr = 4
			custom_metabolism = 0.4

			on_mob_life(var/mob/living/M as mob)
				if(!M) M = holder.my_atom
				M.adjustOxyLoss(4*REM)
				M.sleeping += 1
				..()
				return

		toxin/carpotoxin
			name = "Carpotoxin"
			id = "carpotoxin"
			description = "A deadly neurotoxin produced by the dreaded space carp."
			reagent_state = LIQUID
			color = "#003333" // rgb: 0, 51, 51
			toxpwr = 2

		toxin/zombiepowder
			name = "Zombie Powder"
			id = "zombiepowder"
			description = "A strong neurotoxin that puts the subject into a death-like state."
			reagent_state = SOLID
			color = "#669900" // rgb: 102, 153, 0
			toxpwr = 0.5

			on_mob_life(var/mob/living/carbon/M as mob)
				if(!M) M = holder.my_atom
				M.status_flags |= FAKEDEATH
				M.adjustOxyLoss(0.5*REM)
				M.Weaken(10)
				M.silent = max(M.silent, 10)
				M.tod = worldtime2text()
				..()
				return

			Del()
				if(holder && ismob(holder.my_atom))
					var/mob/M = holder.my_atom
					M.status_flags &= ~FAKEDEATH
				..()

		//Reagents used for plant fertilizers.
		toxin/fertilizer
			name = "fertilizer"
			id = "fertilizer"
			description = "A chemical mix good for growing plants with."
			reagent_state = LIQUID
			toxpwr = 0.2 //It's not THAT poisonous.
			color = "#664330" // rgb: 102, 67, 48

		toxin/fertilizer/eznutrient
			name = "EZ Nutrient"
			id = "eznutrient"

		toxin/fertilizer/left4zed
			name = "Left-4-Zed"
			id = "left4zed"

		toxin/fertilizer/robustharvest
			name = "Robust Harvest"
			id = "robustharvest"

		toxin/plantbgone
			name = "Plant-B-Gone"
			id = "plantbgone"
			description = "A harmful toxic mixture to kill plantlife. Do not ingest!"
			reagent_state = LIQUID
			color = "#49002E" // rgb: 73, 0, 46
			toxpwr = 1

			// Clear off wallrot fungi
			reaction_turf(var/turf/T, var/volume)
				if(istype(T, /turf/simulated/wall))
					var/turf/simulated/wall/W = T
					if(W.rotting)
						W.rotting = 0
						for(var/obj/effect/E in W) if(E.name == "Wallrot") del E

						for(var/mob/O in viewers(W, null))
							O.show_message(text("\blue The fungi are completely dissolved by the solution!"), 1)

			reaction_obj(var/obj/O, var/volume)
				if(istype(O,/obj/effect/alien/weeds/))
					var/obj/effect/alien/weeds/alien_weeds = O
					alien_weeds.health -= rand(15,35) // Kills alien weeds pretty fast
					alien_weeds.healthcheck()
				else if(istype(O,/obj/effect/glowshroom)) //even a small amount is enough to kill it
					del(O)
				else if(istype(O,/obj/effect/plantsegment))
					if(prob(50)) del(O) //Kills kudzu too.
				else if(istype(O,/obj/machinery/portable_atmospherics/hydroponics))
					var/obj/machinery/portable_atmospherics/hydroponics/tray = O

					if(tray.seed)
						tray.health -= rand(30,50)
						if(tray.pestlevel > 0)
							tray.pestlevel -= 2
						if(tray.weedlevel > 0)
							tray.weedlevel -= 3
						tray.toxins += 4
						tray.check_level_sanity()
						tray.update_icon()

			reaction_mob(var/mob/living/M, var/method=TOUCH, var/volume)
				src = null
				if(iscarbon(M))
					var/mob/living/carbon/C = M
					if(!C.wear_mask) // If not wearing a mask
						C.adjustToxLoss(2) // 4 toxic damage per application, doubled for some reason
					if(ishuman(M))
						var/mob/living/carbon/human/H = M
						if(H.dna)
							if(H.species.flags & IS_PLANT) //plantmen take a LOT of damage
								H.adjustToxLoss(50)

		toxin/chloralhydrate
			name = "Chloral Hydrate"
			id = "chloralhydrate"
			description = "A powerful sedative."
			reagent_state = SOLID
			color = "#000067" // rgb: 0, 0, 103
			toxpwr = 1
			custom_metabolism = 0.1 //Default 0.2
			overdose = 15
			overdose_dam = 5

			on_mob_life(var/mob/living/M as mob)
				if(!M) M = holder.my_atom
				if(!data) data = 1
				data++
				switch(data)
					if(1)
						M.confused += 2
						M.drowsyness += 2
					if(2 to 199)
						M.Weaken(30)
					if(200 to INFINITY)
						M.sleeping += 1
				..()
				return

		toxin/potassium_chlorophoride
			name = "Potassium Chlorophoride"
			id = "potassium_chlorophoride"
			description = "A specific chemical based on Potassium Chloride to stop the heart for surgery. Not safe to eat!"
			reagent_state = SOLID
			color = "#FFFFFF" // rgb: 255,255,255
			toxpwr = 2
			overdose = 20

			on_mob_life(var/mob/living/carbon/M as mob)
				if(ishuman(M))
					var/mob/living/carbon/human/H = M
					if(H.stat != 1)
						if(H.losebreath >= 10)
							H.losebreath = max(10, M.losebreath-10)
						H.adjustOxyLoss(2)
						H.Weaken(10)
				..()
				return

		toxin/beer2	//disguised as normal beer for use by emagged brobots
			name = "Beer"
			id = "beer2"
			description = "An alcoholic beverage made from malted grains, hops, yeast, and water. The fermentation appears to be incomplete." //If the players manage to analyze this, they deserve to know something is wrong.
			reagent_state = LIQUID
			color = "#664300" // rgb: 102, 67, 0
			custom_metabolism = 0.15 // Sleep toxins should always be consumed pretty fast
			overdose = REAGENTS_OVERDOSE/2

			glass_icon_state = "beerglass"
			glass_name = "glass of beer"
			glass_desc = "A freezing pint of beer"
			glass_center_of_mass = list("x"=16, "y"=8)

			on_mob_life(var/mob/living/M as mob)
				if(!M) M = holder.my_atom
				if(!data) data = 1
				switch(data)
					if(1)
						M.confused += 2
						M.drowsyness += 2
					if(2 to 50)
						M.sleeping += 1
					if(51 to INFINITY)
						M.sleeping += 1
						M.adjustToxLoss((data - 50)*REM)
				data++
				..()
				return

		toxin/acid
			name = "Sulphuric acid"
			id = "sacid"
			description = "A very corrosive mineral acid with the molecular formula H2SO4."
			reagent_state = LIQUID
			color = "#DB5008" // rgb: 219, 80, 8
			toxpwr = 1
			var/meltprob = 10

			on_mob_life(var/mob/living/M as mob)
				if(!M) M = holder.my_atom
				M.take_organ_damage(0, 1*REM)
				..()
				return

			reaction_mob(var/mob/living/M, var/method=TOUCH, var/volume)//magic numbers everywhere
				if(!istype(M, /mob/living))
					return
				if(method == TOUCH)
					if(ishuman(M))
						var/mob/living/carbon/human/H = M

						if(H.head)
							if(prob(meltprob) && !H.head.unacidable)
								H << "<span class='danger'>Your headgear melts away but protects you from the acid!</span>"
								del(H.head)
								H.update_inv_head(0)
								H.update_hair(0)
							else
								H << "<span class='warning'>Your headgear protects you from the acid.</span>"
							return

						if(H.wear_mask)
							if(prob(meltprob) && !H.wear_mask.unacidable)
								H << "<span class='danger'>Your mask melts away but protects you from the acid!</span>"
								del (H.wear_mask)
								H.update_inv_wear_mask(0)
								H.update_hair(0)
							else
								H << "<span class='warning'>Your mask protects you from the acid.</span>"
							return

						if(H.glasses) //Doesn't protect you from the acid but can melt anyways!
							if(prob(meltprob) && !H.glasses.unacidable)
								H << "<span class='danger'>Your glasses melts away!</span>"
								del (H.glasses)
								H.update_inv_glasses(0)

					else if(ismonkey(M))
						var/mob/living/carbon/monkey/MK = M
						if(MK.wear_mask)
							if(!MK.wear_mask.unacidable)
								MK << "<span class='danger'>Your mask melts away but protects you from the acid!</span>"
								del (MK.wear_mask)
								MK.update_inv_wear_mask(0)
							else
								MK << "<span class='warning'>Your mask protects you from the acid.</span>"
							return

					if(!M.unacidable)
						if(istype(M, /mob/living/carbon/human) && volume >= 10)
							var/mob/living/carbon/human/H = M
							var/datum/organ/external/affecting = H.get_organ("head")
							if(affecting)
								if(affecting.take_damage(4*toxpwr, 2*toxpwr))
									H.UpdateDamageIcon()
								if(prob(meltprob)) //Applies disfigurement
									if (!(H.species && (H.species.flags & NO_PAIN)))
										H.emote("scream")
									H.status_flags |= DISFIGURED
						else
							M.take_organ_damage(min(6*toxpwr, volume * toxpwr)) // uses min() and volume to make sure they aren't being sprayed in trace amounts (1 unit != insta rape) -- Doohl
				else
					if(!M.unacidable)
						M.take_organ_damage(min(6*toxpwr, volume * toxpwr))

			reaction_obj(var/obj/O, var/volume)
				if((istype(O,/obj/item) || istype(O,/obj/effect/glowshroom)) && prob(meltprob * 3))
					if(!O.unacidable)
						var/obj/effect/decal/cleanable/molten_item/I = new/obj/effect/decal/cleanable/molten_item(O.loc)
						I.desc = "Looks like this was \an [O] some time ago."
						for(var/mob/M in viewers(5, O))
							M << "\red \the [O] melts."
						del(O)

		toxin/acid/hacid
			name = "Hydrochloric acid"
			id = "hacid"
			description = "Hydrochloric acid is an extremely corrosive chemical substance."
			reagent_state = LIQUID
			color = "#8E18A9" // rgb: 142, 24, 169
			toxpwr = 2
			meltprob = 30