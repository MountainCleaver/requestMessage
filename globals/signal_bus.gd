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

#act
signal act_num_scene_num_done(act: String, scene: String, nextScenePath: String)
signal habulan_done

#jeepney
signal in_jeep_area
signal out_jeep_area

#npc
signal in_npc(npc_name: String)
signal out_npc(npc_name: String)
