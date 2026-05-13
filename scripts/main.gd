extends Node

@export var pipe_scene : PackedScene
var life_icon_texture = preload("res://assets/bird1.png")
var game_running : bool
var game_over : bool
var scroll 
var score

# --- VARIABEL NYAWA BARU ---
var lives : int 
const MAX_LIVES : int = 3 # Jumlah nyawa awal (bebas kamu ubah)
var is_dying : bool = false # Untuk mencegah nyawa berkurang 2x saat kena pipa lalu jatuh
# ---------------------------

const SCROLL_SPEED : int = 4 
var screen_size : Vector2i 
var ground_height : int 
var pipes : Array
const PIPE_DELAY : int = 100
const PIPE_RANGE : int = 200

func _ready():
	screen_size = get_window().size
	ground_height = $Ground.get_node("Sprite2D").texture.get_height()
	$BGM.play()
	new_game()

func new_game():
	# Reset ulang semuanya (skor dan nyawa) saat awal main atau mati total
	lives = MAX_LIVES 
	update_lives_ui() 
	score = 0
	$Score.text = "SCORE : " + str(score)
	game_over = false
	$GameOver.hide()
	respawn() # Panggil setup posisi burung

# --- FUNGSI BARU UNTUK SETUP POSISI (Skor Tidak Direset) ---
func respawn():
	game_running = false
	is_dying = false
	scroll = 0
	$BGM.volume_db = 5
	# Bersihkan pipa lama dari layar
	for pipe in pipes:
		pipe.queue_free()
	pipes.clear()
	
	generate_pipes()
	$Bird.reset() 

func _input(event):
	# Tambahan pengecekan 'is_dying' agar saat mati tidak bisa lompat
	if game_over == false and is_dying == false: 
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				if game_running == false:
					start_game()
				else:
					if $Bird.flying:
						$Bird.flap()
						$JumpSound.play()
						check_top()

func start_game():
	game_running = true
	$Bird.flying = true
	$Bird.flap()
	$JumpSound.play()
	$PipeTimer.start()

func _process(delta):
	if game_running:
		scroll += SCROLL_SPEED
		if scroll >= screen_size.x:
			scroll = 0
		$Ground.position.x = -scroll
		for pipe in pipes:
			pipe.position.x -= SCROLL_SPEED
		$ParallaxBackground.scroll_offset.x -= 1
		$GroundParallax.scroll_offset.x -= SCROLL_SPEED
func _on_pipe_timer_timeout():
	generate_pipes()

func generate_pipes():
	var pipe = pipe_scene.instantiate()
	pipe.position.x = screen_size.x + PIPE_DELAY
	pipe.position.y = (screen_size.y - ground_height) / 2 + randi_range(-PIPE_RANGE, PIPE_RANGE)
	pipe.hit.connect(bird_hit)
	pipe.scored.connect(scored)
	add_child(pipe)
	pipes.append(pipe)
	
func scored():
	score += 1
	$Score.text = "SCORE : " + str(score)
	
func check_top():
	if $Bird.position.y < 0:
		$Bird.falling = true
		stop_game()
		
func stop_game():
	# Jika sedang proses mati, jangan eksekusi lagi (cegah nyawa minus dobel)
	if is_dying: 
		return
	is_dying = true 
	
	$PipeTimer.stop()
	$Bird.flying = false
	game_running = false
	$HitSound.play()
	$BGM.volume_db = -20
	# Kurangi nyawa
	lives -= 1
	update_lives_ui()
	
	if lives <= 0:
		game_over = true
		$GameOver.show() # Tampilkan tombol restart karena nyawa habis
		$BGM.stop()
	else:
		# Jika nyawa masih ada, tunggu 1.5 detik lalu hidupkan lagi
		await get_tree().create_timer(1.5).timeout
		respawn()
	
func bird_hit():
	$Bird.falling = true
	stop_game()

func _on_ground_hit():
	$Bird.falling = false
	stop_game()

func _on_game_over_restart():
	new_game()

# --- FUNGSI BARU UNTUK TEKS NYAWA ---
func update_lives_ui():
	if has_node("LivesContainer"):
		# 1. Bersihkan ikon nyawa yang ada di layar saat ini
		for child in $LivesContainer.get_children():
			child.queue_free()
			
		# 2. Munculkan ikon burung baru sebanyak sisa nyawa
		for i in range(lives):
			var icon = TextureRect.new()
			icon.texture = life_icon_texture
			
			# Mengatur agar ukuran burungnya pas (tidak kebesaran)
			icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			icon.custom_minimum_size = Vector2(40, 40) # Ubah angka 40 ini kalau ikonnya kurang besar/kecil
			
			$LivesContainer.add_child(icon)
	else:
		print("Sisa Nyawa: ", lives)
