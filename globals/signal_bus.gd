extends Node

#transition
signal next_scene(scene_path: String) # triggers changing of scene
signal on_transition_finished # will go to next scene after fade animations

# save game
signal save_game_done

#menu
signal exit_overlay

#phone
signal phone_in
signal phone_out

#act
signal act_num_scene_num_done(act: String, scene: String, nextScenePath: String)
