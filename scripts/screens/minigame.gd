extends Control
## มินิเกม — เกมสั้น ๆ ฝึกทักษะที่ใช้ใน MMSE และเป็นอีกทางหาเหรียญ
##   memory : จำให้แม่น — เปิดไพ่จับคู่อุปกรณ์ (ฝึกความจำแบบข้อ 3/5)
##   seven  : ลบเจ็ดสายฟ้า — 100 − 7 ต่อเนื่องให้ไวที่สุด (ข้อ 4)
##   kit    : จัดกระเป๋าให้ถูก — คัดอุปกรณ์ MMSE ออกจากของหลอก
## กติกาเหรียญ: Prof.MINI_RULES (scripts/profile.gd)

const GAMES := [
	{"id": "memory", "icon": "🧠", "t": "จำให้แม่น", "mmse": "ข้อ 3 · ข้อ 5 ความจำ",
	 "desc": "เปิดไพ่ทีละ 2 ใบ จับคู่อุปกรณ์ที่เหมือนกันให้ครบ 6 คู่ ภายใน 60 วินาที ยิ่งเปิดน้อยครั้งยิ่งได้เหรียญมาก", "time": 60.0},
	{"id": "seven", "icon": "🔢", "t": "ลบเจ็ดสายฟ้า", "mmse": "ข้อ 4 คิดเลขในใจ",
	 "desc": "เริ่มที่ 100 แล้วลบทีละ 7 เลือกคำตอบให้ถูกและไวที่สุดใน 45 วินาที (กดปุ่ม 1–4 บนคีย์บอร์ดได้)", "time": 45.0},
	{"id": "kit", "icon": "🧳", "t": "จัดกระเป๋าให้ถูก", "mmse": "การเตรียมอุปกรณ์",
	 "desc": "ของจะมาทีละชิ้น ตัดสินว่าต้องใส่กระเป๋าไปประเมิน MMSE หรือไม่ใช้ 12 ชิ้นใน 40 วินาที", "time": 40.0},
]
const MEM_KEYS := ["form", "a4", "pencil", "watch", "card", "penta"]
const KIT_USE := {
	"form": "ใช้บันทึกคะแนนทุกข้อ",
	"a4": "ข้อ 8 พับกระดาษ · ข้อ 10 เขียน · ข้อ 11 วาด",
	"pencil": "ข้อ 6 บอกชื่อ · ข้อ 10–11 เขียนและวาด",
	"watch": "ข้อ 6 ให้ผู้ป่วยบอกชื่อสิ่งของ",
	"card": "ข้อ 9 อ่านแล้วทำตาม",
	"penta": "ข้อ 11 แบบให้ผู้ป่วยวาดตาม",
}

var game := ""          # "" = หน้ารวม
var body: VBoxContainer
var coin_l: Label
var time_l: Label
var score_l: Label
var info_l: Label
var time_left := 0.0
var playing := false
var score := 0
var lock := false

# memory
var cards: Array = []     # [{k, b, open, done}]
var first := -1
var moves := 0
var pairs := 0
# seven
var cur_n := 100
var opts: Array = []
var opt_btns: Array = []
var q_l: Label
var wrong := 0
# kit
var deck: Array = []
var di := 0
var item_box: VBoxContainer


func _ready() -> void:
	add_child(UI.backdrop(0.6))
	var col := UI.vbox(12)
	var m := UI.margin(col, 20)
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(m)
	var top := UI.hbox(10)
	top.add_child(UI.btn("◀ เมนูเกม", func(): G.goto("lobby"), "", 13))
	top.add_child(UI.title("🎮 มินิเกม", 32, Color.WHITE))
	top.add_child(UI.spacer())
	top.add_child(UI.btn("👗 แต่งตัว & ร้านค้า", func(): G.goto("wardrobe"), "", 14))
	var cf := UI.frame("slot_on", 8)
	coin_l = UI.head("", 20, UI.INK)
	cf.add_child(coin_l)
	top.add_child(cf)
	col.add_child(top)
	body = UI.vbox(12)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(body)
	Prof.changed.connect(_coins)
	_coins()
	_hub()


