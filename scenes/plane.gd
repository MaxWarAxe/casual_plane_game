extends CharacterBody3D
class_name Aircraft

var inverted = true
@export var camera : Camera3D
@export var arm : SpringArm3D
var base_camera_rotation : Vector3 = Vector3.ZERO
# ПЕРЕМЕННЫЕ САМОЛЕТА
var pitch = 0.0   # Тангаж (в радианах)
var roll = 0.0# Крен (в радианах)
var yaw = 0.0 # Рыскание (в радианах)
var is_stalling := false
var spin_recovery := 0.0
var stall_angle := 0.3
var stall_speed := 50.0
var airflow_effectiveness := 1.0
var pitch_force = 0.0
var roll_force = 0.0
var yaw_force =  0.0

var pitch_speed = 0.0 # Угловая скорость по тангажу
var roll_speed = 0.0  # Угловая скорость по крену
var yaw_speed = 0.0   # Угловая скорость по рысканию

# КОНСТАНТЫ
var THRUST = 0.0
@export var THRUST_SPEED = 1.0
@export var MAX_THRUST = 200.0              # Базовая сила тяги двигателя
@export var LIFT_FACTOR = 5.0          # Множитель подъемной силы
@export var DRAG_FACTOR = 0.05         # Сопротивление воздуха (замедление)

var MAX_SPEED = 595.8
var thrust_vector : Vector3 = Vector3.ZERO
var lift_force : float = 0.0
var lift_vector : Vector3 = Vector3.ZERO
var total_force : Vector3 = Vector3.ZERO
var acceleration : Vector3 = Vector3.ZERO
var air_force : float = 1.0

var speed : float = 0.0
var drag_direction : Vector3 = Vector3.ZERO
var drag_force : Vector3 = Vector3.ZERO



# КОНСТАНТЫ (настройте их под нужное ощущение)
@export var MAX_ANGULAR_SPEED = 1.5# Макс. скорость вращения
@export var ANGULAR_ACCELERATION_PITCH = 2.5 # Скорость нарастания вращения
@export var ANGULAR_ACCELERATION_YAW = 1.0 # Скорость нарастания вращения
@export var ANGULAR_ACCELERATION_ROLL = 3.0 # Скорость нарастания вращения
@export var ANGULAR_DRAG = 0.95# "Сопротивление" для замедления вращения (0.9 - 0.99)

signal destroyed

var shoot_speed = 0.01
var shoot_spread = 0.0035
var bullet_speed = 100
func _ready():
	$ShootSpeedTimer.wait_time = shoot_speed
	base_camera_rotation = camera.rotation

func controls(_delta: float):
	
	# Ускорение
	if Input.is_action_pressed("gas"):
		THRUST = lerp(THRUST,MAX_THRUST,THRUST_SPEED*_delta)
		THRUST = clamp(THRUST,20.0,MAX_THRUST )
	else:
		THRUST = lerp(THRUST,20.0,air_force*_delta)
		
	# Повороты
	pitch_force = Input.get_action_strength("pitch") - Input.get_action_strength("down_pitch")
	roll_force = Input.get_action_strength("right_roll") - Input.get_action_strength("left_roll")
	yaw_force = Input.get_action_strength("yaw_right") - Input.get_action_strength("yaw_left")

	# Стрельба
	if Input.is_action_pressed("shoot") and $ShootSpeedTimer.is_stopped():
		$ShootSpeedTimer.start()
		shoot()
var rotation_quat := Quaternion.IDENTITY

func shoot():
	for barrel : Marker3D in $Node.get_children():
		var bullet = load("res://bullet.tscn").instantiate()
		bullet.velocity = (barrel.get_child(0).global_position - barrel.global_position).normalized() * bullet_speed
		print(barrel.global_rotation)
		bullet.global_position = barrel.global_position
		get_tree().get_root().add_child(bullet)
		
		

