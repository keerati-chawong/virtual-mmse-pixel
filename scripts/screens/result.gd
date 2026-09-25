extends Control
## หน้าสรุปผล — ใช้ร่วมกันทั้งรอบเต็มและการฝึกทีละข้อ

class Ring extends Control:
	var given := 0
	var max_ := 1
	var shown := 0.0
	func _ready() -> void:
		custom_minimum_size = Vector2(150, 150)
		create_tween().tween_property(self, "shown", float(given) / maxf(max_, 1), 0.9).set_delay(0.15)
	func _process(_d: float) -> void:
		queue_redraw()
	func _draw() -> void:
		var c := size * 0.5
		var r := minf(size.x, size.y) * 0.5 - 12
		# วงแหวนแบบพิกเซล: วาดเป็นช่องสี่เหลี่ยมเล็ก ๆ รอบวง
		var n := 48
		for i in n:
			var a := -PI / 2 + TAU * i / n
			var p := c + Vector2(cos(a), sin(a)) * r
			var on := float(i) / n < shown
			var col := (UI.OK if given == max_ else UI.BRAND) if on else Color("d6e4ee")
			draw_rect(Rect2(p - Vector2(6, 6), Vector2(12, 12)), col)
		var f := UI.font_head
		var s := str(given)
		var fs := 44
		var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string(f, c + Vector2(-w / 2, 14), s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, UI.INK)