func _coins() -> void:
	if is_inside_tree():
		coin_l.text = "🪙 %d" % Prof.coins()


func _g(id: String) -> Dictionary:
	for g in GAMES:
		if g.id == id:
			return g
	return {}


# ============================================================ หน้ารวม
func _hub() -> void:
	game = ""
	playing = false
	UI.clear(body)
	var sub := UI.wrap(UI.label("เกมสั้น ๆ ฝึกทักษะที่ใช้ในการประเมิน MMSE · ได้เหรียญวันละ %d รอบต่อเกม (สูงสุดรอบละ %d เหรียญ)" % [Prof.MINI_RULES.daily, Prof.MINI_RULES.max], 15, Color.WHITE, true))
	sub.add_theme_constant_override("outline_size", 5)
	sub.add_theme_color_override("font_outline_color", UI.INK)
	body.add_child(sub)
	var row := UI.hbox(14)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(row)
	for g in GAMES:
		var card := UI.frame("dialog", 18)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var v := UI.vbox(10)
		card.add_child(v)
		var ic := UI.label(g.icon, 54)
		ic.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(ic)
		var t := UI.head(g.t, 28, UI.BRAND)
		t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(t)
		var chip_row := UI.hbox(0)
		chip_row.alignment = BoxContainer.ALIGNMENT_CENTER
		chip_row.add_child(UI.chip("ฝึก " + g.mmse, UI.BRAND_SOFT, UI.BRAND, 13))
		v.add_child(chip_row)
		var d := UI.wrap(UI.label(g.desc, 15, UI.INK_2))
		d.size_flags_vertical = Control.SIZE_EXPAND_FILL
		v.add_child(d)
		var left: int = Prof.mini_left(g.id)
		v.add_child(UI.label("สถิติดีที่สุด: %s" % _best_text(g.id), 14, UI.INK, true))
		v.add_child(UI.label(("รับเหรียญได้อีก %d รอบวันนี้" % left) if left > 0 else "วันนี้รับเหรียญครบแล้ว (เล่นต่อได้ ไม่ได้เหรียญ)", 13, UI.OK if left > 0 else UI.MUTED))
		var id: String = g.id
		var b := UI.btn("▶  เล่น", func(): _start(id), "primary", 20)
		v.add_child(b)
		row.add_child(card)


func _best_text(id: String) -> String:
	var b: int = Prof.mini_best(id)
	if b <= 0:
		return "-"
	match id:
		"memory":
			return "%d คะแนน" % b
		"seven":
			return "ตอบถูก %d ข้อ" % b
		_:
			return "ถูก %d / 12 ชิ้น" % b


# ============================================================ โครงหน้าเล่น
func _start(id: String) -> void:
	game = id
	score = 0
	lock = false
	time_left = float(_g(id).time)
	UI.clear(body)
	var hud := UI.hbox(12)
	var tf := UI.frame("slot_on", 8)
	time_l = UI.head("", 22, UI.INK)
	tf.add_child(time_l)
	hud.add_child(tf)
	hud.add_child(UI.title(_g(id).icon + " " + _g(id).t, 26, UI.GOLD))
	hud.add_child(UI.spacer())
	var sf := UI.frame("dialog", 8)
	score_l = UI.head("", 20, UI.INK)
	sf.add_child(score_l)
	hud.add_child(sf)
	hud.add_child(UI.btn("ยอมแพ้", func(): _end(), "", 13))
	body.add_child(hud)
	var area := UI.frame("dialog", 18)
	area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var av := UI.vbox(12)
	av.alignment = BoxContainer.ALIGNMENT_CENTER
	area.add_child(av)
	body.add_child(area)
	info_l = UI.wrap(UI.label("", 16, UI.INK_2))
	info_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	match id:
		"memory":
			_mem_build(av)
		"seven":
			_seven_build(av)
		"kit":
			_kit_build(av)
	av.add_child(info_l)
	playing = true
	S.play("open")
	_hud()


