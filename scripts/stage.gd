class_name Stage
extends Control
## ฉาก pixel art 320×180 (SubViewport) ขยายเต็มพื้นที่ + ชั้นทับสำหรับข้อความไทยและจุดกดในฉาก
## kind: "room" = ห้องผู้ป่วย · "corridor" = ทางเดินหน้าห้องตรวจ

const W := 320
const H := 180
const NURSE_HOME := Vector2(112, 96)
const NURSE_NEAR := Vector2(146, 96)
const PATIENT_POS := Vector2(200, 99)

var kind := "room"
var cover := true            # true = ขยายเต็มกรอบ (ตัดขอบ) · false = เห็นทั้งภาพ
var vp: SubViewport
var world: Node2D
var view: TextureRect
var overlay: Control
var nurse: Sprite2D
var patient: Sprite2D
var props := {}
var labels := {}
var hotspots := {}
var flag: PanelContainer
var flag_text: Label
var think: Sprite2D
var talk_icon: Sprite2D
var nurse_pose := "idle"
var pt_arms := "rest"
var pt_eyes := "open"
var _talk_tw: Tween
var _blink_t := 0.0
var _nurse_blink := false


func _init(k: String = "room", cover_: bool = true) -> void:
	kind = k
	cover = cover_
	clip_contents = true


func _ready() -> void:
	vp = SubViewport.new()
	vp.size = Vector2i(W, H)
	vp.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	world = Node2D.new()
	vp.add_child(world)

	view = TextureRect.new()
	view.texture = vp.get_texture()
	view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED if cover else TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	view.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	view.set_anchors_preset(Control.PRESET_FULL_RECT)
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(view)

	overlay = Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)

	var bg := Sprite2D.new()
	bg.centered = false
	bg.texture = Px.cached("bg_" + kind, func(): return Art.room() if kind == "room" else Art.corridor())
	world.add_child(bg)

	if kind == "room":
		var rain := preload("res://scripts/rain.gd").new()
		rain.area = Rect2(236, 16, 68, 44)
		world.add_child(rain)
		patient = _char(Px.patient(G.scn().sex), PATIENT_POS, 24)
		props.table = _sprite(Px.cached("table", func(): return Art.table()), Vector2(200, 122))
		props.table.visible = false
		nurse = _char(Px.nurse("clip"), NURSE_HOME, 31)
		nurse_pose = "clip"
		think = _sprite(Px.think_bubble(), Vector2(224, 66))
		think.visible = false
		for k in ["paper", "card", "pencil", "watch", "write", "penta"]:
			var t: Texture2D
			match k:
				"paper": t = Px.paper("flat")
				"card": t = Px.paper("card")
				"pencil": t = Px.pencil()
				"watch": t = Px.watch()
				"write": t = Px.paper("write")
				"penta": t = Px.paper("penta")
			props[k] = _sprite(t, Vector2.ZERO)
			props[k].visible = false
	else:
		props.door = _sprite(Px.cached("door_panel", func(): return Art.door_panel()), Vector2(263, 61))
		nurse = _char(Px.nurse("tray"), Vector2(80, 96), 31)
		nurse_pose = "tray"
	talk_icon = _sprite(Px.talk_icon(), Vector2.ZERO)
	talk_icon.visible = false
	var vig := Sprite2D.new()
	vig.centered = false
	vig.texture = Px.cached("vignette", func(): return Art.vignette())
	world.add_child(vig)

	_build_overlay_ui()
	resized.connect(_relayout)
	_relayout.call_deferred()


func _sprite(t: Texture2D, pos: Vector2) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = t
	s.position = pos
	world.add_child(s)
	return s

## ตัวละคร = สไปรต์ + เงาใต้เท้า + หายใจขยับขึ้นลงเบา ๆ
func _char(t: Texture2D, pos: Vector2, feet: int) -> Sprite2D:
	var s := _sprite(t, pos)
	var sh := Sprite2D.new()
	sh.texture = Px.shadow()
	sh.position = Vector2(0, feet)
	sh.show_behind_parent = true
	s.add_child(sh)
	var tw := s.create_tween().set_loops()
	tw.tween_property(s, "offset:y", -1.0, 0.7).set_delay(randf() * 0.3)
	tw.tween_property(s, "offset:y", 0.0, 0.7)
	return s


func _process(delta: float) -> void:
	_blink_t += delta
	var want := fmod(_blink_t, 3.6) > 3.45
	if want != _nurse_blink:
		_nurse_blink = want
		nurse.texture = Px.nurse(nurse_pose, want)


# ============================================================
# ชั้นทับ (overlay)
# ============================================================
func _build_overlay_ui() -> void:
	flag = PanelContainer.new()
	flag.add_theme_stylebox_override("panel", UI.tbox("wood", 10))
	flag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flag_text = UI.label("", 16, Color.WHITE, true)
	flag_text.add_theme_constant_override("outline_size", 4)
	flag_text.add_theme_color_override("font_outline_color", Color("3b2414"))
	flag_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	flag_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	flag.add_child(flag_text)
	flag.visible = false
	overlay.add_child(flag)
	if kind == "room":
		add_label("ward", Rect2(60, 20, 56, 8), "ป้ายหอผู้ป่วย", 10, Color.WHITE)
		add_label("room_no", Rect2(14, 14, 22, 6), "512", 8, Color.WHITE)
	else:
		add_label("door", Rect2(234, 12, 58, 11), "ห้องตรวจ 1", 13, Color.WHITE)
		add_label("sign", Rect2(140, 20, 64, 9), "หอผู้ป่วยอายุรกรรม", 10, Color.WHITE)
		add_label("table", Rect2(12, 73, 104, 7), "โต๊ะเตรียมอุปกรณ์", 9, UI.INK_2)


