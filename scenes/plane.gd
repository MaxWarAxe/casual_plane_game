extends CharacterBody3D
class_name Aircraft

# СИ
# размеры в метрах
# масса в кг
# моменты в мг*м^2
# производные устойчивости в радианах
# тяга в kH
var MASS = 9100
var S = 27.8 # Площадь крыла
var b = 9.96 # размах крыла
var CAX = 3.45
var I_xx = 12875
var I_yy = 75674
var I_zz = 85552
var C_Z_a = -5.5
var C_m_a = 0.5
var C_m_q = -20
var C_m_b_e = -1.5
var max_F_engine = 130 #???? idk
signal destroyed
func _physics_process(_delta: float) -> void:
	velocity += Global.G * _delta
	move_and_slide()
	if get_last_slide_collision(): 
		destroyed.emit()
