/obj/item/weapon/storage/gilbo
	name = "\improper Gilbo"
	desc = "He who wields the Gilbo, wields the power of sphinctorial annihilation"
	icon = 'icons/obj/custom_items.dmi'
	icon_state = "gilbo"
	item_state = "gilbo"
	force = 10
	throwforce = 7
	throw_speed = 20
	throw_range = 8
	w_class = 4.0
	slot_flags = SLOT_BACK

	New()
		..()
		new /obj/item/stack/medical/ointment( src )
		new /obj/item/stack/medical/ointment( src )
		new /obj/item/stack/medical/ointment( src )
		new /obj/item/stack/medical/ointment( src )
		new /obj/item/stack/medical/ointment( src )
		new /obj/item/stack/medical/ointment( src )
		new /obj/item/stack/medical/ointment( src )

	attack(mob/living/M as mob, mob/living/user as mob)
		if (istype(user, /mob))
			if (user.client.holder)
				if (M != user)
					user.visible_message("\red With one mighty thrust [user] tears [M] in half!", "\red With one mighty thrust you tear [M] in half!")
					M << "\red You feel your anus tear with a sudden thrust of the mighty [src.name]!"
					M.gib()
					M.attack_log += "\[[time_stamp()]\]<font color='orange'> Gibbed by [src.name] last touched by ([src.fingerprintslast])</font>"
					log_attack("[src.name] has been used by ([src.fingerprintslast]) to gib [M.name] ([M.ckey])" )
					return
				if (M == user)
					user << "\red Your ass painfully widens as the [src.name] slides inside!"
					..()
					M.attack_log += "\[[time_stamp()]\]<font color='orange'> Fucked by [src.name] last touched by ([src.fingerprintslast])</font>"
					log_attack("[src.name] has been used by ([src.fingerprintslast]) to fuck [M.name] ([M.ckey])" )
					return
			if (!user.client.holder)
				if (M != user)
					user.visible_message("\red [user] whacks [M] with the [src.name]", "\red You whack [M] with the [src.name]!")
					M.visible_message("\red [M] winces in painful humiliation as they are slapped by the [src.name]", "\red You wince in painful humiliation as you are beaten with the mighty [src.name]!")
					..()
					M.attack_log += "\[[time_stamp()]\]<font color='orange'> Fucked by [src.name] last touched by ([src.fingerprintslast])</font>"
					log_attack("[src.name] has been used by ([src.fingerprintslast]) to fuck [M.name] ([M.ckey])" )
					return
				else
					user << "\red Your ass painfully widens as the [src.name] slides inside!"
					..()
					M.attack_log += "\[[time_stamp()]\]<font color='orange'> Fucked by [src.name] last touched by ([src.fingerprintslast])</font>"
					log_attack("[src.name] has been used by ([src.fingerprintslast]) to fuck [M.name] ([M.ckey])" )
					return
	throw_impact(atom/hit_atom)
		if(istype(hit_atom, /mob))
			var/mob/living/carbon/H = hit_atom
			for(var/mob/M in player_list) if(M.key == src.fingerprintslast)
				if (M.client.holder)
					H.gib()
					H.attack_log += "\[[time_stamp()]\]<font color='orange'> Gibbed by thrown [src.name] last touched by ([src.fingerprintslast])</font>"
					log_attack("[src.name] has been thrown by ([src.fingerprintslast]) to gib [H.name] ([H.ckey])" )
			else
				. = ..()
				H.attack_log += "\[[time_stamp()]\]<font color='orange'> Fucked by thrown [src.name] last touched by ([src.fingerprintslast])</font>"
				log_attack("[src.name] has been thrown by ([src.fingerprintslast]) to fuck [H.name] ([H.ckey])" )