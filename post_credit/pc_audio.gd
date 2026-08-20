## PCAudio — Procedural audio generator for post-credit sequence.
##
## Synthesizes beeps, clicks, electrical hums, and construction sounds.
## Prevents dependencies on external WAV/Ogg files.
##
extends Node


func play_sound(type: String) -> void:
	var player := AudioStreamPlayer.new()
	add_child(player)
	
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.stereo = false
	
	var sample_rate := 44100
	stream.mix_rate = sample_rate
	
	var data := PackedByteArray()
	var duration := 0.2
	var frequency := 440.0
	
	if type == "click":
		duration = 0.05
		frequency = 880.0
		for i in range(int(sample_rate * duration)):
			var t := float(i) / sample_rate
			var sample := sin(2.0 * PI * frequency * t) * exp(-100.0 * t)
			var val := int(sample * 32767)
			data.append(val & 0xFF)
			data.append((val >> 8) & 0xFF)
			
	elif type == "success":
		duration = 0.5
		# Hopeful major chord progression
		for i in range(int(sample_rate * duration)):
			var t := float(i) / sample_rate
			var f := frequency
			if t > 0.15: f = 554.37 # C#5
			if t > 0.3: f = 659.25 # E5
			var sample := sin(2.0 * PI * f * t) * exp(-4.0 * t)
			var val := int(sample * 16384)
			data.append(val & 0xFF)
			data.append((val >> 8) & 0xFF)
			
	elif type == "electric":
		duration = 0.6
		# Low 60Hz hum + buzz
		for i in range(int(sample_rate * duration)):
			var t := float(i) / sample_rate
			var sample := (sin(2.0 * PI * 60.0 * t) + 0.3 * sin(2.0 * PI * 180.0 * t) + 0.15 * (randf() * 2.0 - 1.0)) * exp(-3.0 * t)
			var val := int(sample * 24000)
			data.append(val & 0xFF)
			data.append((val >> 8) & 0xFF)
			
	elif type == "clink":
		duration = 0.3
		# High frequency click + noise burst
		for i in range(int(sample_rate * duration)):
			var t := float(i) / sample_rate
			var sample := (sin(2.0 * PI * 2000.0 * t) + 0.5 * (randf() * 2.0 - 1.0)) * exp(-35.0 * t)
			var val := int(sample * 16384)
			data.append(val & 0xFF)
			data.append((val >> 8) & 0xFF)
			
	elif type == "servo":
		duration = 0.4
		# Sweep frequency (like a small motor)
		for i in range(int(sample_rate * duration)):
			var t := float(i) / sample_rate
			var f := 300.0 + (t * 600.0)
			var sample := sin(2.0 * PI * f * t) * 0.1
			var val := int(sample * 16384)
			data.append(val & 0xFF)
			data.append((val >> 8) & 0xFF)
			
	stream.data = data
	player.stream = stream
	player.play()
	player.finished.connect(func(): player.queue_free())
