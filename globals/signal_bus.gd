extends Node

#transition
signal next_scene(scene_path: String) # triggers changing of scene
signal on_transition_finished # will go to next scene after fade animations
signal on_white_transition_finished

# save game
signal save_game_done

#menu
signal exit_overlay

#phone
signal phone_in
signal phone_out
signal sched_opened
signal app_chat_opened
signal chat_opened(chat_name: String)
signal chat_message_sent(chat_name: String)
signal chat_message_received(chat_name: String, sender: String, text: String)
signal chat_closed(chat_name)
signal show_locked_label() 
signal type_message_clicked(chat_name)
signal call_done
signal player_answered_call
signal player_rejected_call  

var unknown_sender_unlocked: bool = false
var optional_chats_locked: bool = false
var unknown_sender_label_visible: bool = false #yung may nakalagay na "message request" sa top niya

# game state
signal save_game_state
signal load_game_state

#act
signal act_num_scene_num_done(act: String, scene: String, nextScenePath: String)
signal habulan_done

#jeepney
signal in_jeep_area
signal out_jeep_area

#npc
signal in_npc(npc_name: String)
signal out_npc(npc_name: String)

signal call_opened(call_name: String)
signal call_completed(call_name: String)

#square breathing
signal mini_game_done

#gamot
signal bought_meds_done
var bought_meds : bool = false
signal area_one_entered
signal sat_on_bed
signal second_house_exit

#dream
signal dream_done

signal start_theresa
signal start_vanesa
signal knocked_jonathan
signal start_jonathan
signal jonathan_done
signal asked_a_neighbor
var asked_neighbors_done : bool = false
signal fade_to_blackness
signal remove_npc(npc: String)
signal last_words