func _ready() -> void:
	var run: Dictionary = G.run
	var ids: Array = run.queue
	var t := G.totals()
	var full: bool = run.full
	var ek := G.patient_edu()
	var cut := D.cut_of(ek)
	var v_given := G.verdict_of(t.given, ek)
	var v_truth := G.verdict_of(t.truth, ek)

	add_child(UI.backdrop(0.72))
	var col := UI.vbox(14)
	var sc := UI.scroll(UI.margin(col, 22))
	sc.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(sc)

	# ---- แบนเนอร์จบด่าน + ดาว ----
	var stars := G.stars_for(t.miss, full)
	var key: String = "full" if full else ids[0]
	var improved := G.save_stars(key, stars)
	var ban := UI.vbox(0)
	ban.alignment = BoxContainer.ALIGNMENT_CENTER
	var bt := UI.title("ASSESSMENT COMPLETE!" if full else "STAGE CLEAR!", 40, UI.GOLD)
	bt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ban.add_child(bt)
	var sr := UI.hbox(14)
	sr.alignment = BoxContainer.ALIGNMENT_CENTER
	for i in 3:
		var st := UI.title("★", 64, UI.GOLD if i < stars else Color("3a4d66"))
		st.pivot_offset = Vector2(24, 40)
		st.scale = Vector2.ZERO
		sr.add_child(st)
		var tw := st.create_tween()
		tw.tween_interval(0.35 + i * 0.3)
		tw.tween_callback(func():
			if i < stars:
				S.play("star", 1.0 + i * 0.15))
		tw.tween_property(st, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK)
	ban.add_child(sr)
	var cap := UI.title(["", "บันทึกคลาดเคลื่อนหลายจุด — ลองใหม่อีกครั้ง!", "เกือบสมบูรณ์! พลาดเล็กน้อย", "สมบูรณ์แบบ! บันทึกตรงทุกจุด"][stars] + ("   ✦ สถิติใหม่!" if improved else ""), 18, Color.WHITE)
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ban.add_child(cap)
	col.add_child(ban)

	# ---- หัวสรุป ----
	var top := UI.panel(UI.SURFACE, UI.INK, 18)
	var th := UI.hbox(20)
	top.add_child(th)
	var ring := Ring.new()
	ring.given = t.given
	ring.max_ = t.max
	th.add_child(ring)
	var tv := UI.vbox(6)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.add_child(UI.label("ผลการประเมิน · Scenario %d — %s อายุ %d ปี" % [G.scn().no, G.scn().name, G.scn().age], 12, UI.MUTED, true))
	var p0 := D.part_of(ids[0])
	tv.add_child(UI.head("สรุปผลการประเมิน MMSE" if full else "สรุปผล ข้อ %d %s" % [p0.n, p0.title], 26))
	var lede := "ผู้ป่วยรายนี้ทำได้จริง %d / %d คะแนน · คุณบันทึกไว้ %d / %d — บันทึกคลาดเคลื่อน %d จุด" % [t.truth, t.max, t.given, t.max, t.miss]
	if full and G.is_illiterate():
		lede += " (รอบนี้ข้ามข้อ 4 · 9 · 10 เพราะผู้ป่วยอ่านไม่ออกเขียนไม่ได้ คะแนนเต็มจึงเป็น %d)" % t.max
	if full:
		lede += " · แปลผลด้วยจุดตัดของกลุ่ม “%s” คือ ≤ %d คะแนน" % [cut.short, cut.cut]
	tv.add_child(UI.wrap(UI.label(lede, 14, UI.INK_2)))
	var chips := UI.flow()
	chips.add_child(UI.chip("ทำ %d ข้อ" % ids.filter(func(i): return run.results.has(i)).size()))
	chips.add_child(UI.chip("บันทึกตรง %d จุด" % (t.rows - t.miss), UI.OK_SOFT, UI.OK))
	chips.add_child(UI.chip("คลาดเคลื่อน %d จุด" % t.miss, UI.WARN_SOFT if t.miss else UI.OK_SOFT, UI.WARN if t.miss else UI.OK))
	if full:
		chips.add_child(UI.chip("ผู้ป่วย %s · จุดตัด ≤ %d" % [cut.short, cut.cut]))
		chips.add_child(_vchip("คะแนนที่บันทึก → ", v_given))
		chips.add_child(_vchip("คะแนนจริง → ", v_truth))
		if not run.interp.is_empty():
			var ok: bool = run.interp.cut == ek and run.interp.verdict == v_given
			chips.add_child(UI.chip("การแปลผลของคุณ: " + ("ถูกต้อง" if ok else "ยังไม่ถูก"), UI.OK_SOFT if ok else UI.WARN_SOFT, UI.OK if ok else UI.WARN))
	tv.add_child(chips)
	th.add_child(tv)
	th.add_child(UI.pix(Px.nurse("clip"), 2.4))
	col.add_child(top)

	# ---- ตาราง ----
	var row := UI.hbox(14)
	col.add_child(row)
	var tp := UI.panel(UI.SURFACE, UI.INK, 16)
	tp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tp.size_flags_stretch_ratio = 1.5
	var tbl := UI.vbox(4)
	tp.add_child(tbl)
	tbl.add_child(UI.head("บันทึกการประเมินทีละข้อ", 18))
	tbl.add_child(UI.label("เทียบสิ่งที่ผู้ป่วยทำหรือตอบจริงในฉาก กับคะแนนที่คุณบันทึกไว้", 12, UI.MUTED))
	for id in ids:
		if not run.results.has(id):
			continue
		var r: Dictionary = run.results[id]
		var part := D.part_of(id)
		var gh := UI.panel(UI.BRAND_SOFT, UI.BRAND_SOFT, 8, false)
		gh.add_child(UI.wrap(UI.label("ข้อ %d · %s (%s) — บันทึก %d / %d · ผู้ป่วยทำได้จริง %d / %d" % [part.n, part.title, part.en, r.given, r.max, r.truth, r.max], 13, UI.BRAND, true)))
		tbl.add_child(gh)
		for rw in r.rows:
			var h := UI.hbox(10)
			var no := UI.label("%s %s" % [rw.no, rw.label], 13, UI.INK, true)
			no.custom_minimum_size.x = 170
			no.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			h.add_child(no)
			var dv := UI.vbox(0)
			dv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			dv.add_child(UI.wrap(UI.label(D.t(rw.detail), 13, UI.INK_2)))
			dv.add_child(UI.wrap(UI.label(rw.sub, 11, UI.MUTED)))
			h.add_child(dv)
			var g := UI.head(str(rw.given), 18)
			g.custom_minimum_size.x = 26
			h.add_child(g)
			var ok: bool = rw.tag[0] == "ok"
			h.add_child(UI.chip(rw.tag[1], UI.OK_SOFT if ok else UI.WARN_SOFT, UI.OK if ok else UI.WARN, 11))
			tbl.add_child(h)
			tbl.add_child(HSeparator.new())
	row.add_child(tp)

	# ---- ข้อเสนอแนะ ----
	var fp := UI.panel(UI.SURFACE, UI.INK, 16)
	fp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var fv := UI.vbox(8)
	fp.add_child(fv)
	fv.add_child(UI.head("ข้อเสนอแนะ", 18))
	var fbs := []
	for id in ids:
		if run.results.has(id):
			fbs.append_array(run.results[id].fb)
	if full and not run.interp.is_empty():
		var chose := D.cut_of(run.interp.cut)
		if run.interp.cut == ek:
			fbs.append(G.fb("good", "แปลผล — เลือกเกณฑ์ตรงกับระดับการศึกษาของผู้ป่วย", "ผู้ป่วยรายนี้ %s จึงใช้จุดตัด ≤ %d คะแนน · จุดตัดของ MMSE ฉบับภาษาไทยผูกกับระดับการศึกษาเสมอ เพราะการศึกษามีผลต่อคะแนนโดยตรง ถ้าใช้จุดตัดเดียวกับทุกคนจะแปลผลผู้สูงอายุที่เรียนน้อยว่าผิดปกติเกินจริง" % [cut.short, cut.cut]))
		else:
			fbs.append(G.fb("tip", "แปลผล — ใช้เกณฑ์ผิดกลุ่ม", "คุณเลือกเกณฑ์ของ “%s” (จุดตัด ≤ %d) แต่ผู้ป่วยรายนี้คือ “%s” ซึ่งต้องใช้จุดตัด ≤ %d คะแนน การหยิบจุดตัดผิดกลุ่มทำให้ผลการคัดกรองผิดไปทั้งราย" % [chose.t, chose.cut, cut.t, cut.cut],
				"จำสั้น ๆ: ไม่ได้เรียนหนังสือ ≤ 14 · จบประถมศึกษา ≤ 17 · สูงกว่าประถมศึกษา ≤ 22"))
		if run.interp.verdict == v_given:
			fbs.append(G.fb("good", "แปลผล — สรุปผลตรงกับคะแนนที่บันทึกไว้", "คะแนนที่คุณบันทึกคือ %d / %d เทียบกับจุดตัด ≤ %d จึงแปลผลว่า “%s” ตรงกับที่คุณเลือก" % [t.given, t.max, cut.cut, D.VERDICT_T[v_given]]))
		else:
			fbs.append(G.fb("tip", "แปลผล — สรุปผลไม่ตรงกับคะแนนที่บันทึกไว้", "คุณเลือก “%s” แต่คะแนนที่บันทึกไว้คือ %d / %d เทียบกับจุดตัด ≤ %d ต้องแปลผลว่า “%s”" % [D.VERDICT_T[run.interp.verdict], t.given, t.max, cut.cut, D.VERDICT_T[v_given]],
				"วิธีคิด: คะแนน ≤ จุดตัด = สงสัยภาวะสมองเสื่อม · คะแนนมากกว่าจุดตัด = ยังไม่สงสัย"))
		if v_truth != v_given:
			fbs.append(G.fb("tip", "การบันทึกคะแนนคลาดเคลื่อนทำให้ผลการแปลเปลี่ยนไป", "ผู้ป่วยทำได้จริง %d / %d ซึ่งแปลผลว่า “%s” แต่คะแนนที่คุณบันทึก (%d) แปลผลว่า “%s” — คลาดเคลื่อนเพียง 1–2 คะแนนรอบจุดตัดก็เปลี่ยนการตัดสินใจส่งต่อผู้ป่วยได้ทันที" % [t.truth, t.max, D.VERDICT_T[v_truth], t.given, D.VERDICT_T[v_given]]))
		if run.interp.peeked:
			fbs.append(G.fb("info", "เปิดดูข้อมูลการศึกษาของผู้ป่วยก่อนเลือกเกณฑ์", "ในงานจริงข้อมูลนี้อยู่ในแบบบันทึกอยู่แล้ว การย้อนกลับไปดูไม่ผิด แต่ควรถามระดับการศึกษาไว้ตั้งแต่ขั้นคัดกรอง เพราะมันกำหนดทั้งชุดข้อที่ใช้และจุดตัดตอนแปลผล"))
	if full:
		fbs.append(G.fb("info", "การแปลผลคะแนนรวม", "คะแนนที่ผู้ป่วยทำได้จริงคือ %d / %d · ผู้ป่วย %s จุดตัดคือ ≤ %d คะแนน → %s · MMSE เป็นเพียงเครื่องมือคัดกรอง ไม่ใช่การวินิจฉัยภาวะสมองเสื่อม คะแนนถึงจุดตัดหมายถึงต้องส่งประเมินเพิ่มเติมต่อ ไม่ใช่สรุปว่าเป็นโรค" % [t.truth, t.max, cut.short, cut.cut, D.VERDICT_T[v_truth]]))
	if G.scenario_key == "s2":
		fbs.append(G.fb("info", "Scenario 2 — ผู้ป่วยที่มีความสับสน", "ผู้ป่วยตอบช้า บางครั้งตอบไม่ตรงคำถามหรือขอให้ถามซ้ำ ผู้ประเมินควรให้เวลา พูดช้า ชัด ถามซ้ำได้เฉพาะข้อที่เกณฑ์อนุญาต (เช่น ข้อ 1–2) และบันทึกตามที่ผู้ป่วยทำได้จริงโดยไม่ช่วยใบ้"))
	for f in fbs:
		fv.add_child(_fb_card(f))
	row.add_child(fp)

	var bh := UI.hbox(10)
	bh.add_child(UI.btn("เล่นอีกครั้ง", _again, "primary", 17))
	bh.add_child(UI.btn("กลับหน้าเมนูเกม", func(): G.goto("lobby"), "", 16))
	bh.add_child(UI.btn("กลับหน้าหลัก", func(): G.goto("home"), "ghost", 16))
	col.add_child(bh)

	G.push_history({
		"when": Time.get_datetime_string_from_system(false, true).substr(0, 16),
		"mod": ("ประเมินเต็มชุด" if full else "ข้อ %d %s" % [p0.n, p0.title]) + " · S%d" % G.scn().no,
		"max": t.max, "score": t.given, "miss": t.miss,
	})


