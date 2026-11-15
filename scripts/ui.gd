class_name UI
extends RefCounted
## ธีมและตัวช่วยสร้าง UI แบบเกม pixel — กรอบ 9-slice, ปุ่มนูนมีเสียง, หัวข้อมีขอบตัวอักษร

const BG := Color("dcecf7")
const SURFACE := Color("f4f8fb")
const SURFACE_2 := Color("e8f0f6")
const INK := Color("13233a")
const INK_2 := Color("2b4460")
const MUTED := Color("5b7085")
const FAINT := Color("8da3b5")
const LINE := Color("c3d3e0")
const BRAND := Color("2f6fb8")
const BRAND_SOFT := Color("dceaf6")
const TEAL := Color("2f9b94")
const OK := Color("2e9a62")
const OK_SOFT := Color("ddf0e5")
const WARN := Color("d9822b")
const WARN_SOFT := Color("fbecd8")
const LILAC := Color("7b6ba8")
const GOLD := Color("ffd34d")
const DIALOG_TEXT := Color("13233a")   # ตัวหนังสือบนกล่องสีสว่าง
const PAPER_INK := Color("3e2a1c")

static var font_body: FontFile
static var font_bold: FontFile
static var font_head: FontFile


static func load_fonts() -> void:
	if font_body:
		return
	font_body = load("res://assets/fonts/IBMPlexSansThai-Regular.ttf")
	font_bold = load("res://assets/fonts/IBMPlexSansThai-SemiBold.ttf")
	font_head = load("res://assets/fonts/BaiJamjuree-Bold.ttf")
	# ฟอนต์สำรองสำหรับสัญลักษณ์ (★ ▶ ✔) และอีโมจิ (🪙 🏆 👗) — เวอร์ชันเว็บไม่มีฟอนต์ระบบให้ยืม
	var sym: FontFile = load("res://assets/fonts/DejaVuSans-Symbols.ttf")
	var emo: FontFile = load("res://assets/fonts/NotoColorEmoji-Subset.ttf")
	for f in [font_body, font_bold, font_head]:
		f.fallbacks = [sym, emo]


## กรอบสีเรียบ (ใช้กับแถวเล็ก ๆ)
static func box(bg: Color, border: Color = INK, bw: int = 3, pad: int = 12, shadow: bool = false) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_corner_radius_all(0)
	s.content_margin_left = pad
	s.content_margin_right = pad
	s.content_margin_top = pad * 0.6
	s.content_margin_bottom = pad * 0.6
	s.anti_aliasing = false
	if shadow:
		s.shadow_color = Color(0, 0, 0, 0.35)
		s.shadow_offset = Vector2(4, 4)
		s.shadow_size = 1
	return s

## กรอบ pixel แบบ texture (panel · dialog · paper · wood · btn · slot ...)
static func tbox(kind: String, pad: int = 14) -> StyleBoxTexture:
	var s := StyleBoxTexture.new()
	s.texture = Px.ui_frame(kind)
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		s.set_texture_margin(side, 12)
		s.set_content_margin(side, pad)
	s.content_margin_top = pad * 0.7
	s.content_margin_bottom = pad * 0.8
	return s


static func make_theme() -> Theme:
	load_fonts()
	var t := Theme.new()
	t.default_font = font_body
	t.default_font_size = 16
	t.set_color("font_color", "Label", INK)
	t.set_color("default_color", "RichTextLabel", INK)
	t.set_font("bold_font", "RichTextLabel", font_bold)
	t.set_font("normal_font", "RichTextLabel", font_body)
	t.set_stylebox("normal", "Button", tbox("btn_light", 14))
	t.set_stylebox("hover", "Button", tbox("slot_on", 14))
	t.set_stylebox("pressed", "Button", tbox("btn_press", 14))
	t.set_stylebox("disabled", "Button", tbox("btn_gray", 14))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_color("font_color", "Button", INK)
	t.set_color("font_hover_color", "Button", INK)
	t.set_color("font_pressed_color", "Button", Color.WHITE)
	t.set_color("font_disabled_color", "Button", Color("dfe6ee"))
	t.set_font("font", "Button", font_bold)
	t.set_stylebox("normal", "LineEdit", box(Color.WHITE, INK, 3, 10))
	t.set_stylebox("focus", "LineEdit", box(Color.WHITE, BRAND, 3, 10))
	t.set_color("font_color", "LineEdit", INK)
	t.set_color("font_placeholder_color", "LineEdit", FAINT)
	t.set_stylebox("panel", "PanelContainer", tbox("panel", 14))
	t.set_stylebox("panel", "TooltipPanel", box(INK, GOLD, 2, 8))
	t.set_color("font_color", "TooltipLabel", Color.WHITE)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("7f9bb5")
	sb.content_margin_left = 5
	sb.content_margin_right = 5
	for n in ["grabber", "grabber_highlight", "grabber_pressed"]:
		t.set_stylebox(n, "VScrollBar", sb)
	var sbg := StyleBoxFlat.new()
	sbg.bg_color = Color(0, 0, 0, 0.12)
	sbg.content_margin_left = 5
	sbg.content_margin_right = 5
	t.set_stylebox("scroll", "VScrollBar", sbg)
	return t


