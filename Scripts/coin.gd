extends MeshInstance3D

signal collected
# Coin class that floats up and down and can be collected by the player
@onready var coin_sound = $CoinSound

func _ready() -> void:
	float_up()
	
func float_up():
	var tween = create_tween()
	tween.tween_property(self, "position" , position + Vector3(0,0.5,0), 1).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(float_down)
	
func float_down():
	var tween = create_tween()
	tween.tween_property(self, "position" ,  position - Vector3(0,0.5,0), 1).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(float_up)
	
func _on_Coin_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		# add a tween to animate the coin disappearing
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector3.ZERO, 0.5)
		tween.tween_callback(queue_free)
		
		coin_sound.pitch_scale =  randf_range(0.6, 1.4)
		coin_sound.play()
		
		emit_signal("collected")
		
		print("Collected a coin ...")
