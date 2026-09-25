class_name Px
extends RefCounted
## โรงงาน pixel art — วาดสไปรต์ทั้งหมดด้วยโค้ด (ไม่มีไฟล์ภาพภายนอกนอกจากโลโก้คณะ)
## ตัวละครพยาบาลใส่ชุดตามอัปเดต 25-9-2569:
##   ชุดกระโปรงขาว ปกป้ายขลิบน้ำเงิน ปลายแขนน้ำเงิน · โลโก้คณะพยาบาลศาสตร์ มข. ที่อก
##   หมวกพยาบาลสีขาวไม่มีขีด · ถุงเท้าขาว · รองเท้าพยาบาลสีขาว

const OUT := Color("262b40")
const SKIN := Color("efc09b")
const SKIN_SH := Color("d99a78")
const HAIR := Color("3a2721")
const HAIR_HI := Color("5a3d30")
const WHITE := Color("fbfcfd")
const WHITE_SH := Color("d3dde8")
const WHITE_SH2 := Color("b8c6d4")
const TRIM := Color("1f5fae")
const TRIM_D := Color("184a8a")
const LOGO_RING := Color("3f86c8")
const LOGO_RED := Color("a5462e")
const EYE := Color("2b1d18")
const BLUSH := Color("f2a39a")
const MOUTH := Color("b4735a")
const SHOE_SH := Color("c3cfdb")

static var _cache := {}


# ============================================================
# ตัวช่วยวาดบน Image
# ============================================================
static func blank(w: int, h: int) -> Image:
	return Image.create_empty(w, h, false, Image.FORMAT_RGBA8)