static func label(text: String, size: int = 16, color: Color = INK, bold: bool = false) -> Label:
	load_fonts()
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if bold:
		l.add_theme_font_override("font", font_bold)
	return l

static func head(text: String, size: int = 24, color: Color = INK) -> Label:
	load_fonts()
	var l := label(text, size, color)
	l.add_theme_font_override("font", font_head)
	return l

## หัวข้อแบบเกม — ตัวหนามีขอบเข้มและเงา
static func title(text: String, size: int = 36, color: Color = Color.WHITE, outline_c: Color = INK) -> Label:
	var l := head(text, size, color)
	l.add_theme_constant_override("outline_size", maxi(4, size / 6))
	l.add_theme_color_override("font_outline_color", outline_c)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.45))
	l.add_theme_constant_override("shadow_offset_x", 3)
	l.add_theme_constant_override("shadow_offset_y", 4)
	return l

static func wrap(l: Label) -> Label:
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l

static func rich(bb: String, size: int = 15, color: Color = INK) -> RichTextLabel:
	load_fonts()
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.text = bb
	r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r.add_theme_font_size_override("normal_font_size", size)
	r.add_theme_font_size_override("bold_font_size", size)
	r.add_theme_color_override("default_color", color)
	r.selection_enabled = false
	return r


static func _btn_style(b: Button, normal: String, hover: String, fg: Color, fg_hover: Color, pad: int) -> void:
	b.add_theme_stylebox_override("normal", tbox(normal, pad))
	b.add_theme_stylebox_override("hover", tbox(hover, pad))
	b.add_theme_stylebox_override("pressed", tbox("btn_press", pad))
	b.add_theme_stylebox_override("disabled", tbox("btn_gray", pad))
	b.add_theme_color_override("font_color", fg)
	b.add_theme_color_override("font_hover_color", fg_hover)
	b.add_theme_color_override("font_pressed_color", Color.WHITE)
	b.add_theme_color_override("font_focus_color", fg)

static func btn(text: String, cb: Callable = Callable(), kind: String = "", size: int = 16) -> Button:
	load_fonts()
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", size)
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	match kind:
		"primary":
			_btn_style(b, "btn", "btn_hover", Color.WHITE, Color.WHITE, 16)
			b.add_theme_constant_override("outline_size", 4)
			b.add_theme_color_override("font_outline_color", Color("13233a"))
		"ok":
			_btn_style(b, "btn_green", "btn_hover", Color.WHITE, Color.WHITE, 14)
			b.add_theme_constant_override("outline_size", 4)
			b.add_theme_color_override("font_outline_color", Color("13233a"))
		"warn":
			_btn_style(b, "btn_orange", "btn_hover", Color.WHITE, Color.WHITE, 14)
			b.add_theme_constant_override("outline_size", 4)
			b.add_theme_color_override("font_outline_color", Color("13233a"))
		"opt":
			# ตัวเลือกคำพูดในกล่องบทสนทนา
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
			b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			b.add_theme_font_override("font", font_body)
			b.add_theme_stylebox_override("normal", tbox("choice", 8))
			b.add_theme_stylebox_override("hover", tbox("choice_hover", 8))
			b.add_theme_stylebox_override("pressed", tbox("choice_hover", 8))
			b.add_theme_stylebox_override("disabled", tbox("choice", 8))
			b.add_theme_color_override("font_color", DIALOG_TEXT)
			b.add_theme_color_override("font_hover_color", BRAND)
			b.add_theme_color_override("font_pressed_color", BRAND)
			b.add_theme_color_override("font_disabled_color", Color("8da3b5"))
		_:
			_btn_style(b, "btn_light", "slot_on", INK, INK, 12)
	b.mouse_entered.connect(func():
		if not b.disabled:
			S.play("hover"))
	b.pressed.connect(func(): S.play("click"))
	if cb.is_valid():
		b.pressed.connect(cb)
	return b