func add_label(key: String, world_rect: Rect2, text: String, size: int, color: Color) -> Label:
	var l := UI.label(text, size, color, true)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.set_meta("wr", world_rect)
	l.set_meta("fs", size)
	overlay.add_child(l)
	labels[key] = l
	_relayout()
	return l


## จุดกดในฉาก — มีประกายระยิบระยับบอกว่ากดได้
func add_hotspot(key: String, world_rect: Rect2, tip: String, cb: Callable) -> Button:
	var b := Button.new()
	b.flat = true
	b.tooltip_text = tip
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(1, 0.95, 0.6, 0.18)
	hover.border_color = UI.GOLD
	hover.set_border_width_all(3)
	b.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", hover)
	b.set_meta("wr", world_rect)
	b.mouse_entered.connect(func(): S.play("hover"))
	b.pressed.connect(func(): S.play("open"))
	b.pressed.connect(cb)
	overlay.add_child(b)
	hotspots[key] = b
	var sp := _sprite(Px.sparkle(0), world_rect.position + Vector2(world_rect.size.x - 2, 2))
	var tw := sp.create_tween().set_loops()
	tw.tween_callback(func(): sp.texture = Px.sparkle(1))
	tw.tween_interval(0.25)
	tw.tween_callback(func(): sp.texture = Px.sparkle(0))
	tw.tween_interval(0.25)
	tw.tween_callback(func(): sp.visible = false)
	tw.tween_interval(1.4 + randf())
	tw.tween_callback(func(): sp.visible = true)
	_relayout()
	return b


func _disp() -> Rect2:
	var s := size
	var k := maxf(s.x / W, s.y / H) if cover else minf(s.x / W, s.y / H)
	var ds := Vector2(W, H) * k
	return Rect2((s - ds) * 0.5, ds)

func w2s(p: Vector2) -> Vector2:
	var d := _disp()
	return d.position + p * (d.size.x / W)

func scale_k() -> float:
	return _disp().size.x / W

func _relayout() -> void:
	if overlay == null:
		return
	overlay.move_child(flag, -1)
	var d := _disp()
	var k := d.size.x / W
	for c in overlay.get_children():
		if c.has_meta("wr"):
			var wr: Rect2 = c.get_meta("wr")
			c.position = d.position + wr.position * k
			c.size = wr.size * k
			if c is Label:
				c.add_theme_font_size_override("font_size", maxi(9, int(c.get_meta("fs") * k / 2.6)))
	flag.custom_minimum_size.x = minf(size.x * 0.5, 620)
	flag.reset_size()
	flag.position = Vector2((size.x - flag.size.x) * 0.5, maxf(d.position.y, 0) + 64)


# ============================================================
# คำสั่งควบคุมฉาก
# ============================================================
func set_nurse(pose: String) -> void:
	nurse_pose = pose
	nurse.texture = Px.nurse(pose, false)

func set_patient(arms: String = "", eyes: String = "") -> void:
	if arms != "":
		pt_arms = arms
	if eyes != "":
		pt_eyes = eyes
	if patient:
		patient.texture = Px.patient(G.scn().sex, pt_arms, pt_eyes, false)

func show_flag(t: String) -> void:
	flag.visible = t != ""
	flag_text.text = t
	if t != "":
		_relayout()

## ให้ตัวละครขยับปากพูด + ไอคอนคำพูดเหนือหัว (ข้อความอยู่ในกล่องบทสนทนา)
func say(_text: String, who: String = "patient") -> void:
	if _talk_tw:
		_talk_tw.kill()
	var target: Sprite2D = patient if who == "patient" else nurse
	if target == null:
		return
	talk_icon.position = target.position + Vector2(10, -34)
	talk_icon.visible = true
	if who != "patient" or _text == "…":
		_talk_tw = create_tween()
		_talk_tw.tween_interval(1.0)
		_talk_tw.tween_callback(func(): talk_icon.visible = false)
		return
	_talk_tw = create_tween().set_loops(5)
	_talk_tw.tween_callback(func(): patient.texture = Px.patient(G.scn().sex, pt_arms, pt_eyes, true))
	_talk_tw.tween_interval(0.13)
	_talk_tw.tween_callback(func(): patient.texture = Px.patient(G.scn().sex, pt_arms, pt_eyes, false))
	_talk_tw.tween_interval(0.13)
	_talk_tw.finished.connect(func(): talk_icon.visible = false)

func quiet() -> void:
	talk_icon.visible = false

func set_think(on: bool, q: bool = false) -> void:
	if think:
		think.texture = Px.think_bubble(q)
		think.visible = on

func show_prop(key: String, pos: Vector2, on: bool = true) -> void:
	var s: Sprite2D = props[key]
	s.position = pos
	s.visible = on

func hide_props() -> void:
	for k in ["paper", "card", "pencil", "watch", "write", "penta"]:
		if props.has(k):
			props[k].visible = false
	if labels.has("card"):
		labels.card.visible = false

func reset_scene() -> void:
	hide_props()
	quiet()
	show_flag("")
	set_think(false)
	set_patient("rest", "open")
	if kind == "room":
		set_nurse("clip")
		nurse.position = NURSE_HOME
		props.table.visible = false