func apply_controls(_delta: float):
	if inverted:
		pitch_force = -pitch_force
	
	# РАСЧЕТ ИНТЕНСИВНОСТИ ПОВОРОТА (добавлено)
	var turn_intensity = (abs(roll_force) + abs(yaw_force)) * 0.5
	turn_intensity = clamp(turn_intensity, 0, 1)
	
	# АВТОМАТИЧЕСКИЙ ТАНГАЖ В ВИРАЖЕ (добавлено)
	var auto_pitch = -roll_speed * 0.3 * turn_intensity
	pitch_speed += auto_pitch * _delta
	
	pitch_speed += pitch_force * ANGULAR_ACCELERATION_PITCH * _delta
	roll_speed += roll_force * ANGULAR_ACCELERATION_ROLL * _delta
	yaw_speed += yaw_force * ANGULAR_ACCELERATION_YAW * _delta

	# Ограничение скорости
	pitch_speed = clamp(pitch_speed, -MAX_ANGULAR_SPEED, MAX_ANGULAR_SPEED)
	roll_speed = clamp(roll_speed, -MAX_ANGULAR_SPEED, MAX_ANGULAR_SPEED)
	yaw_speed = clamp(yaw_speed, -MAX_ANGULAR_SPEED, MAX_ANGULAR_SPEED)
	
	# Угловое сопротивление
	pitch_speed *= ANGULAR_DRAG
	roll_speed *= ANGULAR_DRAG
	yaw_speed *= ANGULAR_DRAG
	
	# Обновление вращения через кватернионы
	var rotation_delta = Basis.from_euler(Vector3(roll_speed * _delta,yaw_speed * _delta, pitch_speed * _delta))
	rotation_quat = rotation_quat * Quaternion(rotation_delta).normalized()

func local_velocity():
	return (velocity * basis)

func apply_force(_delta: float):
	var local_forward := Vector3(1, 0, 0)
	var basis := Basis(rotation_quat)
	
	var world_forward := basis * local_forward
	
	# РАСЧЕТ ДОПОЛНИТЕЛЬНОЙ ТЯГИ В ПОВОРОТЕ (добавлено)
	var turn_intensity = (abs(roll_speed) + abs(yaw_speed)) / (MAX_ANGULAR_SPEED * 2)
	turn_intensity = clamp(turn_intensity, 0, 1)
	var turn_boost = 1.0 + turn_intensity * 1  # +50% тяги в крутом вираже
	
	thrust_vector = world_forward * THRUST * turn_boost
	
	# УЛУЧШЕННЫЙ РАСЧЕТ ПОДЪЕМНОЙ СИЛЫ (модифицировано)
	var base_lift = LIFT_FACTOR * basis.y.dot(Vector3.UP)
	var turn_lift = turn_intensity * LIFT_FACTOR * 0.7  # Дополнительная подъемная сила в вираже
	lift_force = base_lift + turn_lift
	
	lift_vector = Vector3(0, lift_force, 0)
	total_force = thrust_vector + lift_vector + Global.G
	acceleration = total_force
	velocity += acceleration * _delta
	speed = velocity.length()
	if speed > 0:
		drag_direction = -velocity.normalized()
		drag_force = drag_direction * (speed * speed * DRAG_FACTOR)
		velocity += drag_force * _delta
		
	# Для совместимости сохраняем углы Эйлера
	rotation = basis.get_euler()

func camera_interaction():
	camera.fov = clamp(80 + local_velocity().x,80,150)
	camera.rotation = base_camera_rotation + Vector3(pitch_speed,yaw_speed,-roll_speed)/2.0
func _process(_delta: float) -> void:
	controls(_delta)
	camera_interaction()
	
	
func _physics_process(_delta: float) -> void:
	apply_controls(_delta)
	apply_force(_delta)
	var collide = move_and_collide(velocity * _delta)
	if collide: 
		destroyed.emit()
	