func _process(delta: float) -> void:
	if not playing:
		return
	time_left -= delta
	if time_left <= 0.0:
		time_left = 0.0
		_hud()
		_end()
		return
	_hud()


func _hud() -> void:
	if time_l == null or not is_instance_valid(time_l):
		return
	time_l.text = "⏱ %d" % int(ceil(time_left))
	time_l.add_theme_color_override("font_color", Color("d13b3b") if time_left <= 10.0 else UI.INK)
	match game:
		"memory":
			score_l.text = "คู่ %d / 6 · เปิด %d ครั้ง" % [pairs, moves]
		"seven":
			score_l.text = "ถูก %d · ผิด %d" % [score, wrong]
		"kit":
			score_l.text = "ชิ้นที่ %d / 12 · ถูก %d" % [mini(di + 1, 12), score]


# ============================================================ 1) จำให้แม่น
func _mem_build(av: VBoxContainer) -> void:
	cards.clear()
	first = -1
	moves = 0
	pairs = 0
	var ks: Array = MEM_KEYS + MEM_KEYS
	ks.shuffle()
	var grid := GridContainer.new()
	grid.columns = 6
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	var c := CenterContainer.new()
	c.add_child(grid)
	av.add_child(c)
	for i in ks.size():
		var b := UI.btn("?", _flip.bind(i), "primary", 40)
		b.custom_minimum_size = Vector2(120, 120)
		b.expand_icon = true
		b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		grid.add_child(b)
		cards.append({"k": ks[i], "b": b, "open": false, "done": false})
	info_l.text = "จำตำแหน่งให้ดี — เปิดไพ่ 2 ใบ ถ้าเป็นอุปกรณ์เดียวกันจะค้างไว้"


func _show_card(i: int, open: bool) -> void:
	var c: Dictionary = cards[i]
	c.open = open
	var b: Button = c.b
	if open:
		b.text = ""
		b.icon = Px.kit_icon(c.k)
		b.add_theme_constant_override("icon_max_width", 72)
	else:
		b.text = "?"
		b.icon = null


func _flip(i: int) -> void:
	if not playing or lock or game != "memory":
		return
	var c: Dictionary = cards[i]
	if c.done or c.open:
		return
	_show_card(i, true)
	S.play("blip")
	if first < 0:
		first = i
		return
	moves += 1
	var a: Dictionary = cards[first]
	if a.k == c.k:
		a.done = true
		c.done = true
		a.b.disabled = true
		c.b.disabled = true
		pairs += 1
		S.play("star")
		info_l.text = "✔ คู่ “%s”" % _kit_name(c.k)
		first = -1
		_hud()
		if pairs >= 6:
			_end()
		return
	var f := first
	first = -1
	lock = true
	S.play("error")
	_hud()
	await get_tree().create_timer(0.7).timeout
	if not is_inside_tree() or game != "memory":
		return
	_show_card(f, false)
	_show_card(i, false)
	lock = false


func _kit_name(k: String) -> String:
	for it in D.KIT:
		if it.k == k:
			return it.t
	return k


# ============================================================ 2) ลบเจ็ดสายฟ้า
func _seven_build(av: VBoxContainer) -> void:
	cur_n = 100
	wrong = 0
	q_l = UI.title("", 64, Color.WHITE)
	q_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	av.add_child(q_l)
	var g := GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 16)
	g.add_theme_constant_override("v_separation", 16)
	var c := CenterContainer.new()
	c.add_child(g)
	av.add_child(c)
	opt_btns.clear()
	for i in 4:
		var b := UI.btn("", _answer.bind(i), "primary", 34)
		b.custom_minimum_size = Vector2(300, 84)
		g.add_child(b)
		opt_btns.append(b)
	_seven_next()