static func mark_picked(b: Button) -> void:
	b.add_theme_color_override("font_disabled_color", GOLD)
	b.text = "✔ " + b.text

static func panel(bg: Color = SURFACE, border: Color = INK, pad: int = 14, shadow: bool = true) -> PanelContainer:
	var p := PanelContainer.new()
	if bg == SURFACE:
		p.add_theme_stylebox_override("panel", tbox("panel", pad))
	else:
		p.add_theme_stylebox_override("panel", box(bg, border, 3, pad, shadow))
	return p

static func frame(kind: String, pad: int = 14) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", tbox(kind, pad))
	return p

static func vbox(sep: int = 8) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	return v

static func hbox(sep: int = 8) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", sep)
	return h

static func flow(sep: int = 6) -> HFlowContainer:
	var f := HFlowContainer.new()
	f.add_theme_constant_override("h_separation", sep)
	f.add_theme_constant_override("v_separation", sep)
	return f

static func chip(text: String, bg: Color = BRAND_SOFT, fg: Color = BRAND, size: int = 13) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", box(bg, INK, 2, 8))
	p.add_child(label(text, size, fg, true))
	return p

static func scroll(child: Control) -> ScrollContainer:
	var s := ScrollContainer.new()
	s.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	s.size_flags_vertical = Control.SIZE_EXPAND_FILL
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	child.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.add_child(child)
	return s

static func pix(t: Texture2D, scale: float) -> TextureRect:
	var r := TextureRect.new()
	r.texture = t
	r.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.custom_minimum_size = t.get_size() * scale
	return r

static func spacer() -> Control:
	var c := Control.new()
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return c

static func margin(child: Control, m: int) -> MarginContainer:
	var mc := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		mc.add_theme_constant_override("margin_" + side, m)
	mc.add_child(child)
	return mc

static func clear(n: Node) -> void:
	for c in n.get_children():
		c.queue_free()

## ฉากหลังสำหรับหน้าเมนู (ภาพนอกโรงพยาบาล ขยายแบบ pixel) + เมฆลอย
static func backdrop(dim: float = 0.35) -> Control:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.clip_contents = true
	var t := TextureRect.new()
	t.texture = Px.cached("ext_bg", func(): return Art.hospital_exterior())
	t.set_anchors_preset(Control.PRESET_FULL_RECT)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(t)
	for i in 3:
		var c := TextureRect.new()
		c.texture = Px.cached("cloud_%d" % i, func(): return Art.cloud(40 + i * 12))
		c.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		c.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		c.size = c.texture.get_size() * 4
		c.position = Vector2(200 + i * 420, 40 + i * 50)
		c.modulate.a = 0.9
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(c)
		var tw := c.create_tween().set_loops()
		tw.tween_property(c, "position:x", -300.0, 50.0 + i * 15).from(1400.0 + i * 100)
	var shade := ColorRect.new()
	shade.color = Color(1.0, 0.99, 0.95, dim * 0.45)   # โทนสว่าง: ทับด้วยสีขาวนวล
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(shade)
	return root

## รูป Achievement — ใช้รูปวาดจริงถ้ามีไฟล์ ไม่งั้นใช้เหรียญตราชั่วคราว + อีโมจิ
static func ach_icon(a: Dictionary, unlocked: bool, k: float = 3.0) -> Control:
	var path: String = Prof.ACH_IMG_DIR + a.id + ".png"
	var box := CenterContainer.new()
	box.custom_minimum_size = Vector2(32, 32) * k
	box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if ResourceLoader.exists(path):
		var t := TextureRect.new()
		t.texture = load(path)
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		t.custom_minimum_size = Vector2(32, 32) * k
		if not unlocked:
			t.modulate = Color(0.3, 0.3, 0.35, 0.6)
		box.add_child(t)
		return box
	var st := Control.new()
	st.custom_minimum_size = Vector2(32, 32) * k
	var img := pix(Px.ach_badge(a.id, "", not unlocked), k)
	img.position = Vector2.ZERO
	img.size = img.custom_minimum_size
	st.add_child(img)
	var e := label(a.get("icon", "★") if unlocked else "?", int(11 * k), INK, true)
	e.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	e.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	e.position = Vector2(0, 0)
	e.size = Vector2(32, 28) * k
	st.add_child(e)
	box.add_child(st)
	return box
