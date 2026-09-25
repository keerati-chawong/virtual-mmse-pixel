extends Node
## เสียงเอฟเฟกต์ 8-bit สร้างด้วยโค้ด (ไม่มีไฟล์เสียงภายนอก)

const RATE := 22050
var sounds := {}
var players: Array[AudioStreamPlayer] = []
var enabled := true


func _ready() -> void:
	sounds.blip = _tone([[1320, 0.018]], 0.12, "square")
	sounds.blip2 = _tone([[880, 0.02]], 0.12, "square")
	sounds.click = _tone([[660, 0.03], [990, 0.03]], 0.2, "square")
	sounds.hover = _tone([[1500, 0.012]], 0.06, "square")
	sounds.open = _tone([[520, 0.04], [780, 0.04], [1040, 0.05]], 0.18, "square")
	sounds.ok = _tone([[523, 0.07], [659, 0.07], [784, 0.07], [1047, 0.14]], 0.2, "square")
	sounds.star = _tone([[988, 0.06], [1319, 0.12]], 0.2, "square")
	sounds.error = _tone([[220, 0.09], [180, 0.12]], 0.2, "square")
	sounds.stamp = _noise(0.09, 0.45, 60.0)
	sounds.step = _noise(0.03, 0.12, 40.0)
	sounds.whoosh = _noise(0.18, 0.12, 8.0)
	for i in 6:
		var p := AudioStreamPlayer.new()
		p.volume_db = -8.0
		add_child(p)
		players.append(p)


func play(name: String, pitch: float = 1.0) -> void:
	if not enabled or not sounds.has(name):
		return
	for p in players:
		if not p.playing:
			p.stream = sounds[name]
			p.pitch_scale = pitch
			p.play()
			return


func _tone(notes: Array, vol: float, wave: String) -> AudioStreamWAV:
	var data := PackedByteArray()
	for n in notes:
		var f: float = n[0]
		var d: float = n[1]
		var count := int(d * RATE)
		for i in count:
			var t := float(i) / RATE
			var env := 1.0 - float(i) / count
			var s := (1.0 if fmod(t * f, 1.0) < 0.5 else -1.0) if wave == "square" else sin(TAU * f * t)
			var v := int(clampf(s * vol * env, -1.0, 1.0) * 32767)
			data.append(v & 0xff)
			data.append((v >> 8) & 0xff)
	return _wav(data)


func _noise(d: float, vol: float, decay: float) -> AudioStreamWAV:
	var data := PackedByteArray()
	var count := int(d * RATE)
	var last := 0.0
	for i in count:
		var t := float(i) / RATE
		last = lerpf(last, randf_range(-1, 1), 0.35)
		var v := int(clampf(last * vol * exp(-t * decay), -1, 1) * 32767)
		data.append(v & 0xff)
		data.append((v >> 8) & 0xff)
	return _wav(data)


func _wav(data: PackedByteArray) -> AudioStreamWAV:
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = data
	return w