func _seven_next() -> void:
	if cur_n < 7:
		cur_n = 60 + randi() % 61   # วนใหม่: สุ่มเลขเริ่ม 60–120
		info_l.text = "ลบจนเหลือน้อยกว่า 7 แล้ว — เริ่มใหม่จาก %d" % cur_n
	var right := cur_n - 7
	var pool := [right + 1, right - 1, right + 10, right - 10, cur_n - 6, cur_n - 8, right + 2]
	var seen := {right: true}
	opts = [right]
	pool.shuffle()
	for x in pool:
		if opts.size() >= 4:
			break
		if x >= 0 and not seen.has(x):
			seen[x] = true
			opts.append(x)
	opts.shuffle()
	q_l.text = "%d − 7 = ?" % cur_n
	for i in 4:
		opt_btns[i].text = "%d ▸ %d" % [i + 1, opts[i]]


func _answer(i: int) -> void:
	if not playing or game != "seven":
		return
	var right := cur_n - 7
	if int(opts[i]) == right:
		score += 1
		S.play("star")
		info_l.text = "✔ %d − 7 = %d" % [cur_n, right]
	else:
		wrong += 1
		S.play("error")
		info_l.text = "✘ %d − 7 = %d (ไม่ใช่ %d) — ไปต่อจาก %d" % [cur_n, right, opts[i], right]
	cur_n = right
	_seven_next()
	_hud()


func _unhandled_key_input(e: InputEvent) -> void:
	if game == "seven" and playing and e.is_pressed() and not e.is_echo():
		var k: int = e.keycode
		if k >= KEY_1 and k <= KEY_4:
			_answer(k - KEY_1)
		elif k >= KEY_KP_1 and k <= KEY_KP_4:
			_answer(k - KEY_KP_1)
	elif game == "kit" and playing and e.is_pressed() and not e.is_echo():
		if e.keycode == KEY_LEFT:
			_pack(true)
		elif e.keycode == KEY_RIGHT:
			_pack(false)


# ============================================================ 3) จัดกระเป๋าให้ถูก
func _kit_build(av: VBoxContainer) -> void:
	var good := D.KIT.filter(func(x): return x.ok)
	var bad := D.KIT.filter(func(x): return not x.ok)
	good.shuffle()
	bad.shuffle()
	deck = good.slice(0, 6) + bad.slice(0, 5)
	deck.append(G.pick(good))
	deck.shuffle()
	di = 0
	item_box = UI.vbox(8)
	item_box.alignment = BoxContainer.ALIGNMENT_CENTER
	av.add_child(item_box)
	var h := UI.hbox(24)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	var yes := UI.btn("✔  ใส่กระเป๋า  (←)", func(): _pack(true), "ok", 26)
	yes.custom_minimum_size = Vector2(320, 80)
	var no := UI.btn("✘  ไม่ใช้  (→)", func(): _pack(false), "warn", 26)
	no.custom_minimum_size = Vector2(320, 80)
	h.add_child(yes)
	h.add_child(no)
	av.add_child(h)
	_kit_show()
	info_l.text = "อุปกรณ์ที่แบบประเมินกำหนดเท่านั้นที่ต้องใส่กระเป๋า"


func _kit_show() -> void:
	UI.clear(item_box)
	var it: Dictionary = deck[di]
	var c := CenterContainer.new()
	var f := UI.frame("slot", 10)
	f.add_child(UI.pix(Px.kit_icon(it.k), 8.0))
	c.add_child(f)
	item_box.add_child(c)
	var t := UI.head(it.t, 30, UI.INK)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	item_box.add_child(t)


func _pack(put: bool) -> void:
	if not playing or game != "kit" or di >= deck.size():
		return
	var it: Dictionary = deck[di]
	var ok: bool = put == bool(it.ok)
	if ok:
		score += 1
		S.play("star")
		info_l.text = "✔ " + (("%s — %s" % [it.t, KIT_USE.get(it.k, "")]) if it.ok else ("%s — %s" % [it.t, it.why]))
	else:
		S.play("error")
		info_l.text = "✘ " + (("%s ต้องใช้! — %s" % [it.t, KIT_USE.get(it.k, "")]) if it.ok else ("%s ไม่ต้องใช้ — %s" % [it.t, it.why]))
	di += 1
	_hud()
	if di >= deck.size():
		_end()
		return
	_kit_show()


