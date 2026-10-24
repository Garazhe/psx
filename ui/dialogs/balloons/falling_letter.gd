
extends Control

@onready var label: Label = $Label

var fall_distance := 80.0
var fall_duration := 0.35
var bounce := true

func setup(char: String, font: Font, font_size: int, color: Color) -> void:
	label.text = char
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	
	# Начинаем выше
	position.y = -fall_distance
	modulate.a = 0.0
	
	# Анимация падения
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)   # красивый «подскок»
	
	tween.tween_property(self, "position:y", 0.0, fall_duration)
	tween.tween_property(self, "modulate:a", 1.0, fall_duration * 0.6)
	
	if bounce:
		tween.chain().tween_property(self, "position:y", -8.0, 0.12)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "position:y", 0.0, 0.15)\
			.set_trans(Tween.TRANS_BOUNCE)