static func r(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	for yy in range(y, y + h):
		for xx in range(x, x + w):
			p(img, xx, yy, c)

static func p(img: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		img.set_pixel(x, y, c)

static func line(img: Image, x0: int, y0: int, x1: int, y1: int, c: Color, th: int = 1) -> void:
	var dx: int = absi(x1 - x0)
	var dy: int = -absi(y1 - y0)
	var sx: int = 1 if x0 < x1 else -1
	var sy: int = 1 if y0 < y1 else -1
	var err: int = dx + dy
	while true:
		for t in th:
			p(img, x0 + t, y0, c)
		if x0 == x1 and y0 == y1:
			break
		var e2: int = 2 * err
		if e2 >= dy:
			err += dy
			x0 += sx
		if e2 <= dx:
			err += dx
			y0 += sy

static func ell(img: Image, cx: float, cy: float, rx: float, ry: float, c: Color) -> void:
	for yy in range(int(cy - ry) - 1, int(cy + ry) + 2):
		for xx in range(int(cx - rx) - 1, int(cx + rx) + 2):
			var nx := (xx + 0.5 - cx) / rx
			var ny := (yy + 0.5 - cy) / ry
			if nx * nx + ny * ny <= 1.0:
				p(img, xx, yy, c)

## เส้นขอบรอบรูปทรง (เฉพาะด้านนอก) — ทำให้ดูเป็น pixel art ชัด ๆ บนพื้นหลังสว่าง
static func outline(img: Image, c: Color = OUT) -> Image:
	var w := img.get_width()
	var h := img.get_height()
	var out := img.duplicate() as Image
	for y in h:
		for x in w:
			if img.get_pixel(x, y).a > 0.1:
				continue
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var q: Vector2i = Vector2i(x, y) + d
				if q.x >= 0 and q.y >= 0 and q.x < w and q.y < h and img.get_pixel(q.x, q.y).a > 0.1:
					out.set_pixel(x, y, c)
					break
	return out

static func tex(img: Image) -> ImageTexture:
	return ImageTexture.create_from_image(img)

static func cached(key: String, maker: Callable) -> ImageTexture:
	if not _cache.has(key):
		_cache[key] = tex(maker.call())
	return _cache[key]


## จุดสลับสี (dither) — ทำพื้นผิวให้ไม่เรียบโล้น
static func dither(img: Image, x: int, y: int, w: int, h: int, c: Color, every: int = 2) -> void:
	for yy in range(y, y + h):
		for xx in range(x, x + w):
			if (xx + yy) % every == 0 and (yy % 2 == 0 or every == 2):
				p(img, xx, yy, c)

## สุ่มจุดเล็ก ๆ ให้พื้นผิวมีเนื้อ
static func noise(img: Image, x: int, y: int, w: int, h: int, amount: float, density: float, seed_: int = 7) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_
	for yy in range(y, y + h):
		for xx in range(x, x + w):
			if rng.randf() < density and xx >= 0 and yy >= 0 and xx < img.get_width() and yy < img.get_height():
				var c := img.get_pixel(xx, yy)
				c = c.lightened(amount) if rng.randf() < 0.5 else c.darkened(amount)
				img.set_pixel(xx, yy, c)

## ผสมสีแบบโปร่งแสง (แสงจากหน้าต่าง เงา)
static func blend(img: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		img.set_pixel(x, y, img.get_pixel(x, y).blend(c))

static func shadow() -> ImageTexture:
	return cached("shadow", func():
		var img := blank(26, 7)
		ell(img, 13, 3.5, 12.5, 3.2, Color(0.12, 0.08, 0.22, 0.28))
		ell(img, 13, 3.5, 8, 2, Color(0.12, 0.08, 0.22, 0.38))
		return img)

static func sparkle(frame: int) -> ImageTexture:
	return cached("sparkle_%d" % frame, func():
		var img := blank(7, 7)
		var c := Color("fff6b0")
		if frame == 0:
			p(img, 3, 3, Color.WHITE); p(img, 3, 2, c); p(img, 3, 4, c); p(img, 2, 3, c); p(img, 4, 3, c)
		else:
			r(img, 3, 0, 1, 7, c); r(img, 0, 3, 7, 1, c); p(img, 3, 3, Color.WHITE)
		return img)

static func exclaim() -> ImageTexture:
	return cached("exclaim", func():
		var img := blank(9, 11)
		r(img, 1, 0, 7, 9, Color("ffd34d"))
		r(img, 4, 2, 1, 4, OUT); p(img, 4, 7, OUT)
		return outline(img))

static func talk_icon() -> ImageTexture:
	return cached("talk_icon", func():
		var img := blank(13, 10)
		r(img, 1, 1, 11, 6, Color.WHITE)
		p(img, 3, 7, Color.WHITE); p(img, 2, 8, Color.WHITE)
		for i in 3:
			p(img, 3 + i * 3, 4, Color("5b7085"))
		return outline(img))


# ============================================================
# ภาพหน้าตัวละคร (portrait) 40×40 สำหรับกล่องบทสนทนา
# ============================================================
static func portrait(who: String, expr: String = "normal") -> ImageTexture:
	return cached("pt_%s_%s" % [who, expr], func(): return _portrait_img(who, expr))

static func _portrait_img(who: String, expr: String) -> Image:
	var img := blank(40, 40)
	if who == "nurse":
		# ไหล่ + ชุดขาว ปกน้ำเงิน โลโก้
		for y in range(30, 40):
			var hw := 13 + (y - 30) / 2
			r(img, 20 - hw, y, hw * 2, 1, WHITE)
			p(img, 20 + hw - 1, y, WHITE_SH); p(img, 20 + hw - 2, y, WHITE_SH)
		r(img, 17, 26, 6, 5, SKIN)
		r(img, 17, 27, 6, 1, SKIN_SH)
		r(img, 18, 30, 4, 2, SKIN)
		line(img, 13, 30, 23, 39, TRIM, 2)
		line(img, 27, 30, 24, 34, TRIM, 2)
		ell(img, 10.5, 35.5, 3, 3, LOGO_RING)
		ell(img, 10.5, 35.5, 1.8, 1.8, LOGO_RED)
		p(img, 10, 34, WHITE)
		# ผมด้านหลัง
		ell(img, 20, 17, 13, 13, HAIR)
		r(img, 7, 17, 4, 13, HAIR)
		r(img, 29, 17, 4, 13, HAIR)
		# หน้า
		ell(img, 20, 19.5, 9.5, 10, SKIN)
		for y in range(13, 27):
			p(img, 28, y, SKIN_SH)
		# หน้าม้า
		r(img, 11, 9, 18, 4, HAIR)
		for x in [12, 13, 16, 17, 22, 23, 26, 27]:
			p(img, x, 13, HAIR)
		p(img, 14, 10, HAIR_HI); p(img, 15, 10, HAIR_HI); p(img, 16, 9, HAIR_HI); p(img, 24, 10, HAIR_HI)
		p(img, 9, 18, HAIR_HI); p(img, 9, 19, HAIR_HI)
		# คิ้ว ตา
		r(img, 13, 16, 4, 1, HAIR); r(img, 23, 16, 4, 1, HAIR)
		if expr == "blink":
			r(img, 13, 20, 4, 1, EYE); r(img, 23, 20, 4, 1, EYE)
		else:
			r(img, 14, 18, 3, 4, EYE); r(img, 23, 18, 3, 4, EYE)
			p(img, 15, 18, Color.WHITE); p(img, 24, 18, Color.WHITE)
			p(img, 13, 18, EYE); p(img, 26, 18, EYE)
		r(img, 12, 23, 2, 1, BLUSH); r(img, 26, 23, 2, 1, BLUSH)
		p(img, 20, 22, SKIN_SH)
		if expr == "talk":
			r(img, 18, 25, 4, 2, Color("8a3b35")); r(img, 19, 26, 2, 1, Color("d9786e"))
		elif expr == "smile":
			r(img, 18, 25, 4, 1, MOUTH); p(img, 17, 24, MOUTH); p(img, 22, 24, MOUTH)
		else:
			r(img, 18, 25, 4, 1, MOUTH)
		# หมวกพยาบาลขาว ไม่มีขีด
		r(img, 12, 3, 16, 1, WHITE)
		r(img, 11, 4, 18, 4, WHITE)
		r(img, 11, 8, 18, 1, WHITE_SH)
		r(img, 14, 5, 12, 1, WHITE_SH)
		r(img, 25, 4, 4, 4, WHITE_SH)
		r(img, 12, 3, 4, 1, Color.WHITE)
		return outline(img)

	# ผู้ป่วย
	var female := who == "f"
	var skin := Color("e2ad88")
	var skin_sh := Color("c98f6c")
	var gown := Color("e7aac2") if female else Color("8fb8dc")
	var gown_sh := Color("cc8aa6") if female else Color("6f9cc7")
	var hair := Color("e4e4e4") if female else Color("cfd3d8")
	var hair_sh := Color("b5b5b5") if female else Color("a2a9b1")
	for y in range(31, 40):
		var hw := 14 + (y - 31) / 2
		r(img, 20 - hw, y, hw * 2, 1, gown)
		p(img, 20 + hw - 1, y, gown_sh); p(img, 20 + hw - 2, y, gown_sh)
	for i in 5:
		p(img, 10 + i * 5, 35 + (i % 2) * 2, gown_sh)
	r(img, 16, 26, 8, 6, skin)
	r(img, 16, 27, 8, 1, skin_sh)
	line(img, 15, 31, 20, 36, gown_sh); line(img, 25, 31, 20, 36, gown_sh)
	ell(img, 20, 17, 12, 12.5, hair)
	if female:
		ell(img, 20, 5, 6, 4, hair)             # มวยผม
		ell(img, 20, 5, 3, 2, hair_sh)
		r(img, 8, 16, 4, 12, hair)
		r(img, 28, 16, 4, 12, hair)
	ell(img, 20, 19.5, 9.5, 10, skin)
	for y in range(13, 27):
		p(img, 28, y, skin_sh)
	if female:
		r(img, 11, 9, 18, 3, hair)
		line(img, 12, 12, 16, 9, hair_sh)
	else:
		r(img, 11, 8, 18, 3, hair)
		r(img, 9, 11, 3, 8, hair); r(img, 28, 11, 3, 8, hair)
		p(img, 14, 9, hair_sh); p(img, 18, 8, hair_sh); p(img, 24, 9, hair_sh)
	# ริ้วรอย
	r(img, 15, 13, 10, 1, skin_sh)
	r(img, 13, 16, 4, 1, hair_sh); r(img, 23, 16, 4, 1, hair_sh)
	match expr:
		"closed":
			r(img, 13, 20, 4, 1, EYE); r(img, 23, 20, 4, 1, EYE)
		"think":
			r(img, 15, 18, 2, 2, EYE); r(img, 24, 18, 2, 2, EYE)
			p(img, 12, 15, hair_sh); p(img, 27, 15, hair_sh)
		"confused":
			r(img, 14, 19, 3, 3, EYE); r(img, 23, 20, 2, 2, EYE)
			r(img, 13, 15, 4, 1, hair_sh); p(img, 26, 17, hair_sh)
		_:
			r(img, 14, 19, 3, 3, EYE); r(img, 23, 19, 3, 3, EYE)
			p(img, 15, 19, Color.WHITE); p(img, 24, 19, Color.WHITE)
	r(img, 13, 23, 3, 1, skin_sh); r(img, 24, 23, 3, 1, skin_sh)   # ถุงใต้ตา
	p(img, 20, 22, skin_sh); p(img, 21, 22, skin_sh)
	if expr == "talk":
		r(img, 18, 25, 5, 2, Color("7a3d33"))
	elif expr == "confused":
		line(img, 18, 26, 22, 25, Color("a86a55"))
	else:
		r(img, 18, 25, 5, 1, Color("a86a55"))
	r(img, 16, 27, 8, 1, skin_sh)
	if female:
		var gl := Color("8a6b4a")
		for gx in [12, 22]:
			r(img, gx, 17, 7, 1, gl); r(img, gx, 22, 7, 1, gl)
			r(img, gx, 17, 1, 6, gl); r(img, gx + 6, 17, 1, 6, gl)
		r(img, 19, 18, 3, 1, gl)
		p(img, 13, 18, Color(1, 1, 1, 0.8)); p(img, 23, 18, Color(1, 1, 1, 0.8))
	return outline(img)


# ============================================================
# กรอบ UI แบบ pixel (9-slice) ขยาย 3 เท่า
# ============================================================
static func ui_frame(kind: String) -> ImageTexture:
	return cached("ui_" + kind, func():
		var img := blank(12, 12)
		var o := Color("13233a")
		match kind:
			"dialog":
				r(img, 0, 0, 12, 12, o)
				r(img, 1, 1, 10, 10, Color("1b3150"))
				r(img, 2, 2, 8, 8, Color("7fb2e0"))
				r(img, 3, 3, 6, 6, Color("1b3150"))
				p(img, 0, 0, Color(0, 0, 0, 0)); p(img, 11, 0, Color(0, 0, 0, 0)); p(img, 0, 11, Color(0, 0, 0, 0)); p(img, 11, 11, Color(0, 0, 0, 0))
			"paper":
				r(img, 0, 0, 12, 12, Color("5a3a22"))
				r(img, 1, 1, 10, 10, Color("fbf3e6"))
				r(img, 1, 10, 10, 1, Color("e2d3bd"))
				r(img, 10, 1, 1, 10, Color("e2d3bd"))
			"wood":
				r(img, 0, 0, 12, 12, Color("3b2414"))
				r(img, 1, 1, 10, 10, Color("9a6a42"))
				r(img, 1, 1, 10, 1, Color("c08b5c"))
				r(img, 1, 1, 1, 10, Color("b27f52"))
				r(img, 1, 10, 10, 1, Color("6e4629"))
				r(img, 10, 1, 1, 10, Color("6e4629"))
				r(img, 3, 3, 6, 6, Color("8a5d38"))
			"btn", "btn_hover", "btn_press", "btn_green", "btn_orange", "btn_gray", "btn_light":
				var base: Color = {"btn": Color("2f6fb8"), "btn_hover": Color("3f86d6"), "btn_press": Color("255c9c"),
					"btn_green": Color("2e9a62"), "btn_orange": Color("d9822b"), "btn_gray": Color("8b9bab"), "btn_light": Color("e9f2fa")}[kind]
				r(img, 0, 0, 12, 12, o)
				r(img, 1, 1, 10, 10, base)
				if kind != "btn_press":
					r(img, 1, 1, 10, 1, base.lightened(0.35))
					r(img, 1, 1, 1, 9, base.lightened(0.2))
					r(img, 1, 9, 10, 2, base.darkened(0.35))
				else:
					r(img, 1, 1, 10, 2, base.darkened(0.3))
				p(img, 0, 0, Color(0, 0, 0, 0)); p(img, 11, 0, Color(0, 0, 0, 0)); p(img, 0, 11, Color(0, 0, 0, 0)); p(img, 11, 11, Color(0, 0, 0, 0))
			"slot":
				r(img, 0, 0, 12, 12, Color("2c3e55"))
				r(img, 1, 1, 10, 10, Color("4a6280"))
				r(img, 1, 1, 10, 1, Color("22334a"))
				r(img, 1, 1, 1, 10, Color("22334a"))
			"slot_on":
				r(img, 0, 0, 12, 12, Color("13233a"))
				r(img, 1, 1, 10, 10, Color("ffe08a"))
				r(img, 1, 1, 10, 1, Color("fff4c7"))
				r(img, 1, 10, 10, 1, Color("d9a93b"))
			"choice":
				r(img, 0, 0, 12, 12, Color(1, 1, 1, 0.0))
			"choice_hover":
				r(img, 0, 0, 12, 12, Color(1, 1, 1, 0.14))
				r(img, 0, 0, 12, 1, Color("ffe08a")); r(img, 0, 11, 12, 1, Color("ffe08a"))
			_:  # panel
				r(img, 0, 0, 12, 12, o)
				r(img, 1, 1, 10, 10, Color("f4f8fb"))
				r(img, 1, 1, 10, 1, Color.WHITE)
				r(img, 1, 1, 1, 10, Color.WHITE)
				r(img, 1, 10, 10, 1, Color("c3d3e0"))
				r(img, 10, 1, 1, 10, Color("c3d3e0"))
				p(img, 0, 0, Color(0, 0, 0, 0)); p(img, 11, 0, Color(0, 0, 0, 0)); p(img, 0, 11, Color(0, 0, 0, 0)); p(img, 11, 11, Color(0, 0, 0, 0))
		img.resize(36, 36, Image.INTERPOLATE_NEAREST)
		return img)


# ============================================================
# โลโก้คณะพยาบาลศาสตร์ มข. — แปลงรูปจริงเป็น pixel
# ============================================================
static func logo_image() -> Image:
	var tex_res = load("res://assets/logo_nursing.png")
	var img: Image = tex_res.get_image() if tex_res else blank(8, 8)
	if img.is_compressed():
		img.decompress()
	img.convert(Image.FORMAT_RGBA8)
	# ตัดเฉพาะวงกลม (รูปต้นฉบับมีไอคอนกล้องติดมุมซ้ายล่าง)
	var w := img.get_width()
	var h := img.get_height()
	var cx := w * 0.5
	var cy := h * 0.5
	var rad := minf(w, h) * 0.5 - 2.0
	for y in h:
		for x in w:
			if Vector2(x - cx, y - cy).length() > rad:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
	var side := int(rad * 2)
	var out := img.get_region(Rect2i(int(cx - rad), int(cy - rad), side, side))
	return out

static func logo_tex() -> ImageTexture:
	return cached("logo_full", func(): return logo_image())

static func logo_pixel(size: int) -> ImageTexture:
	return cached("logo_px_%d" % size, func():
		var img := logo_image()
		img.resize(size, size, Image.INTERPOLATE_LANCZOS)
		for y in size:
			for x in size:
				var c := img.get_pixel(x, y)
				c.a = 1.0 if c.a > 0.5 else 0.0
				img.set_pixel(x, y, c)
		return img)


# ============================================================
# พยาบาล (นักศึกษาพยาบาล) 32×64
# pose: idle · walk1 · walk2 · offer · tray · clip · show · point
# ============================================================
static func nurse(pose: String = "idle", blink: bool = false) -> ImageTexture:
	return cached("nurse_%s_%s" % [pose, blink], func(): return _nurse_img(pose, blink))

static func _nurse_img(pose: String, blink: bool) -> Image:
	var img := blank(32, 64)
	var walk := 0
	if pose == "walk1":
		walk = 1
	elif pose == "walk2":
		walk = -1

	# ---- ขา · ถุงเท้าขาว · รองเท้าพยาบาลขาว ----
	var lx := 12
	var rx := 18
	var ly := 0
	var ry := 0
	if walk == 1:
		lx = 11; rx = 19; ry = -1
	elif walk == -1:
		lx = 11; rx = 19; ly = -1
	r(img, lx, 54 + ly, 3, 2, SKIN)
	r(img, rx, 54 + ry, 3, 2, SKIN)
	r(img, lx, 56 + ly, 3, 4, WHITE)            # ถุงเท้าขาว
	r(img, rx, 56 + ry, 3, 4, WHITE)
	p(img, lx, 56 + ly, WHITE_SH)
	p(img, rx + 2, 56 + ry, WHITE_SH)
	r(img, lx - 1, 60 + ly, 5, 2, WHITE)        # รองเท้าขาว
	r(img, rx - 1, 60 + ry, 5, 2, WHITE)
	r(img, lx - 1, 62 + ly, 5, 1, SHOE_SH)
	r(img, rx - 1, 62 + ry, 5, 1, SHOE_SH)

	# ---- ชุดกระโปรงขาว ----
	for y in range(22, 55):
		var half := 6
		if y < 24:
			half = 5
		elif y < 36:
			half = 6
		elif y < 41:
			half = 5
		else:
			half = 5 + int((y - 41) / 4.0)
		r(img, 16 - half, y, half * 2 + 1, 1, WHITE)
	# เงาด้านข้าง + รอยป้ายหน้า (ชุดแบบป้าย)
	for y in range(24, 55):
		var half2 := 6 if y < 36 else (5 if y < 41 else 5 + int((y - 41) / 4.0))
		p(img, 16 + half2, y, WHITE_SH)
		p(img, 16 - half2, y, WHITE_SH)
	line(img, 20, 32, 20, 54, WHITE_SH)
	# ชายกระโปรง
	r(img, 8, 54, 17, 1, WHITE_SH)
	# กระเป๋า/ฝาปิดที่เอว
	r(img, 11, 40, 3, 1, WHITE_SH2)
	r(img, 21, 40, 3, 1, WHITE_SH2)

	# ---- คอเสื้อ V + ปกป้ายขลิบน้ำเงิน ----
	r(img, 14, 22, 5, 2, SKIN)
	p(img, 15, 24, SKIN); p(img, 16, 24, SKIN); p(img, 17, 24, SKIN)
	p(img, 16, 25, SKIN)
	line(img, 11, 22, 20, 31, TRIM, 2)          # ปกยาวจากไหล่ซ้าย (ของผู้ดู) ป้ายไปขวา
	line(img, 21, 22, 18, 26, TRIM, 2)          # ปกสั้นอีกข้าง
	p(img, 21, 31, TRIM_D)

	# ---- โลโก้คณะที่อก ----
	var lg := Vector2i(11, 27)
	r(img, lg.x + 1, lg.y, 2, 1, LOGO_RING)
	r(img, lg.x, lg.y + 1, 1, 2, LOGO_RING)
	r(img, lg.x + 3, lg.y + 1, 1, 2, LOGO_RING)
	r(img, lg.x + 1, lg.y + 3, 2, 1, LOGO_RING)
	p(img, lg.x + 1, lg.y + 1, WHITE)
	p(img, lg.x + 2, lg.y + 1, LOGO_RED)
	p(img, lg.x + 1, lg.y + 2, LOGO_RED)
	p(img, lg.x + 2, lg.y + 2, LOGO_RED)

	# ---- แขนเสื้อสั้น ปลายแขนน้ำเงิน + แขน ----
	var swing := walk
	_nurse_arm(img, "L", pose, swing)
	_nurse_arm(img, "R", pose, -swing)

	# ---- ศีรษะ ----
	ell(img, 16, 13.5, 7.5, 7.5, HAIR)           # ผม
	r(img, 9, 13, 2, 8, HAIR)
	r(img, 22, 13, 2, 8, HAIR)
	ell(img, 16, 15.5, 5.6, 6.2, SKIN)           # หน้า
	r(img, 11, 9, 11, 2, HAIR)                   # หน้าม้า
	p(img, 15, 11, HAIR); p(img, 16, 11, HAIR); p(img, 12, 11, HAIR); p(img, 20, 11, HAIR)
	p(img, 13, 9, HAIR_HI); p(img, 14, 9, HAIR_HI)
	if blink:
		r(img, 13, 15, 2, 1, EYE)
		r(img, 18, 15, 2, 1, EYE)
	else:
		r(img, 13, 14, 2, 2, EYE)
		r(img, 18, 14, 2, 2, EYE)
	p(img, 12, 17, BLUSH); p(img, 20, 17, BLUSH)
	r(img, 15, 18, 3, 1, MOUTH)
	p(img, 11, 18, SKIN_SH); p(img, 21, 18, SKIN_SH)
	# มวยผมด้านหลัง
	ell(img, 16, 5.5, 3.5, 2.2, HAIR)

	# ---- หมวกพยาบาลสีขาว ไม่มีขีด ----
	r(img, 11, 4, 11, 1, WHITE)
	r(img, 10, 5, 13, 2, WHITE)
	r(img, 10, 7, 13, 1, WHITE_SH)
	r(img, 12, 3, 9, 1, WHITE)
	p(img, 10, 5, WHITE_SH); p(img, 22, 5, WHITE_SH)
	r(img, 13, 5, 7, 1, WHITE_SH)                # รอยพับของหมวก (ไม่ใช่ขีดสี)

	# ---- แสงเงาเพิ่มมิติ ----
	for y in range(24, 54):
		var hw := 6 if y < 36 else (5 if y < 41 else 5 + int((y - 41) / 4.0))
		p(img, 16 + hw - 1, y, WHITE_SH)                 # เงาด้านขวาของชุด
		if y > 42:
			p(img, 16 + hw - 2, y, WHITE_SH)
		p(img, 16 - hw + 1, y, Color.WHITE)              # ขอบรับแสงด้านซ้าย
	r(img, 11, 34, 11, 1, WHITE_SH)                      # เงาใต้อก
	line(img, 13, 44, 12, 53, WHITE_SH)                  # จีบกระโปรง
	line(img, 17, 45, 17, 53, WHITE_SH)
	p(img, 14, 22, SKIN_SH); p(img, 18, 22, SKIN_SH)     # เงาใต้คาง
	r(img, 21, 13, 1, 6, SKIN_SH)                        # เงาแก้มขวา
	p(img, 12, 9, HAIR_HI); p(img, 13, 9, HAIR_HI); p(img, 18, 9, HAIR_HI)
	p(img, 10, 14, HAIR_HI); p(img, 10, 15, HAIR_HI)
	r(img, 22, 17, 2, 4, Color("2a1c17"))                # ผมด้านเงา
	if not blink:
		p(img, 14, 14, Color.WHITE); p(img, 19, 14, Color.WHITE)  # ประกายตา
	r(img, 11, 3, 3, 1, Color.WHITE)                     # ไฮไลต์หมวก
	r(img, 20, 6, 3, 2, WHITE_SH)

	# ---- ของในมือ ----
	if pose == "tray":
		r(img, 5, 38, 23, 2, Color("b9c9d6"))
		r(img, 5, 40, 23, 1, Color("8fa3b5"))
		r(img, 7, 34, 4, 4, Color("fdfcf8"))     # แบบประเมิน
		r(img, 12, 35, 4, 3, WHITE)             # กระดาษ
		r(img, 17, 36, 6, 1, Color("e8b84b"))   # ดินสอ
		r(img, 24, 35, 3, 3, Color("8f9fac"))   # นาฬิกา
	elif pose == "clip":
		r(img, 3, 31, 7, 10, Color("9b7653"))
		r(img, 4, 32, 5, 8, Color("fdfcf8"))
		r(img, 5, 30, 3, 2, Color("7c8a96"))
		r(img, 5, 34, 3, 1, Color("9aa8b4")); r(img, 5, 36, 3, 1, Color("9aa8b4"))
	return outline(img)

static func _nurse_arm(img: Image, side: String, pose: String, swing: int) -> void:
	var sx := 6 if side == "L" else 23          # ไหล่ด้านซ้าย/ขวาของภาพ
	var ax := 6 if side == "L" else 24          # แนวแขนที่ห้อยลง
	# แขนเสื้อสั้นสีขาว + ขลิบน้ำเงิน
	r(img, sx, 23, 3, 6, WHITE)
	r(img, sx, 29, 3, 2, TRIM)
	var ext := (side == "R" and (pose == "offer" or pose == "show" or pose == "point"))
	if ext:
		# ยื่นแขนไปข้างหน้า (ทางขวาของภาพ)
		var ay := 27 if pose != "show" else 24
		r(img, 25, ay, 5, 2, SKIN)
		r(img, 29, ay - 1, 3, 3, SKIN)
		p(img, 25, ay + 2, SKIN_SH)
		return
	if pose == "tray" or (pose == "clip" and side == "L"):
		# งอศอกมาถือของตรงหน้า
		r(img, ax, 31, 2, 5, SKIN)
		if side == "L":
			r(img, ax, 35, 4, 2, SKIN)
		else:
			r(img, ax - 2, 35, 4, 2, SKIN)
		return
	r(img, ax, 31 + swing, 2, 9, SKIN)
	r(img, ax, 40 + swing, 2, 2, SKIN_SH)


# ============================================================
# ผู้ป่วย (นั่ง) 32×50 — sex: "m" คุณสมชาย · "f" คุณยายสมพร
# arms: rest · reach_r · reach_l · reach_both · hold · think · fingers · table
# ============================================================
static func patient(sex: String, arms: String = "rest", eyes: String = "open", talk: bool = false) -> ImageTexture:
	return cached("pt_%s_%s_%s_%s" % [sex, arms, eyes, talk], func(): return _patient_img(sex, arms, eyes, talk))

static func _patient_img(sex: String, arms: String, eyes: String, talk: bool) -> Image:
	var img := blank(36, 50)
	var skin := Color("e2ad88")
	var skin_sh := Color("c98f6c")
	var gown := Color("8fb8dc") if sex == "m" else Color("e7aac2")
	var gown_sh := Color("6f9cc7") if sex == "m" else Color("cc8aa6")
	var hair := Color("cfd3d8") if sex == "m" else Color("e4e4e4")
	var hair_sh := Color("a9afb6") if sex == "m" else Color("bcbcbc")
	var cx := 18

	# ขา (นั่ง) + รองเท้าแตะ
	r(img, cx - 7, 38, 6, 4, gown_sh)
	r(img, cx + 1, 38, 6, 4, gown_sh)
	r(img, cx - 6, 42, 4, 5, skin)
	r(img, cx + 2, 42, 4, 5, skin)
	r(img, cx - 7, 47, 6, 2, Color("7b8a99"))
	r(img, cx + 1, 47, 6, 2, Color("7b8a99"))
	# ลำตัว + ชุดผู้ป่วย
	for y in range(20, 39):
		var half := 8 if y < 36 else 9
		r(img, cx - half, y, half * 2, 1, gown)
	for i in range(0, 5):
		p(img, cx - 5 + i * 3, 26 + (i % 2) * 5, gown_sh)
		p(img, cx - 4 + i * 3, 33 - (i % 2) * 4, gown_sh)
	line(img, cx, 21, cx, 37, gown_sh)
	r(img, cx - 2, 20, 4, 2, skin)
	# แขน
	_patient_arms(img, arms, skin, skin_sh, gown, cx)
	# ศีรษะ
	ell(img, cx, 12, 7, 7.5, hair)
	ell(img, cx, 13.5, 5.8, 6.2, skin)
	if sex == "m":
		r(img, cx - 6, 6, 12, 3, hair)
		r(img, cx - 7, 8, 2, 6, hair)
		r(img, cx + 5, 8, 2, 6, hair)
		p(img, cx - 3, 7, hair_sh); p(img, cx + 2, 7, hair_sh)
	else:
		ell(img, cx, 4.5, 3.5, 2.5, hair)       # มวยผม
		r(img, cx - 6, 6, 12, 3, hair)
		r(img, cx - 7, 8, 2, 9, hair)
		r(img, cx + 5, 8, 2, 9, hair)
		p(img, cx, 7, hair_sh); p(img, cx - 1, 8, hair_sh)
	# ริ้วรอย/คิ้ว
	r(img, cx - 4, 11, 2, 1, hair_sh)
	r(img, cx + 2, 11, 2, 1, hair_sh)
	match eyes:
		"closed":
			r(img, cx - 4, 13, 2, 1, EYE)
			r(img, cx + 2, 13, 2, 1, EYE)
		"worried":
			p(img, cx - 3, 13, EYE); p(img, cx + 3, 13, EYE)
			p(img, cx - 4, 11, hair_sh); p(img, cx + 4, 11, hair_sh)
		_:
			r(img, cx - 3, 12, 1, 2, EYE)
			r(img, cx + 3, 12, 1, 2, EYE)
	p(img, cx - 5, 15, Color("e79e92")); p(img, cx + 5, 15, Color("e79e92"))
	if talk:
		r(img, cx - 1, 16, 3, 2, Color("7a3d33"))
	else:
		r(img, cx - 1, 16, 3, 1, Color("a86a55"))
	p(img, cx - 5, 17, skin_sh); p(img, cx + 5, 17, skin_sh)
	if sex == "m":
		r(img, cx - 2, 19, 5, 1, skin_sh)       # รอยย่นคาง
	# แสงเงา
	for y in range(21, 38):
		p(img, cx + 6, y, gown_sh)
		p(img, cx + 7, y, gown_sh)
		p(img, cx - 7, y, gown.lightened(0.18))
	r(img, cx - 3, 21, 6, 1, gown_sh)          # คอเสื้อ
	p(img, cx - 3, 22, gown_sh); p(img, cx + 2, 22, gown_sh)
	r(img, cx + 4, 11, 1, 6, skin_sh)           # เงาแก้ม
	p(img, cx - 3, 6, hair.lightened(0.35)); p(img, cx - 2, 6, hair.lightened(0.35)); p(img, cx + 1, 7, hair.lightened(0.35))
	if eyes == "open":
		p(img, cx - 3, 12, Color.WHITE); p(img, cx + 3, 12, Color.WHITE)
		p(img, cx - 3, 13, EYE); p(img, cx + 3, 13, EYE)
	if sex == "f":
		# แว่นสายตาของคุณยาย
		var gl := Color("8a6b4a")
		r(img, cx - 5, 11, 4, 1, gl); r(img, cx - 5, 14, 4, 1, gl)
		r(img, cx + 1, 11, 4, 1, gl); r(img, cx + 1, 14, 4, 1, gl)
		p(img, cx - 5, 12, gl); p(img, cx - 5, 13, gl); p(img, cx - 2, 12, gl); p(img, cx - 2, 13, gl)
		p(img, cx + 1, 12, gl); p(img, cx + 1, 13, gl); p(img, cx + 4, 12, gl); p(img, cx + 4, 13, gl)
		p(img, cx - 1, 12, gl); p(img, cx, 12, gl)
	return outline(img)

static func _patient_arms(img: Image, arms: String, skin: Color, skin_sh: Color, gown: Color, cx: int) -> void:
	# แขนเสื้อ
	r(img, cx - 10, 21, 3, 6, gown)
	r(img, cx + 7, 21, 3, 6, gown)
	var left_reach := arms in ["reach_r", "reach_both"]    # มือขวาของผู้ป่วย = ซ้ายของภาพ
	var right_reach := arms in ["reach_l", "reach_both"]
	if left_reach:
		r(img, cx - 14, 25, 5, 2, skin)
		r(img, cx - 16, 24, 3, 3, skin)
	elif arms == "hold" or arms == "table":
		r(img, cx - 9, 27, 2, 5, skin)
		r(img, cx - 8, 31, 5, 2, skin)
	elif arms == "think":
		r(img, cx - 9, 27, 2, 5, skin)
		r(img, cx - 8, 31, 5, 2, skin)
	else:
		r(img, cx - 9, 27, 2, 7, skin)
		r(img, cx - 8, 34, 4, 2, skin_sh)
	if right_reach:
		r(img, cx + 9, 25, 5, 2, skin)
		r(img, cx + 13, 24, 3, 3, skin)
	elif arms == "hold" or arms == "table":
		r(img, cx + 7, 27, 2, 5, skin)
		r(img, cx + 3, 31, 5, 2, skin)
	elif arms == "think":
		r(img, cx + 7, 23, 2, 4, skin)
		r(img, cx + 3, 19, 5, 3, skin)           # มือเท้าคาง
	elif arms == "fingers":
		r(img, cx + 7, 23, 2, 4, skin)
		r(img, cx + 8, 17, 4, 6, skin)           # ยกมือนับนิ้ว
		p(img, cx + 8, 16, skin); p(img, cx + 10, 16, skin)
	else:
		r(img, cx + 7, 27, 2, 7, skin)
		r(img, cx + 4, 34, 4, 2, skin_sh)


# ============================================================
# ของประกอบฉาก
# ============================================================
static func paper(kind: String = "flat") -> ImageTexture:
	return cached("paper_" + kind, func():
		var img: Image
		match kind:
			"half":
				img = blank(9, 7); r(img, 1, 1, 7, 5, WHITE); r(img, 1, 5, 7, 1, WHITE_SH)
			"quarter":
				img = blank(6, 7); r(img, 1, 1, 4, 5, WHITE); r(img, 1, 5, 4, 1, WHITE_SH)
			"card":
				img = blank(16, 11); r(img, 1, 1, 14, 9, Color("fdfcf8"))
				r(img, 3, 4, 10, 2, Color("20364a"))
			"write":
				img = blank(9, 11); r(img, 1, 1, 7, 9, WHITE)
				r(img, 2, 3, 5, 1, Color("5b6b78")); r(img, 2, 5, 4, 1, Color("5b6b78"))
			"penta":
				img = blank(11, 11); r(img, 1, 1, 9, 9, Color("fdfcf8"))
				line(img, 2, 5, 4, 3, OUT); line(img, 4, 3, 6, 5, OUT); line(img, 6, 5, 5, 8, OUT); line(img, 5, 8, 3, 8, OUT); line(img, 3, 8, 2, 5, OUT)
				line(img, 5, 5, 7, 3, OUT); line(img, 7, 3, 9, 5, OUT); line(img, 9, 5, 8, 8, OUT); line(img, 8, 8, 6, 8, OUT)
			_:
				img = blank(9, 11); r(img, 1, 1, 7, 9, WHITE); r(img, 7, 1, 1, 9, WHITE_SH)
		return outline(img))

static func pencil() -> ImageTexture:
	return cached("pencil", func():
		var img := blank(16, 5)
		r(img, 3, 1, 10, 3, Color("e8b84b"))
		r(img, 3, 1, 10, 1, Color("f4d27a"))
		r(img, 1, 2, 2, 1, Color("f0d2a8")); p(img, 0, 2, Color("3a3a3a"))
		r(img, 13, 1, 2, 3, Color("e98b96"))
		return outline(img))

static func watch() -> ImageTexture:
	return cached("watch", func():
		var img := blank(10, 14)
		r(img, 3, 0, 4, 3, Color("5b6b78")); r(img, 3, 11, 4, 3, Color("5b6b78"))
		ell(img, 5, 7, 4.5, 4.5, Color("8f9fac"))
		ell(img, 5, 7, 3.3, 3.3, WHITE)
		line(img, 5, 7, 5, 5, Color("39536a")); line(img, 5, 7, 7, 8, Color("39536a"))
		return outline(img))

static func think_bubble(q: bool = false) -> ImageTexture:
	return cached("think_%s" % q, func():
		var img := blank(18, 14)
		ell(img, 10, 6, 7.5, 5.5, WHITE)
		ell(img, 3, 12, 1.6, 1.6, WHITE)
		ell(img, 5.5, 10.5, 1.2, 1.2, WHITE)
		if q:
			var c := Color("c0761c")
			r(img, 8, 2, 4, 1, c); p(img, 12, 3, c); p(img, 12, 4, c); r(img, 10, 5, 2, 1, c); p(img, 10, 6, c); p(img, 10, 8, c)
		else:
			for i in 3:
				r(img, 6 + i * 3, 6, 2, 2, Color("5b7085"))
		return outline(img))

static func calendar_icon() -> ImageTexture:
	return cached("cal_icon", func():
		var img := blank(18, 16)
		r(img, 1, 2, 16, 13, WHITE)
		r(img, 1, 2, 16, 4, Color("d8556b"))
		r(img, 4, 0, 2, 3, Color("7b8a99")); r(img, 12, 0, 2, 3, Color("7b8a99"))
		for yy in 3:
			for xx in 5:
				p(img, 3 + xx * 3, 8 + yy * 2, Color("9aa8b4"))
		r(img, 9, 11, 3, 2, Color("d8556b"))
		return outline(img))


# ============================================================
# ไอคอนอุปกรณ์ 16×16 (หน้าหยิบอุปกรณ์)
# ============================================================
static func kit_icon(k: String) -> ImageTexture:
	return cached("kit_" + k, func(): return _kit_img(k))

static func _kit_img(k: String) -> Image:
	var img := blank(16, 16)
	match k:
		"form":
			r(img, 3, 2, 10, 13, Color("9b7653")); r(img, 4, 3, 8, 11, Color("fdfcf8")); r(img, 6, 1, 4, 3, Color("7c8a96"))
			for i in 4:
				r(img, 5, 6 + i * 2, 6, 1, Color("9aa8b4"))
		"a4":
			r(img, 3, 1, 10, 14, WHITE); r(img, 12, 1, 1, 14, WHITE_SH)
		"x_fold":
			r(img, 3, 1, 10, 14, WHITE); line(img, 3, 8, 12, 8, WHITE_SH2); r(img, 3, 1, 5, 7, WHITE_SH)
		"pencil":
			line(img, 2, 13, 12, 3, Color("e8b84b"), 2); p(img, 1, 14, Color("3a3a3a")); r(img, 12, 2, 2, 2, Color("e98b96"))
		"x_pen":
			line(img, 2, 13, 12, 3, Color("2f5fa8"), 2); p(img, 1, 14, Color("222222")); r(img, 11, 2, 3, 2, Color("dfe6ee"))
		"watch":
			r(img, 6, 0, 4, 4, Color("5b6b78")); r(img, 6, 12, 4, 4, Color("5b6b78"))
			ell(img, 8, 8, 5, 5, Color("8f9fac")); ell(img, 8, 8, 3.6, 3.6, WHITE)
			line(img, 8, 8, 8, 5, Color("39536a")); line(img, 8, 8, 10, 9, Color("39536a"))
		"x_watch":
			r(img, 6, 0, 4, 4, Color("333a44")); r(img, 6, 12, 4, 4, Color("333a44"))
			r(img, 3, 4, 10, 8, Color("333a44")); r(img, 4, 5, 8, 6, Color("86c9a3"))
			r(img, 5, 7, 2, 2, Color("24503a")); r(img, 9, 7, 2, 2, Color("24503a"))
		"card":
			r(img, 1, 3, 14, 10, Color("fdfcf8")); r(img, 3, 6, 10, 2, Color("20364a")); r(img, 4, 9, 7, 1, Color("20364a"))
		"penta":
			r(img, 1, 1, 14, 14, Color("fdfcf8"))
			line(img, 2, 7, 5, 4, OUT); line(img, 5, 4, 8, 7, OUT); line(img, 8, 7, 7, 11, OUT); line(img, 7, 11, 3, 11, OUT); line(img, 3, 11, 2, 7, OUT)
			line(img, 7, 7, 10, 4, OUT); line(img, 10, 4, 13, 7, OUT); line(img, 13, 7, 12, 11, OUT); line(img, 12, 11, 8, 11, OUT)
		"x_calc":
			r(img, 3, 1, 10, 14, Color("4a5563")); r(img, 4, 2, 8, 3, Color("b9dcc4"))
			for yy in 3:
				for xx in 3:
					r(img, 4 + xx * 3, 7 + yy * 3, 2, 2, Color("dfe6ee"))
		"x_ruler":
			line(img, 1, 12, 13, 2, Color("e7c86a"), 3)
			for i in 5:
				p(img, 3 + i * 2, 11 - i * 2, Color("7a6230"))
	return outline(img)


# ============================================================
# รูปห้าเหลี่ยมของผู้ป่วย (ข้อ 11) — วาดแบบ pixel
# ============================================================
static func penta_drawing(kind: String) -> ImageTexture:
	return cached("pd_" + kind, func():
		var img := blank(64, 36)
		r(img, 0, 0, 64, 36, Color("fdfcf8"))
		var a := [Vector2i(4, 16), Vector2i(16, 6), Vector2i(28, 16), Vector2i(24, 30), Vector2i(8, 30)]
		var off := {"good": Vector2i(16, 0), "shaky": Vector2i(16, 0), "far": Vector2i(32, 0), "corner": Vector2i(24, 3), "quad": Vector2i(16, 0)}.get(kind, Vector2i(16, 0))
		_poly(img, a, Vector2i.ZERO, kind == "shaky")
		if kind == "quad":
			_poly(img, [Vector2i(4, 16), Vector2i(16, 6), Vector2i(24, 30), Vector2i(8, 30)], off, false)
		else:
			_poly(img, a, off, kind == "shaky")
		return img)

static func _poly(img: Image, pts: Array, off: Vector2i, shaky: bool) -> void:
	var c := Color("3e3128")
	for i in pts.size():
		var a: Vector2i = pts[i] + off
		var b: Vector2i = pts[(i + 1) % pts.size()] + off
		if shaky:
			var m := (a + b) / 2 + Vector2i(1, -1)
			line(img, a.x, a.y, m.x, m.y, c)
			line(img, m.x, m.y, b.x, b.y, c)
		else:
			line(img, a.x, a.y, b.x, b.y, c)