func _vchip(prefix: String, v: String) -> Control:
	return UI.chip(prefix + D.VERDICT_T[v], UI.OK_SOFT if v == "normal" else UI.WARN_SOFT, UI.OK if v == "normal" else UI.WARN, 12)


func _fb_card(f: Dictionary) -> Control:
	var col := {"good": UI.OK, "tip": UI.WARN, "info": UI.BRAND}.get(f.kind, UI.BRAND)
	var bg := {"good": UI.OK_SOFT, "tip": UI.WARN_SOFT, "info": UI.BRAND_SOFT}.get(f.kind, UI.BRAND_SOFT)
	var p := UI.panel(bg, col, 10, false)
	var h := UI.hbox(10)
	p.add_child(h)
	var ic := UI.head({"good": "✓", "tip": "!", "info": "i"}.get(f.kind, "i"), 20, col)
	ic.custom_minimum_size.x = 18
	ic.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	h.add_child(ic)
	var v := UI.vbox(2)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(UI.wrap(UI.label(D.t(f.title), 14, UI.INK, true)))
	v.add_child(UI.wrap(UI.label(D.t(f.body), 13, UI.INK_2)))
	if f.better != "":
		v.add_child(UI.wrap(UI.label("→ " + D.t(f.better), 13, col, true)))
	h.add_child(v)
	return p


func _again() -> void:
	if G.run.full:
		G.start_full_run()
	else:
		G.start_single_run(G.run.queue[0])
