//This is a beta game mode to test ways to implement an "infinite" traitor round in which more traitors are automatically added in as needed.
//Automatic traitor adding is complete pending the inevitable bug fixes.  Need to add a respawn system to let dead people respawn after 30 minutes or so.


/datum/game_mode/traitor/autotraitor
	name = "AutoTraitor"
	config_tag = "autotraitor"

	var/list/possible_traitors
	var/num_players = 0

/datum/game_mode/traitor/autotraitor/announce()
	..()
	world << "<B>Game mode is AutoTraitor. Traitors will be added to the round automagically as needed.<br>Expect bugs.</B>"

/datum/game_mode/traitor/autotraitor/pre_setup()
	if(istype(ticker.mode, /datum/game_mode/mixed))
		mixed = 1
	if(config.protect_roles_from_antagonist)
		restricted_jobs += protected_jobs

	possible_traitors = get_players_for_role(ROLE_TRAITOR)

	for(var/datum/mind/player in possible_traitors)
		for(var/job in restricted_jobs)
			if(player.assigned_role == job)
				possible_traitors -= player


	num_players = num_players()

	//var/r = rand(5)
	var/num_traitors = 1
	var/max_traitors = 1
	var/traitor_prob = 0
	max_traitors = round(num_players / 10) + 1
	traitor_prob = (num_players - (max_traitors - 1) * 10) * 10

	// Stop setup if no possible traitors
	if(!possible_traitors.len)
		return 0

	if(config.traitor_scaling)
		num_traitors = max_traitors - 1 + prob(traitor_prob)
		// mixed mode scaling
		if(mixed)
			num_traitors = min(3, num_traitors)
		log_game("Number of traitors: [num_traitors]")
		message_admins("Players counted: [num_players]  Number of traitors chosen: [num_traitors]")
	else
		num_traitors = max(1, min(num_players(), traitors_possible))


	for(var/i = 0, i < num_traitors, i++)
		var/datum/mind/traitor = pick(possible_traitors)
		if(traitor.special_role)
			possible_traitors.Remove(traitor)
			continue
		traitors += traitor
		possible_traitors.Remove(traitor)

	for(var/datum/mind/traitor in traitors)
		if(!traitor || !istype(traitor))
			traitors.Remove(traitor)
			continue
		if(istype(traitor))
			traitor.special_role = "traitor"

//	if(!traitors.len)
//		return 0
	return 1




/datum/game_mode/traitor/autotraitor/post_setup()
	..()
	abandon_allowed = 1
	traitorcheckloop()

/datum/game_mode/traitor/autotraitor/proc/traitorcheckloop()
	spawn(9000)
		if(emergency_shuttle.departed)
			return
		//message_admins("Performing AutoTraitor Check")
		var/playercount = 0
		var/traitorcount = 0
		var/possible_traitors[0]
		for(var/mob/living/player in mob_list)

			if (player.client && player.stat != 2)
				playercount += 1
			if (player.client && player.mind && player.mind.special_role && player.stat != 2)
				traitorcount += 1
			if (player.client && player.mind && !player.mind.special_role && player.stat != 2 && (player.client && player.client.desires_role(ROLE_TRAITOR)) && !jobban_isbanned(player, "Syndicate") && !isMoMMI(player))
				possible_traitors += player
		for(var/datum/mind/player in possible_traitors)
			for(var/job in restricted_jobs)
				if(player.assigned_role == job)
					possible_traitors -= player

		//message_admins("Live Players: [playercount]")
		//message_admins("Live Traitors: [traitorcount]")
//		message_admins("Potential Traitors:")
//		for(var/mob/living/traitorlist in possible_traitors)
//			message_admins("[traitorlist.real_name]")

//		var/r = rand(5)
//		var/target_traitors = 1
		var/max_traitors = 1
		var/traitor_prob = 0
		max_traitors = round(playercount / 10) + 1
		traitor_prob = (playercount - (max_traitors - 1) * 10) * 5
		if(traitorcount < max_traitors - 1)
			traitor_prob += 50


		if (traitorcount < max_traitors)
			//message_admins("Number of Traitors is below maximum.  Rolling for new Traitor.")
			//message_admins("The probability of a new traitor is [traitor_prob]%")

			if (prob(traitor_prob))
				message_admins("AUTOTRAITOR: making someone traitor")

				if (possible_traitors.len > 0)
					var/mob/living/traitor_body = pick(possible_traitors)

					if (traitor_body)
						var/datum/mind/traitor_mind = traitor_body.mind

						if (traitor_mind)
							log_game("[key_name(traitor_body)] has been auto traitor'ed.")
							message_admins("AUTOTRAITOR: making [key_name_admin(traitor_body)] a traitor")
							traitor_body << "<SPAN CLASS='danger'><CENTER><BIG>ATTENTION</BIG></CENTER></SPAN><BR><CENTER>It is time to pay your debt to the [syndicate_name()].</CENTER>"
							traitor_body = null
							traitors += traitor_mind
							traitor_mind.special_role = "traitor"
							forge_traitor_objectives(traitor_mind)
							finalize_traitor(traitor_mind)
							greet_traitor(traitor_mind)
				else
					message_admins("AUTOTRAITOR: no potential traitors, mission is kill")

			//else
				//message_admins("No new traitor being added.")
		//else
			//message_admins("Number of Traitors is at maximum.  Not making a new Traitor.")

		traitorcheckloop()

/datum/game_mode/traitor/autotraitor/latespawn(mob/living/carbon/human/character)
	..()
	if(emergency_shuttle.departed)
		return
	//message_admins("Late Join Check")
	if((character.client && character.client.desires_role(ROLE_TRAITOR)) && !jobban_isbanned(character, "Syndicate"))
		//message_admins("Late Joiner has Be Syndicate")
		//message_admins("Checking number of players")
		var/playercount = 0
		var/traitorcount = 0
		for(var/mob/living/player in mob_list)

			if (player.client && player.stat != 2)
				playercount += 1
			if (player.client && player.mind && player.mind.special_role && player.stat != 2)
				traitorcount += 1
		//message_admins("Live Players: [playercount]")
		//message_admins("Live Traitors: [traitorcount]")

		//var/r = rand(5)
		//var/target_traitors = 1
		var/max_traitors = 2
		var/traitor_prob = 0
		max_traitors = round(playercount / 10) + 1
		traitor_prob = (playercount - (max_traitors - 1) * 10) * 5
		if(traitorcount < max_traitors - 1)
			traitor_prob += 50

		//target_traitors = max(1, min(round((playercount + r) / 10, 1), traitors_possible))
		//message_admins("Target Traitor Count is: [target_traitors]")
		if (traitorcount < max_traitors)
			//message_admins("Number of Traitors is below maximum.  Rolling for New Arrival Traitor.")
			//message_admins("The probability of a new traitor is [traitor_prob]%")
			if(prob(traitor_prob))
				message_admins("New traitor roll passed.  Making a new Traitor.")
				forge_traitor_objectives(character.mind)
				equip_traitor(character)
				traitors += character.mind
				character << "<span class='warning'><B>You are the traitor.</B></span>"
				character.mind.special_role = "traitor"
				var/obj_count = 1
				character << "<span class='notice'>Your current objectives:</span>"
				for(var/datum/objective/objective in character.mind.objectives)
					character << "<B>Objective #[obj_count]</B>: [objective.explanation_text]"
					obj_count++
			//else
				//message_admins("New traitor roll failed.  No new traitor.")
	//else
		//message_admins("Late Joiner does not have Be Syndicate")