# ============================================================ จบเกม
## คะแนน 0–100 สำหรับคิดเหรียญ + ค่าที่เก็บเป็นสถิติดีที่สุด
func _result() -> Dictionary:
	match game:
		"memory":
			var pts := 0
			if pairs >= 6:
				pts = clampi(100 - (moves - 6) * 5, 30, 100) + int(time_left)   # โบนัสเวลาที่เหลือ
			else:
				pts = pairs * 8
			return {"pct": clampf(pts / 100.0, 0.0, 1.0), "best": pts,
				"line": ("จับคู่ครบ 6 คู่ เปิด %d ครั้ง เหลือเวลา %d วินาที → %d คะแนน" % [moves, int(time_left), pts]) if pairs >= 6 else ("จับคู่ได้ %d / 6 คู่ → %d คะแนน" % [pairs, pts])}
		"seven":
			var net := maxi(score - wrong, 0)
			return {"pct": clampf(net / 12.0, 0.0, 1.0), "best": score,
				"line": "ตอบถูก %d ข้อ ผิด %d ข้อ" % [score, wrong]}
		_:
			return {"pct": clampf((score - 6) / 6.0, 0.0, 1.0), "best": score,
				"line": "คัดถูก %d จาก 12 ชิ้น" % score}


func _end() -> void:
	if not playing:
		return
	playing = false
	var r := _result()
	var id := game
	var prev: int = Prof.mini_best(id)
	var earned: int = Prof.mini_end(id, float(r.pct), int(r.best))
	UI.clear(body)
	var c := CenterContainer.new()
	c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var f := UI.frame("dialog", 26)
	f.custom_minimum_size = Vector2(620, 0)
	var v := UI.vbox(12)
	f.add_child(v)
	c.add_child(f)
	body.add_child(c)
	var t := UI.head(_g(id).icon + "  " + ("หมดเวลา!" if time_left <= 0.0 else "จบเกม!"), 34, UI.BRAND)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var l := UI.wrap(UI.label(r.line, 20, UI.INK, true))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(l)
	if int(r.best) > prev and prev > 0:
		var nb := UI.label("🎉 ทำสถิติใหม่! (เดิม %s)" % str(prev), 17, UI.OK, true)
		nb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(nb)
	var cl: Label
	if earned > 0:
		cl = UI.label("+%d 🪙  (รวม %d เหรียญ)" % [earned, Prof.coins()], 24, Color("c07a00"), true)
		S.play("ok")
	elif Prof.mini_left(id) <= 0 and earned == 0:
		cl = UI.label("วันนี้รับเหรียญจากเกมนี้ครบแล้ว — พรุ่งนี้มาใหม่นะ", 16, UI.MUTED)
	else:
		cl = UI.label("ยังไม่ได้เหรียญรอบนี้ — ลองอีกครั้ง!", 16, UI.MUTED)
	cl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(cl)
	if id == "seven":
		var tip := UI.wrap(UI.label("ใน MMSE ข้อ 4 ผู้ป่วยลบ 7 ต่อเนื่อง 5 ครั้ง (93 · 86 · 79 · 72 · 65) — ถ้าลบพลาด ให้นับต่อจากตัวเลขที่ผู้ป่วยตอบ", 14, UI.INK_2))
		tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(tip)
	var h := UI.hbox(12)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_child(UI.btn("↻ เล่นอีกครั้ง", func(): _start(id), "primary", 18))
	h.add_child(UI.btn("รวมมินิเกม", _hub, "", 18))
	h.add_child(UI.btn("◀ เมนูเกม", func(): G.goto("lobby"), "", 18))
	v.add_child(h)
