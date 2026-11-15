class_name Art
extends RefCounted
## ภาพพื้นหลังฉาก 320×180 แบบมีพื้นผิว แสงเงา และของประกอบฉาก

const W := 320
const H := 180
const FLOOR_Y := 94


static func _px(img: Image, x: int, y: int, c: Color) -> void:
	Px.p(img, x, y, c)

static func _r(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	Px.r(img, x, y, w, h, c)

static func _box(img: Image, x: int, y: int, w: int, h: int, fill: Color, edge: Color) -> void:
	_r(img, x, y, w, h, edge)
	_r(img, x + 1, y + 1, w - 2, h - 2, fill)
	_r(img, x + 1, y + 1, w - 2, 1, fill.lightened(0.2))
	_r(img, x + 1, y + h - 2, w - 2, 1, fill.darkened(0.15))


# ------------------------------------------------------------
# พื้นกระเบื้องมีมิติ
# ------------------------------------------------------------
static func _floor(img: Image, y0: int, a: Color, b: Color, tw: int, th: int) -> void:
	for y in range(y0, H, th):
		var row := (y - y0) / th
		var off := (tw / 2) * (row % 2)
		for x in range(-tw, W, tw):
			var xx := x + off
			var alt := ((xx / tw) + row) % 2 == 0
			var c := a if alt else b
			# ยิ่งใกล้กล้องยิ่งสว่างขึ้นเล็กน้อย
			c = c.lightened(float(y - y0) / (H - y0) * 0.08)
			_r(img, xx, y, tw, th, c)
			_r(img, xx, y, tw, 1, c.lightened(0.14))
			_r(img, xx, y, 1, th, c.lightened(0.08))
			_r(img, xx, y + th - 1, tw, 1, c.darkened(0.18))
	Px.noise(img, 0, y0, W, H - y0, 0.05, 0.06, 11)


static func _light_beam(img: Image, x0: int, x1: int, y0: int, spread: int, strength: float) -> void:
	for y in range(y0, H):
		var t := float(y - y0) / (H - y0)
		var l := int(lerpf(x0, x0 - spread, t))
		var rr := int(lerpf(x1, x1 - spread * 0.6, t))
		for x in range(l, rr):
			Px.blend(img, x, y, Color(1, 0.98, 0.85, strength * (1.0 - t * 0.7)))


static func _wall(img: Image, top: Color, panel: Color) -> void:
	# ฝ้า
	_r(img, 0, 0, W, 9, Color("dde9ef"))
	_r(img, 0, 8, W, 1, Color("b7c9d4"))
	# วอลเปเปอร์ลายจุด
	_r(img, 0, 9, W, 56, top)
	for y in range(12, 64, 6):
		for x in range((y / 6) % 2 * 4, W, 8):
			_px(img, x, y, top.darkened(0.06))
	# บัวกลาง + ผนังล่าง (wainscot)
	_r(img, 0, 63, W, 3, Color("eef6f9"))
	_r(img, 0, 66, W, 1, Color("8fb3c4"))
	_r(img, 0, 67, W, 24, panel)
	for x in range(0, W, 24):
		_r(img, x + 2, 70, 20, 18, panel.lightened(0.06))
		_r(img, x + 2, 87, 20, 1, panel.darkened(0.12))
		_r(img, x + 21, 70, 1, 18, panel.darkened(0.12))
	_r(img, 0, 90, W, 4, Color("5f8ea3"))
	_r(img, 0, 90, W, 1, Color("7eaabd"))


static func _ceiling_lamp(img: Image, x: int) -> void:
	_r(img, x, 9, 30, 3, Color("f7fbfd"))
	_r(img, x, 12, 30, 1, Color("c8d6df"))
	for i in 5:
		for j in range(x - i * 3, x + 30 + i * 3):
			Px.blend(img, j, 13 + i, Color(1, 1, 0.9, 0.05))


# ------------------------------------------------------------
# ห้องผู้ป่วย
# ------------------------------------------------------------
static func room() -> Image:
	var img := Px.blank(W, H)
	_wall(img, Color("cfe6ee"), Color("a6cddb"))
	_floor(img, FLOOR_Y, Color("d8c4a4"), Color("ccb592"), 20, 12)
	_ceiling_lamp(img, 130)

	# ประตู + ช่องกระจก + ป้ายห้อง
	_r(img, 5, 20, 40, 74, Color("5a4128"))
	_r(img, 8, 23, 34, 71, Color("8b6a47"))
	for y in range(24, 94, 3):
		_r(img, 9, y, 32, 1, Color("83623f"))
	_r(img, 14, 28, 22, 14, Color("5a4128"))
	_r(img, 15, 29, 20, 12, Color("9fc3d6"))
	Px.line(img, 17, 39, 23, 31, Color("d6ebf5"))
	_r(img, 12, 50, 26, 38, Color("9c7b56"))
	_r(img, 12, 50, 26, 1, Color("b08e66"))
	_r(img, 36, 62, 3, 3, Color("e0c78f"))
	_px(img, 36, 62, Color("fff2c4"))
	_box(img, 14, 14, 22, 6, Color("1d62ab"), Color("13233a"))
	# เจลล้างมือ
	_box(img, 49, 48, 7, 12, Color("f4f8fb"), Color("5b7085"))
	_r(img, 51, 51, 3, 4, Color("7ec7c0"))

	# ป้ายหอผู้ป่วย
	_r(img, 59, 19, 58, 34, Color("46596b"))
	_r(img, 60, 20, 56, 32, Color("fdfefe"))
	_r(img, 60, 20, 56, 8, Color("2f9b94"))
	_r(img, 60, 27, 56, 1, Color("237a74"))
	for i in 4:
		_r(img, 64, 32 + i * 5, 34 + (i % 2) * 12, 2, Color("c3d3dc"))
	_r(img, 106, 32, 6, 6, Color("e8b84b"))
	# นาฬิกาแขวน
	Px.ell(img, 136, 30, 8, 8, Color("33475b"))
	Px.ell(img, 136, 30, 6.5, 6.5, Color("fdfefe"))
	Px.line(img, 136, 30, 136, 25, Color("33475b"))
	Px.line(img, 136, 30, 139, 31, Color("d8556b"))
	# โปสเตอร์ล้างมือ
	_r(img, 178, 18, 26, 32, Color("5b7085"))
	_r(img, 179, 19, 24, 30, Color("fff8e8"))
	_r(img, 179, 19, 24, 7, Color("4e9e72"))
	Px.ell(img, 187, 36, 4, 5, Color("efc09b"))
	Px.ell(img, 195, 37, 4, 5, Color("efc09b"))
	for i in 5:
		_px(img, 184 + i * 3, 30, Color("7ec7c0"))

	# หน้าต่าง
	_r(img, 232, 12, 76, 60, Color("dfe8ee"))
	_r(img, 236, 16, 68, 50, Color("7f9db1"))
	for y in range(16, 40):
		_r(img, 236, y, 68, 1, Color("7f9db1").lerp(Color("a7bccb"), float(40 - y) / 24.0))
	Px.ell(img, 250, 22, 14, 5, Color("b9c9d4"))
	Px.ell(img, 285, 26, 16, 5, Color("aec0cd"))
	Px.ell(img, 248, 58, 13, 10, Color("3b7f55"))
	Px.ell(img, 268, 60, 12, 8, Color("4a9464"))
	Px.ell(img, 292, 57, 14, 11, Color("3b7f55"))
	Px.dither(img, 236, 50, 68, 16, Color("2f6b47"), 3)
	_r(img, 236, 60, 68, 6, Color("4f7d62"))
	_r(img, 268, 16, 3, 50, Color("dfe8ee"))
	_r(img, 236, 40, 68, 2, Color("dfe8ee"))
	_r(img, 229, 70, 82, 4, Color("f4f8fb"))
	_r(img, 229, 73, 82, 1, Color("b7c9d4"))
	# ม่าน
	for cx in [224, 304]:
		_r(img, cx, 9, 12, 70, Color("f2c6d0"))
		for x in range(cx + 1, cx + 12, 3):
			_r(img, x, 9, 1, 70, Color("dea5b3"))
		_r(img, cx, 76, 12, 4, Color("dea5b3"))
	_r(img, 220, 7, 100, 3, Color("8b9bab"))

	# เสาน้ำเกลือ
	_r(img, 259, 30, 2, 70, Color("9aa8b4"))
	_r(img, 252, 30, 16, 2, Color("9aa8b4"))
	_box(img, 262, 32, 7, 11, Color("e6f3fb"), Color("7c9bb3"))
	_r(img, 263, 37, 5, 5, Color("bfe0f2"))
	_r(img, 254, 100, 12, 2, Color("6f7f8f"))

	# ตู้ข้างเตียง
	_r(img, 268, 70, 40, 34, Color("8a6d4b"))
	_r(img, 270, 72, 36, 30, Color("d9c4a5"))
	_r(img, 270, 72, 36, 1, Color("ecdcc3"))
	_r(img, 270, 86, 36, 1, Color("b89c78"))
	_r(img, 285, 78, 6, 2, Color("8b6a47"))
	_r(img, 285, 93, 6, 2, Color("8b6a47"))
	Px.noise(img, 270, 72, 36, 30, 0.04, 0.2, 3)
	var cal := Px.calendar_icon().get_image()
	img.blend_rect(cal, Rect2i(Vector2i.ZERO, cal.get_size()), Vector2i(279, 55))
	_box(img, 296, 62, 6, 9, Color("f0f4f7"), Color("7b8a99"))   # แก้วน้ำ

	# เตียง
	_r(img, 238, 50, 6, 58, Color("8b9bab"))
	_r(img, 236, 48, 10, 4, Color("b7c4cf"))
	_r(img, 150, 64, 5, 44, Color("8b9bab"))
	_r(img, 148, 62, 9, 4, Color("b7c4cf"))
	_r(img, 152, 78, 88, 12, Color("f7fafc"))
	_r(img, 152, 78, 88, 1, Color.WHITE)
	_r(img, 152, 89, 88, 5, Color("c7d2dc"))
	_r(img, 152, 94, 88, 3, Color("9aa8b4"))
	_r(img, 196, 74, 44, 16, Color("7ea7d4"))
	for x in range(200, 240, 6):
		_r(img, x, 75, 1, 14, Color("6b93c0"))
	_r(img, 196, 74, 44, 2, Color("9cc0e6"))
	_r(img, 216, 68, 22, 8, Color.WHITE)
	_r(img, 216, 75, 22, 1, Color("d5dfe8"))
	_r(img, 156, 97, 3, 12, Color("6f7f8f"))
	_r(img, 232, 97, 3, 12, Color("6f7f8f"))
	Px.ell(img, 157, 110, 2, 2, Color("33475b"))
	Px.ell(img, 233, 110, 2, 2, Color("33475b"))
	# ราวข้างเตียง
	_r(img, 160, 72, 30, 2, Color("b7c4cf"))
	_r(img, 162, 72, 2, 7, Color("b7c4cf"))
	_r(img, 186, 72, 2, 7, Color("b7c4cf"))

	# ต้นไม้ในกระถาง
	_r(img, 118, 84, 14, 12, Color("b36a45"))
	_r(img, 118, 84, 14, 2, Color("cf8660"))
	Px.ell(img, 125, 74, 9, 10, Color("3f8a5a"))
	Px.ell(img, 122, 71, 5, 5, Color("58a874"))
	Px.dither(img, 118, 66, 16, 16, Color("2f6b47"), 4)
	# ถังขยะ
	_r(img, 58, 82, 11, 14, Color("7b8a99"))
	_r(img, 57, 81, 13, 2, Color("9aa8b4"))

	# แสงจากหน้าต่างตกลงพื้น
	_light_beam(img, 240, 300, FLOOR_Y, 70, 0.10)
	# เงาใต้เตียง
	for x in range(152, 242):
		for y in range(106, 112):
			Px.blend(img, x, y, Color(0.35, 0.25, 0.15, 0.16))
	return img


# ------------------------------------------------------------
# ทางเดินหน้าห้องตรวจ
# ------------------------------------------------------------
static func corridor() -> Image:
	var img := Px.blank(W, H)
	_wall(img, Color("dcebf3"), Color("b5d0dd"))
	_floor(img, FLOOR_Y, Color("b4c4d1"), Color("a5b7c6"), 24, 12)
	_ceiling_lamp(img, 40)
	_ceiling_lamp(img, 170)
	# ราวจับ
	_r(img, 0, 58, W, 3, Color("c9a77c"))
	_r(img, 0, 58, W, 1, Color("e2c49a"))
	for x in range(20, W, 60):
		_r(img, x, 61, 2, 4, Color("8b9bab"))
	# ป้ายทางเดิน
	_r(img, 139, 19, 66, 26, Color("46596b"))
	_r(img, 140, 20, 64, 24, Color.WHITE)
	_r(img, 140, 20, 64, 9, Color("2f9b94"))
	_r(img, 146, 33, 40, 2, Color("c3d3dc"))
	_r(img, 146, 38, 50, 2, Color("c3d3dc"))
	# ถังดับเพลิง
	_r(img, 214, 62, 8, 18, Color("c0392b"))
	_r(img, 214, 62, 8, 2, Color("e0584a"))
	_r(img, 216, 58, 4, 4, Color("33475b"))
	# เก้าอี้ม้านั่ง
	_r(img, 150, 76, 50, 4, Color("3f7fc4"))
	_r(img, 150, 76, 50, 1, Color("6aa0db"))
	_r(img, 150, 66, 50, 10, Color("3470ae"))
	_r(img, 154, 80, 3, 14, Color("6f7f8f"))
	_r(img, 193, 80, 3, 14, Color("6f7f8f"))
	# โต๊ะเตรียมอุปกรณ์ + ของ 6 ชิ้น
	_r(img, 8, 66, 112, 5, Color("f3f7fa"))
	_r(img, 8, 66, 112, 1, Color.WHITE)
	_r(img, 8, 71, 112, 1, Color("a9b8c4"))
	_r(img, 12, 72, 104, 18, Color("dfe8ef"))
	_r(img, 12, 80, 104, 1, Color("c3d0da"))
	_r(img, 58, 75, 12, 2, Color("9aa8b4"))
	_r(img, 58, 84, 12, 2, Color("9aa8b4"))
	_r(img, 14, 90, 4, 16, Color("8b9bab"))
	_r(img, 110, 90, 4, 16, Color("8b9bab"))
	var x := 14
	for k in ["form", "a4", "pencil", "watch", "card", "penta"]:
		var ic := Px.kit_icon(k).get_image()
		img.blend_rect(ic, Rect2i(Vector2i.ZERO, ic.get_size()), Vector2i(x, 50))
		x += 17
	# ประตูห้องตรวจ (บานประตูเป็นสไปรต์แยก)
	_r(img, 232, 24, 62, 70, Color("5a4128"))
	_r(img, 236, 28, 54, 66, Color("152432"))
	for y in range(28, 94, 4):
		_r(img, 236, y, 54, 1, Color("1b2d3d"))
	_box(img, 234, 12, 58, 11, Color("1d62ab"), Color("13233a"))
	# กระถางต้นไม้
	_r(img, 300, 80, 14, 14, Color("b36a45"))
	Px.ell(img, 307, 70, 9, 11, Color("3f8a5a"))
	Px.dither(img, 299, 60, 16, 18, Color("2f6b47"), 4)
	# เงาใต้โต๊ะ
	for xx in range(10, 118):
		for yy in range(104, 109):
			Px.blend(img, xx, yy, Color(0.1, 0.1, 0.2, 0.15))
	return img


static func door_panel() -> Image:
	var img := Px.blank(54, 66)
	_r(img, 0, 0, 54, 66, Color("a07a52"))
	for y in range(0, 66, 3):
		_r(img, 0, y, 54, 1, Color("96704a"))
	_r(img, 6, 6, 42, 22, Color("b38c61"))
	_r(img, 12, 9, 30, 14, Color("9fc3d6"))
	_r(img, 6, 34, 42, 26, Color("b38c61"))
	_r(img, 44, 33, 4, 4, Color("e0c78f"))
	return img


static func table() -> Image:
	var img := Px.blank(56, 26)
	_r(img, 0, 0, 56, 4, Color("eef3f7"))
	_r(img, 0, 0, 56, 1, Color.WHITE)
	_r(img, 0, 4, 56, 2, Color("a9b8c4"))
	_r(img, 4, 6, 3, 20, Color("8b9bab"))
	_r(img, 49, 6, 3, 20, Color("8b9bab"))
	return Px.outline(img)


static func vignette() -> Image:
	var img := Px.blank(W, H)
	for y in H:
		for x in W:
			var d := Vector2((x - W / 2.0) / (W / 2.0), (y - H / 2.0) / (H / 2.0)).length()
			var a := clampf((d - 0.85) * 0.3, 0.0, 0.12)
			if a > 0:
				img.set_pixel(x, y, Color(0.05, 0.03, 0.12, snappedf(a, 0.05)))
	return img


# ------------------------------------------------------------
# หน้า title — ภายนอกโรงพยาบาล
# ------------------------------------------------------------
static func hospital_exterior() -> Image:
	var img := Px.blank(W, H)
	for y in 120:
		var c := Color("6fa8dc").lerp(Color("d6ecf8"), float(y) / 120.0)
		_r(img, 0, y, W, 1, c)
	# dither แบ่งแถบท้องฟ้า
	for y in range(20, 110, 18):
		Px.dither(img, 0, y, W, 2, Color("6fa8dc").lerp(Color("d6ecf8"), float(y + 9) / 120.0), 2)
	Px.ell(img, 272, 26, 10, 10, Color("fff4c2"))
	Px.ell(img, 272, 26, 7, 7, Color("fffbe6"))
	# เมืองไกล ๆ
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var x := 0
	while x < W:
		var w := rng.randi_range(10, 24)
		var h := rng.randi_range(14, 38)
		_r(img, x, 104 - h, w, h, Color("a9c3d6"))
		for wy in range(104 - h + 3, 102, 5):
			for wx in range(x + 2, x + w - 2, 4):
				_px(img, wx, wy, Color("c8dbe8"))
		x += w + rng.randi_range(0, 4)
	# ตึกโรงพยาบาล
	_r(img, 70, 30, 180, 80, Color("c9d4dd"))
	_r(img, 72, 32, 176, 78, Color("f3efe6"))
	for fy in range(38, 96, 12):
		_r(img, 72, fy + 8, 176, 2, Color("3f7fc4"))
		for wx in range(78, 244, 12):
			var lit := rng.randf() < 0.35
			_r(img, wx, fy, 8, 7, Color("fff1b8") if lit else Color("7fa6c4"))
			_r(img, wx, fy, 8, 1, Color("5a7f9c"))
	_r(img, 140, 18, 40, 14, Color("f3efe6"))
	_r(img, 138, 16, 44, 3, Color("c9d4dd"))
	_r(img, 156, 20, 8, 10, Color("d8453b"))
	_r(img, 152, 23, 16, 4, Color("d8453b"))
	# ทางเข้า
	_r(img, 136, 84, 48, 26, Color("5a7f9c"))
	_r(img, 138, 86, 20, 24, Color("a8d0e6"))
	_r(img, 162, 86, 20, 24, Color("a8d0e6"))
	_r(img, 130, 80, 60, 5, Color("3f7fc4"))
	_r(img, 90, 70, 36, 10, Color("1d62ab"))   # ป้ายชื่อ รพ.
	# ต้นไม้ พื้นหญ้า ทางเดิน ถนน
	_r(img, 0, 110, W, 12, Color("6fbf73"))
	Px.dither(img, 0, 110, W, 12, Color("58a85c"), 3)
	for tx in [24, 52, 262, 296]:
		_r(img, tx - 2, 92, 4, 20, Color("7a5234"))
		Px.ell(img, tx, 86, 13, 13, Color("3f8a5a"))
		Px.ell(img, tx - 4, 82, 7, 6, Color("58a874"))
		Px.dither(img, tx - 12, 76, 24, 22, Color("2f6b47"), 4)
	_r(img, 0, 122, W, 22, Color("d9d2c3"))
	for sx in range(0, W, 16):
		_r(img, sx, 122, 1, 22, Color("c4bca9"))
	_r(img, 0, 122, W, 1, Color("efe9dc"))
	_r(img, 0, 144, W, 36, Color("5d6673"))
	for sx in range(6, W, 30):
		_r(img, sx, 161, 14, 2, Color("e8e2c9"))
	Px.noise(img, 0, 144, W, 36, 0.05, 0.08, 9)
	# เสาไฟ
	for lx in [110, 210]:
		_r(img, lx, 96, 2, 26, Color("46596b"))
		_r(img, lx - 3, 94, 8, 3, Color("46596b"))
		_r(img, lx - 2, 97, 6, 2, Color("fff1b8"))
	return img

static func cloud(w: int) -> Image:
	var img := Px.blank(w, 14)
	Px.ell(img, w * 0.3, 9, w * 0.25, 4.5, Color.WHITE)
	Px.ell(img, w * 0.55, 6.5, w * 0.25, 6, Color.WHITE)
	Px.ell(img, w * 0.78, 9.5, w * 0.2, 4, Color.WHITE)
	_r(img, int(w * 0.1), 11, int(w * 0.8), 2, Color("e3eef6"))
	return img


# ------------------------------------------------------------
# ชุมชน — ในบ้านผู้สูงอายุ (บ้านไม้ ชั้นล่าง) · ตำแหน่งหน้าต่าง/ป้าย/ปฏิทินตรงกับห้องผู้ป่วย
# ------------------------------------------------------------
static func home() -> Image:
	var img := Px.blank(W, H)
	# ผนังไม้ตีแนวตั้ง
	_r(img, 0, 0, W, 9, Color("b88a5c"))
	_r(img, 0, 8, W, 1, Color("8a6440"))
	_r(img, 0, 9, W, 85, Color("e4c49a"))
	for x in range(0, W, 8):
		_r(img, x, 9, 1, 85, Color("cfa97b"))
		_r(img, x + 1, 9, 1, 85, Color("efd4ae"))
	Px.noise(img, 0, 9, W, 85, 0.04, 0.12, 21)
	_r(img, 0, 88, W, 6, Color("a37650"))
	_r(img, 0, 88, W, 1, Color("c49668"))
	# พื้นไม้กระดาน
	_floor(img, FLOOR_Y, Color("d9b37f"), Color("cfa774"), 40, 7)
	_ceiling_lamp(img, 130)

	# ประตูไม้เปิดออกไปลานบ้าน
	_r(img, 5, 20, 40, 74, Color("6b4a2c"))
	_r(img, 8, 23, 34, 71, Color("bfe3f5"))
	_r(img, 8, 60, 34, 34, Color("7cc47f"))
	Px.dither(img, 8, 60, 34, 34, Color("5fae66"), 3)
	Px.ell(img, 22, 52, 10, 9, Color("4f9a5c"))
	_r(img, 20, 58, 3, 10, Color("7a5234"))
	_r(img, 8, 23, 6, 71, Color("8b6a47"))   # บานประตูเปิด
	for y in range(26, 92, 4):
		_r(img, 8, y, 6, 1, Color("7a5a3a"))

	# ป้ายบ้านเลขที่/ข้อมูลที่อยู่ (กรอบไม้)
	_r(img, 59, 19, 58, 34, Color("6b4a2c"))
	_r(img, 60, 20, 56, 32, Color("fdfaf2"))
	_r(img, 60, 20, 56, 8, Color("3f8a5a"))
	_r(img, 60, 27, 56, 1, Color("2f6b47"))
	for i in 4:
		_r(img, 64, 32 + i * 5, 34 + (i % 2) * 12, 2, Color("d6c9b0"))
	_r(img, 106, 32, 6, 6, Color("d8453b"))
	# นาฬิกาแขวน
	Px.ell(img, 136, 30, 8, 8, Color("6b4a2c"))
	Px.ell(img, 136, 30, 6.5, 6.5, Color("fdfefe"))
	Px.line(img, 136, 30, 136, 25, Color("33475b"))
	Px.line(img, 136, 30, 139, 31, Color("d8556b"))
	# หิ้งพระ + พวงมาลัย
	_r(img, 172, 30, 36, 3, Color("8a5a2b"))
	_r(img, 172, 33, 36, 1, Color("6b4a2c"))
	_box(img, 184, 18, 12, 12, Color("f3d36b"), Color("8a6a1e"))
	_r(img, 188, 21, 4, 7, Color("e0a93a"))
	Px.ell(img, 177, 27, 3, 3, Color("f2f2e6"))
	Px.ell(img, 203, 27, 3, 3, Color("f2f2e6"))
	# รูปครอบครัวใส่กรอบ
	_box(img, 176, 40, 14, 11, Color("bcd8e8"), Color("6b4a2c"))
	_box(img, 194, 40, 12, 11, Color("f0d9b5"), Color("6b4a2c"))

	# หน้าต่างไม้ (บานเปิด) เห็นต้นไม้และฝน
	_r(img, 232, 12, 76, 60, Color("8b6a47"))
	_r(img, 236, 16, 68, 50, Color("7f9db1"))
	for y in range(16, 40):
		_r(img, 236, y, 68, 1, Color("7f9db1").lerp(Color("a7bccb"), float(40 - y) / 24.0))
	Px.ell(img, 250, 22, 14, 5, Color("b9c9d4"))
	Px.ell(img, 285, 26, 16, 5, Color("aec0cd"))
	Px.ell(img, 248, 58, 13, 10, Color("3b7f55"))
	Px.ell(img, 268, 56, 12, 9, Color("4a9464"))
	Px.ell(img, 292, 57, 14, 11, Color("3b7f55"))
	Px.dither(img, 236, 50, 68, 16, Color("2f6b47"), 3)
	_r(img, 280, 40, 3, 26, Color("7a5234"))   # ต้นมะพร้าว
	Px.ell(img, 281, 38, 9, 3, Color("4a9464"))
	_r(img, 268, 16, 3, 50, Color("8b6a47"))
	_r(img, 229, 70, 82, 4, Color("a37650"))
	for sx in [222, 308]:
		_r(img, sx, 12, 10, 60, Color("a07a52"))
		for y in range(14, 70, 4):
			_r(img, sx + 1, y, 8, 1, Color("8b6a47"))

	# ตู้ไม้เตี้ย + ปฏิทิน
	_r(img, 268, 70, 40, 34, Color("6b4a2c"))
	_r(img, 270, 72, 36, 30, Color("b88a5c"))
	_r(img, 270, 72, 36, 1, Color("d4a878"))
	_r(img, 270, 86, 36, 1, Color("8a6440"))
	_r(img, 285, 78, 6, 2, Color("e0c78f"))
	_r(img, 285, 93, 6, 2, Color("e0c78f"))
	var cal := Px.calendar_icon().get_image()
	img.blend_rect(cal, Rect2i(Vector2i.ZERO, cal.get_size()), Vector2i(279, 55))
	_box(img, 296, 62, 6, 9, Color("f0f4f7"), Color("7b8a99"))   # แก้วน้ำ

	# แคร่ไม้ไผ่ + เสื่อ + หมอนขวาน
	_r(img, 150, 84, 92, 6, Color("c9a35a"))
	_r(img, 150, 84, 92, 1, Color("e2c27c"))
	for x in range(152, 242, 5):
		_r(img, x, 84, 1, 6, Color("a8853f"))
	_r(img, 152, 80, 88, 5, Color("e9c46a"))
	for x in range(152, 240, 4):
		_r(img, x, 80, 2, 5, Color("d9534f") if (x / 4) % 3 == 0 else Color("e9c46a"))
	_r(img, 154, 90, 4, 18, Color("8a6a3a"))
	_r(img, 234, 90, 4, 18, Color("8a6a3a"))
	_r(img, 192, 90, 4, 18, Color("8a6a3a"))
	for i in 8:
		_r(img, 222 + i, 72 + (8 - i), 1, i + 1, Color("d8453b"))
		_r(img, 222 + i, 72 + (8 - i), 1, 1, Color("f3d36b"))

	# พัดลมตั้งพื้น
	_r(img, 124, 70, 3, 24, Color("8b9bab"))
	_r(img, 119, 92, 13, 3, Color("6f7f8f"))
	Px.ell(img, 125, 64, 8, 8, Color("5f8ea3"))
	Px.ell(img, 125, 64, 6, 6, Color("bcd8e8"))
	Px.ell(img, 125, 64, 1.5, 1.5, Color("33475b"))
	# กระติบข้าว + ขันน้ำ
	_r(img, 60, 86, 8, 8, Color("c9a35a"))
	_r(img, 60, 86, 8, 2, Color("a8853f"))
	_r(img, 74, 89, 9, 5, Color("c0c8d0"))

	_light_beam(img, 240, 300, FLOOR_Y, 70, 0.10)
	for x in range(150, 244):
		for y in range(106, 111):
			Px.blend(img, x, y, Color(0.35, 0.25, 0.15, 0.16))
	return img


# ------------------------------------------------------------
# ชุมชน — ลานหน้าบ้าน (โต๊ะเตรียมอุปกรณ์ที่ศาลา อสม. · ประตูบ้านผู้สูงอายุ)
# ตำแหน่งโต๊ะ/ประตูตรงกับฉากทางเดินในโรงพยาบาล
# ------------------------------------------------------------
static func lane() -> Image:
	var img := Px.blank(W, H)
	for y in 94:
		_r(img, 0, y, W, 1, Color("8cc4ea").lerp(Color("e3f2fb"), float(y) / 94.0))
	Px.ell(img, 40, 18, 9, 9, Color("fff4c2"))
	# ทิวไม้ไกล ๆ
	for tx in range(0, W, 18):
		Px.ell(img, tx, 62, 14, 10, Color("7fb98a"))
	Px.dither(img, 0, 56, W, 20, Color("6aa877"), 3)
	# พื้นดิน + ถนนลูกรัง
	_r(img, 0, 76, W, 18, Color("8fcf7f"))
	Px.dither(img, 0, 76, W, 18, Color("76b86a"), 3)
	_floor(img, FLOOR_Y, Color("dcb98a"), Color("d3ae7e"), 32, 10)
	Px.noise(img, 0, FLOOR_Y, W, H - FLOOR_Y, 0.06, 0.12, 5)
	# ศาลา อสม. (หลังคา + โต๊ะ)
	_r(img, 2, 30, 124, 6, Color("b0503a"))
	_r(img, 6, 26, 116, 5, Color("c8654a"))
	_r(img, 6, 36, 3, 58, Color("8a6440"))
	_r(img, 118, 36, 3, 58, Color("8a6440"))
	_r(img, 8, 66, 112, 5, Color("f3e7d2"))
	_r(img, 8, 66, 112, 1, Color.WHITE)
	_r(img, 8, 71, 112, 1, Color("b89c78"))
	_r(img, 12, 72, 104, 18, Color("d9c4a5"))
	_r(img, 12, 80, 104, 1, Color("c3a984"))
	_r(img, 14, 90, 4, 16, Color("8a6440"))
	_r(img, 110, 90, 4, 16, Color("8a6440"))
	var x := 14
	for k in ["form", "a4", "pencil", "watch", "card", "penta"]:
		var ic := Px.kit_icon(k).get_image()
		img.blend_rect(ic, Rect2i(Vector2i.ZERO, ic.get_size()), Vector2i(x, 50))
		x += 17
	# ป้ายหมู่บ้าน
	_r(img, 170, 44, 3, 50, Color("6b4a2c"))
	_r(img, 139, 19, 66, 26, Color("6b4a2c"))
	_r(img, 140, 20, 64, 24, Color("fdfaf2"))
	_r(img, 140, 20, 64, 9, Color("3f8a5a"))
	_r(img, 146, 33, 40, 2, Color("d6c9b0"))
	_r(img, 146, 38, 50, 2, Color("d6c9b0"))
	# บ้านไม้ยกพื้น (ประตูเป็นสไปรต์แยก)
	_r(img, 224, 4, 96, 10, Color("b0503a"))
	_r(img, 228, 0, 88, 5, Color("c8654a"))
	_r(img, 228, 14, 92, 80, Color("c49668"))
	for xx in range(228, W, 6):
		_r(img, xx, 14, 1, 80, Color("a37650"))
	_r(img, 232, 24, 62, 70, Color("6b4a2c"))
	_r(img, 236, 28, 54, 66, Color("3a2a1c"))
	_box(img, 234, 12, 58, 11, Color("3f8a5a"), Color("2f4a33"))
	_r(img, 298, 30, 18, 16, Color("8b6a47"))
	_r(img, 300, 32, 14, 12, Color("bfe3f5"))
	# ต้นไม้ + กระถาง
	_r(img, 206, 60, 4, 34, Color("7a5234"))
	Px.ell(img, 208, 54, 13, 11, Color("3f8a5a"))
	Px.dither(img, 196, 44, 24, 20, Color("2f6b47"), 4)
	_r(img, 300, 80, 14, 14, Color("b36a45"))
	Px.ell(img, 307, 72, 8, 9, Color("4f9a5c"))
	for xx in range(10, 118):
		for yy in range(104, 109):
			Px.blend(img, xx, yy, Color(0.3, 0.2, 0.1, 0.15))
	return img
