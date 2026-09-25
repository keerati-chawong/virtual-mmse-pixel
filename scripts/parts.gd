class_name Parts
extends RefCounted
## ตรรกะสุ่มพฤติกรรมผู้ป่วย + ลำดับฉาก + feedback ของแต่ละข้อ
## ลำดับฉาก (seq) = อาร์เรย์ของขั้น {q, a, who, fx_before, fx_after} หรือ {choice: {...}}
## fx: "think", "unthink", "pencil", "watch", "hide_props", "finger", "unfinger", "chip:<text>"


# ---------- ข้อ 1 ----------
static func time_answer(item: Dictionary, opt_type: String) -> Dictionary:
	if opt_type == "leading":
		return item.lead
	var good := []
	var bad := []
	for a in item.answers:
		(good if a.ok else bad).append(a)
	# ผู้ป่วยที่สับสน (s2) บางครั้งตอบไม่ตรงคำถาม
	if G.confused_moment():
		return {"t": G.pick(D.OFFTOPIC), "ok": 0, "why": "ตอบไม่ตรงคำถาม — ผู้ป่วยสับสน ไม่ได้คะแนนข้อนี้", "off": true}
	var p := 0.78
	if item.id == "date" or item.id == "dow":
		p = 0.7
	return G.pick(good) if G.chance(p) else G.pick(bad)


# ---------- ข้อ 8 · 9 ----------
static func roll_cmd8(t: String) -> Dictionary:
	var sc := {}
	if t == "stepwise":
		sc = {"hand": "right", "fold": "half", "place": "table"}
	elif t == "short":
		sc = {"hand": G.pick(["left", "both", "right"]), "fold": "half", "place": "hold"}
	else:
		sc = {
			"hand": "right" if G.chance(0.62) else G.pick(["left", "both"]),
			"fold": "half" if G.chance(0.7) else G.pick(["quarter", "none"]),
			"place": "table" if G.chance(0.68) else G.pick(["hold", "back"]),
		}
	sc.truth = {"take": int(sc.hand == "right"), "fold": int(sc.fold == "half"), "place": int(sc.place == "table")}
	sc.said = {
		"take": {"right": "รับด้วยมือขวา", "left": "รับด้วยมือซ้าย", "both": "รับด้วยสองมือพร้อมกัน"}[sc.hand],
		"fold": {"half": "พับครึ่งด้วยมือทั้งสองข้าง", "quarter": "พับซ้ำเป็นสี่ส่วน", "none": "ไม่ได้พับ ถือแผ่ไว้"}[sc.fold],
		"place": {"table": "วางไว้บนโต๊ะ", "hold": "ถือค้างไว้ ไม่ได้วาง", "back": "ส่งกระดาษคืนให้ผู้ประเมิน"}[sc.place],
	}
	return sc

static func roll_cmd9(t: String) -> Dictionary:
	var sc := {}
	if t == "good":
		sc = {"eyes": "shut" if G.chance(0.7) else "open", "read": G.pick(["aloud", "silent"])}
	else:
		sc = {"eyes": "shut", "read": "none"}
	sc.truth = {"eyes": int(sc.eyes == "shut")}
	sc.said = {"eyes": ("หลับตาตามคำสั่ง" if sc.eyes == "shut" else "ไม่ได้หลับตา มองกระดาษเฉย ๆ") + " · " +
		{"aloud": "อ่านออกเสียง", "silent": "อ่านในใจ", "none": "ไม่ได้อ่านเอง"}[sc.read]}
	return sc

static func cmd_feedback(item: Dictionary, rec: Dictionary, out: Array) -> void:
	if item.id == "cmd8":
		var good_text: String = D.t(item.options[0].text)
		match rec.type:
			"good":
				out.append(G.fb("good", "ข้อ 8 — สั่งครบ 3 ขั้นในครั้งเดียวก่อนยื่นกระดาษ",
					"ถูกต้องตามคู่มือ MMSE ข้อนี้วัดทั้งความเข้าใจคำสั่งและความจำขณะทำงาน จึงต้องพูดคำสั่งให้จบทั้ง 3 ขั้น แล้วค่อยส่งกระดาษ ระหว่างที่ผู้ป่วยทำต้องไม่บอกซ้ำและไม่ช่วยเตือน"))
			"stepwise":
				out.append(G.fb("tip", "ข้อ 8 — บอกทีละขั้นระหว่างที่ผู้ป่วยกำลังทำ",
					"ผู้ป่วยทำได้ครบทั้ง 3 ขั้นเพราะได้รับคำใบ้ต่อเนื่อง ไม่ได้ใช้ความจำของตัวเอง คะแนนที่ได้จึงสูงเกินความจริงและนำไปแปลผลไม่ได้",
					"ควรพูดครั้งเดียวให้จบ เช่น " + good_text))
			_:
				out.append(G.fb("tip", "ข้อ 8 — คำสั่งไม่ครบ 3 ขั้น",
					"คำสั่งมาตรฐานต้องระบุครบทั้งการรับด้วยมือขวา การพับครึ่งด้วยมือทั้งสองข้าง และตำแหน่งที่จะวาง เมื่อสั่งไม่ครบ ผู้ป่วยย่อมทำไม่ครบ และคะแนนที่ได้ไม่สะท้อนความสามารถจริง",
					"ควรพูดครั้งเดียวให้จบ เช่น " + good_text))
	else:
		var good9: String = D.t(item.options[0].text)
		match rec.type:
			"good":
				out.append(G.fb("good", "ข้อ 9 — ให้ผู้ป่วยอ่านคำสั่งด้วยตัวเอง",
					"บอกชัดว่าจะอ่านออกเสียงหรืออ่านในใจก็ได้ แล้วปล่อยให้ผู้ป่วยอ่านเอง ข้อนี้จึงวัด “การอ่านและเข้าใจความหมาย” ได้จริง"))
			"sayit":
				out.append(G.fb("tip", "ข้อ 9 — ผู้ประเมินอ่านข้อความให้ผู้ป่วยฟัง",
					"เมื่อบอกว่ากระดาษเขียนว่าอะไร ข้อนี้จะกลายเป็นคำสั่งด้วยเสียงเหมือนข้อ 8 ทันที ไม่ได้วัดการอ่านอีกต่อไป ผู้ป่วยที่อ่านหนังสือไม่ออกก็จะทำได้ ทำให้คะแนนสูงเกินจริง",
					"ควรพูดว่า " + good9))
			_:
				out.append(G.fb("tip", "ข้อ 9 — สั่งด้วยปากเปล่า ไม่ได้ให้อ่านกระดาษ",
					"การบอกให้หลับตาโดยตรงคือคำสั่งด้วยเสียง ไม่ใช่ written command ข้อนี้ต้องให้ผู้ป่วยอ่านข้อความ “หลับตา” จากกระดาษแล้วทำตามเอง",
					"ควรพูดว่า " + good9))


# ---------- ข้อ 2 3 4 5 6 7 10 11 ----------
static func rows(id: String, sc: Dictionary) -> Array:
	match id:
		"place":
			return [{"k": "here", "t": "อยู่ที่ไหน + ที่นี่ชื่ออะไร"}, {"k": "floor", "t": "อยู่ชั้นไหนของอาคาร"},
				{"k": "amphoe", "t": "อำเภออะไร"}, {"k": "province", "t": "จังหวัดอะไร"}, {"k": "region", "t": "ภาคอะไร"}]
		"reg":
			return [{"k": "flower", "t": "พูดตามคำว่า “ดอกไม้”"}, {"k": "river", "t": "พูดตามคำว่า “แม่น้ำ”"},
				{"k": "train", "t": "พูดตามคำว่า “รถไฟ”"}]
		"calc":
			var r := []
			for i in 5:
				if sc.get("mode", "calc") == "spell":
					r.append({"k": "p%d" % i, "t": "ตัวที่ %d (%s)" % [i + 1, D.SPELL_TARGET[i]]})
				else:
					var ans := ""
					if sc.has("ans"):
						ans = " — ตอบ " + str(sc.ans[i])
					r.append({"k": "n%d" % i, "t": "ครั้งที่ %d%s" % [i + 1, ans]})
			return r
		"recall":
			return [{"k": "flower", "t": "ทวนได้ว่า “ดอกไม้”"}, {"k": "river", "t": "ทวนได้ว่า “แม่น้ำ”"},
				{"k": "train", "t": "ทวนได้ว่า “รถไฟ”"}]
		"name":
			return [{"k": "pencil", "t": "บอกชื่อ “ดินสอ” ได้"}, {"k": "watch", "t": "บอกชื่อ “นาฬิกา” ได้"}]
		"repeat":
			return [{"k": "say", "t": "พูดตามได้ถูกครบทั้งประโยค"}]
		"write":
			return [{"k": "sent", "t": "เขียนเป็นประโยคที่มีความหมาย"}]
		"draw":
			return [{"k": "draw", "t": "วาดได้ครบทั้งสองเงื่อนไข"}]
	return []


static func roll(id: String, t: String) -> Dictionary:
	match id:
		"place": return _roll_place(t)
		"reg": return _roll_reg(t)
		"calc": return _roll_calc(t)
		"recall": return _roll_recall(t)
		"name": return _roll_name(t)
		"repeat": return _roll_repeat(t)
		"write": return _roll_write(t)
		"draw": return _roll_draw(t)
	return {}


static func _roll_place(t: String) -> Dictionary:
	var sc := {"truth": {}, "said": {}, "seq": []}
	var right := {
		"here": D.t("อยู่โรงพยาบาล{k} ชื่อโรงพยาบาลศรีนครินทร์"),
		"floor": D.t(G.pick(["ชั้น 5 {k}", "ชั้นบน{k}"])),
		"amphoe": D.t("อำเภอเมือง{k}"),
		"province": D.t("จังหวัดขอนแก่น{k}"),
		"region": D.t(G.pick(["ภาคอีสาน{k}", "อีสานเหนือ{k}"])),
	}
	var wrong := {
		"here": D.t(G.pick(["อยู่โรงพยาบาล{k}", "อยู่บ้าน{me}ไม่ใช่เหรอ"])),
		"floor": D.t("ไม่แน่ใจ{k}"),
		"amphoe": D.t("จำไม่ได้{k}"),
		"province": D.t("จังหวัดอุดรธานี{k}"),
		"region": D.t("ภาคกลางมั้ง{k}"),
	}
	var ask := {
		"here": D.t("“ตอนนี้{c}อยู่ที่ไหนคะ แล้วที่นี่ชื่ออะไรคะ”"),
		"floor": "“ตรงนี้เป็นชั้นไหนของตึกคะ”",
		"amphoe": "“ที่นี่อยู่อำเภออะไรคะ”",
		"province": "“จังหวัดอะไรคะ”",
		"region": "“อยู่ภาคไหนของประเทศคะ”",
	}
	var cued := {"here": 1, "floor": 1, "amphoe": 1}
	for k in ["here", "floor", "amphoe", "province", "region"]:
		var ok := G.chance(0.75 if k == "province" else 0.7)
		var a: String = right[k] if ok else wrong[k]
		var q: String = ask[k]
		if t == "leading" and cued.has(k):
			ok = true
			a = D.t("ใช่{k} ตามที่คุณพยาบาลบอกเลย")
			q = "(บอกคำตอบไปในคำถาม) " + ask[k]
		if t == "half" and k == "here":
			a = D.t("อยู่โรงพยาบาล{k}")
			ok = false
			q = "“ตอนนี้อยู่ที่ไหนคะ”"
		sc.truth[k] = int(ok)
		sc.said[k] = a
		if t == "leading" and cued.has(k):
			sc.said[k] = a + " — ตอบรับตามคำตอบที่ผู้ประเมินใบ้ให้ ไม่ได้ระลึกเอง"
		if t == "half" and k == "here":
			sc.said[k] = a + " — ผู้ประเมินไม่ได้ถามว่าที่นี่ชื่ออะไร จึงไม่ครบเกณฑ์ข้อนี้"
		# ผู้ป่วยสับสน: ถามว่าอะไรนะ แล้วพยาบาลถามซ้ำ (ข้อ 2 ทวนคำถามได้)
		if not (t == "leading" and cued.has(k)) and G.confused_moment():
			sc.seq.append({"q": q, "a": D.t("หือ… ถามว่าอะไรนะ{k}")})
			q = "(ถามซ้ำช้า ๆ) " + q
		sc.seq.append({"q": q, "a": a})
	return sc


static func _roll_reg(t: String) -> Dictionary:
	var word := {"flower": "ดอกไม้", "river": "แม่น้ำ", "train": "รถไฟ"}
	var sc := {"truth": {}, "said": {}, "seq": [], "got": []}
	var all_ok := t != "good" or G.chance(0.55)
	for k in ["flower", "river", "train"]:
		var ok := all_ok or G.chance(0.72)
		sc.truth[k] = int(ok)
		if ok:
			sc.got.append(word[k])
		sc.said[k] = "พูดตามได้" if ok else "ไม่ได้พูดคำนี้"
	if sc.got.is_empty():
		sc.truth.flower = 1
		sc.got.append("ดอกไม้")
		sc.said.flower = "พูดตามได้"
	var spoken := " ".join(sc.got)
	match t:
		"onebyone":
			sc.seq = [{"q": "“ดอกไม้ … พูดตามค่ะ”", "a": "ดอกไม้"}, {"q": "“แม่น้ำ … พูดตามค่ะ”", "a": "แม่น้ำ"},
				{"q": "“รถไฟ … พูดตามค่ะ”", "a": "รถไฟ"}]
		"twice":
			sc.seq = [{"q": "“ดอกไม้ แม่น้ำ รถไฟ”", "a": "…"}, {"q": "“เอาใหม่นะคะ ดอกไม้ แม่น้ำ รถไฟ”", "a": spoken}]
		_:
			sc.seq = [{"q": "“ฟังให้ดีนะคะ — ดอกไม้ แม่น้ำ รถไฟ”", "a": "…", "who": "ผู้ป่วยกำลังฟัง"},
				{"q": "“พูดตามให้ครบทั้ง 3 อย่างค่ะ”", "a": spoken}]
	return sc


static func _roll_calc(t: String) -> Dictionary:
	var can_calc := G.chance(0.7)
	var sc := {"truth": {}, "said": {}, "mode": "calc"}
	if not can_calc and t == "good":
		sc.mode = "spell"
	elif not can_calc:
		sc.stuck = true
	if sc.mode == "spell":
		var v: Dictionary = D.SPELL_VARIANTS[0] if G.chance(0.45) else G.pick(D.SPELL_VARIANTS)
		sc.spell = v
		for j in 5:
			sc.truth["p%d" % j] = v.pos[j]
			sc.said["p%d" % j] = v.note[j]
		sc.seq = [
			{"q": D.t("“{c}คิดเลขได้มั้ยคะ”"), "a": D.t("คิดเลขไม่ค่อยเป็น{k}")},
			{"q": "“งั้นเปลี่ยนเป็นสะกดคำนะคะ — มะนาว สะกดว่า ม-ะ-น-า-ว”", "a": "…", "who": "ผู้ป่วยกำลังฟัง"},
			{"q": "“ทีนี้ช่วยสะกดคำว่า มะนาว กลับหลังให้ฟังหน่อยค่ะ”", "a": v.out},
		]
		return sc
	if sc.get("stuck", false):
		sc.ans = ["–", "–", "–", "–", "–"]
		for s in 5:
			sc.truth["n%d" % s] = 0
			sc.said["n%d" % s] = "ไม่ได้ตอบ — ผู้ป่วยบอกว่าคิดเลขไม่เป็น และผู้ประเมินไม่ได้เปลี่ยนไปใช้การสะกดคำ"
		return sc
	sc.fingers = randf() < 0.25
	if t == "hint":
		sc.ans = [93, 86, 79, 72, 65]
	else:
		sc.ans = (G.pick(D.CALC_GOOD) if G.chance(0.4) else G.pick(D.CALC_MIXED)).duplicate()
	var prev := 100
	for i in 5:
		var v: int = sc.ans[i]
		var ok := int(v == prev - 7)
		if sc.fingers:
			ok = 0
		sc.truth["n%d" % i] = ok
		var note := ""
		if sc.fingers:
			note = " · นับนิ้วช่วย จึงไม่นับคะแนน"
		elif not ok:
			note = " · ไม่เท่ากับ %d" % (prev - 7)
		sc.said["n%d" % i] = "ตอบ %d (ก่อนหน้านี้ %d)%s" % [v, prev, note]
		prev = v
	return sc


static func _roll_recall(t: String) -> Dictionary:
	var word := {"flower": "ดอกไม้", "river": "แม่น้ำ", "train": "รถไฟ"}
	var known: Array = G.run.get("reg_words", [])
	if known.is_empty():
		known = ["ดอกไม้", "แม่น้ำ", "รถไฟ"]
	var sc := {"truth": {}, "said": {}, "seq": [], "got": []}
	for k in ["flower", "river", "train"]:
		var heard := known.has(word[k])
		var ok := false
		if t == "yn":
			ok = true
		elif t == "cue":
			ok = true if k == "flower" else (heard and G.chance(0.7))
		else:
			ok = heard and G.chance(0.62)
		sc.truth[k] = int(ok)
		if ok:
			sc.got.append(word[k])
		var extra := ""
		if t == "yn":
			extra = " (ตอบรับตามที่ผู้ประเมินบอกให้)"
		elif t == "cue" and k == "flower":
			extra = " (ผู้ประเมินใบ้คำนี้ให้)"
		sc.said[k] = ("ทวนได้" + extra) if ok else ("นึกไม่ออก" if heard else "ข้อ 3 ผู้ป่วยไม่ได้พูดคำนี้ไว้ตั้งแต่แรก")
	# อัปเดต 25-9-2569: ผู้ป่วยตอบเรียงหรือไม่เรียงก็ได้ — ได้คะแนนหมด
	var order: Array = sc.got.duplicate()
	if t != "yn" and order.size() > 1 and randf() < 0.6:
		var tries := 0
		while order == sc.got and tries < 6:
			order.shuffle()
			tries += 1
	sc.unordered = order != sc.got
	if sc.unordered:
		for k in ["flower", "river", "train"]:
			if sc.truth[k] == 1:
				sc.said[k] += " · ตอบไม่เรียงลำดับ ก็ยังได้คะแนน"
	var spoken := " … ".join(order) if order.size() else D.t("นึกไม่ออกเลย{k}")
	if t == "yn":
		spoken = D.t("ใช่{k} ดอกไม้ แม่น้ำ รถไฟ")
	sc.spoken = spoken
	sc.seq = [
		{"q": "“เมื่อซักครู่ที่ให้จำของสามอย่าง จำได้มั้ยคะ”", "a": "…", "who": "ผู้ป่วยกำลังนึก", "fx_after": "think"},
		{"q": "“มีอะไรบ้างคะ”", "a": spoken, "fx_before": "unthink"},
	]
	return sc


static func _roll_name(t: String) -> Dictionary:
	var sc := {"truth": {}, "said": {}}
	if t == "leading":
		sc.truth = {"pencil": 1, "watch": 1}
		sc.said = {"pencil": D.t("ใช่{k} ดินสอ (ตอบรับตามคำถามชี้นำ)"), "watch": D.t("ใช่{k} นาฬิกา (ตอบรับตามคำถามชี้นำ)")}
		sc.p_ans = D.t("ใช่{k} ดินสอ")
		sc.w_ans = D.t("ใช่{k} นาฬิกา")
	else:
		var p_ans: String = D.t("ดินสอ{k}") if G.chance(0.8) else D.t(G.pick(["ดินสอไม้{k}", "ปากกา{k}"]))
		var w_ans: String = D.t(G.pick(["นาฬิกา{k}", "นาฬิกาข้อมือ{k}"])) if G.chance(0.72) else D.t(G.pick(["ของใส่ข้อมือ{k}", "ไม่รู้{k}"]))
		sc.truth.pencil = int(p_ans.begins_with("ดินสอ"))
		sc.truth.watch = int(w_ans.begins_with("นาฬิกา"))
		var touch := " · ผู้ประเมินให้ผู้ป่วยจับของด้วย" if t == "touch" else ""
		sc.said.pencil = "ตอบว่า “" + p_ans + "”" + touch
		sc.said.watch = "ตอบว่า “" + w_ans + "”" + touch
		sc.p_ans = p_ans
		sc.w_ans = w_ans
	sc.seq = [
		{"q": "ยื่นดินสอไม้ให้ผู้ป่วยดู — “สิ่งนี้เรียกว่าอะไรคะ”", "a": sc.p_ans, "fx_before": "pencil"},
		{"q": "ชี้นาฬิกาข้อมือให้ดู — “แล้วอันนี้ล่ะคะ”", "a": sc.w_ans, "fx_before": "watch"},
	]
	return sc


static func _roll_repeat(t: String) -> Dictionary:
	var full := "ใคร ใคร่ ขาย ไก่ ไข่"
	var out: String
	if t == "good":
		out = full if G.chance(0.55) else G.pick(["ใคร ใคร ขาย ไก่ ไข่", "ใคร ใคร่ ขาย ไก่", "ใคร ใคร่ ขาย ไข่ ไก่"])
	else:
		out = G.pick([full, full, "ใคร ใคร ขาย ไก่ ไข่"])
	var ok := int(out == full)
	return {
		"out": out, "truth": {"say": ok},
		"said": {"say": "ผู้ป่วยพูดว่า “" + out + "” — " + ("ถูกครบทุกคำ" if ok else "ผิดหรือไม่ครบอย่างน้อย 1 คำ จึงไม่ได้คะแนนเลย")},
		"seq": [{"q": "“ฟังให้ดีแล้วพูดตามนะคะ — ใคร ใคร่ ขาย ไก่ ไข่”", "a": "…", "who": "ผู้ป่วยกำลังฟัง"},
			{"q": "รอผู้ป่วยพูดตาม", "a": out}],
	}


static func _roll_write(t: String) -> Dictionary:
	var s: Dictionary
	if t == "dictate":
		s = {"t": "วันนี้อากาศดี", "ok": 1, "why": "เป็นประโยคที่มีความหมาย แต่ผู้ประเมินบอกให้เขียนตามคำบอก ข้อนี้จึงไม่ได้วัดการเขียนภาษาของผู้ป่วยเอง"}
	elif t == "vague":
		s = G.pick([D.WRITE_SENTENCES[3], D.WRITE_SENTENCES[5], D.WRITE_SENTENCES[2], D.WRITE_SENTENCES[4]])
	else:
		s = G.pick(D.WRITE_SENTENCES.slice(0, 3)) if G.chance(0.6) else G.pick(D.WRITE_SENTENCES)
	s = s.duplicate()
	s.t = D.t(s.t)
	return {
		"sentence": s, "truth": {"sent": s.ok},
		"said": {"sent": "เขียนว่า “" + s.t + "” — " + s.why},
		"seq": [{"q": "ยื่นกระดาษ A4 กับดินสอไม้ให้ผู้ป่วย", "a": "…", "who": "ผู้ป่วยกำลังเขียน", "fx_after": "think"},
			{"q": "ผู้ป่วยเขียนเสร็จแล้วส่งกระดาษคืน", "a": D.t("เขียนเสร็จแล้ว{k}"), "fx_before": "unthink"}],
		"proof": "write",
	}


static func _roll_draw(t: String) -> Dictionary:
	var v: Dictionary
	var dv: Array = D.DRAW_VARIANTS
	if t == "good":
		v = G.pick([dv[0], dv[1]]) if G.chance(0.55) else G.pick(dv)
	elif t == "guide":
		v = G.pick([dv[0], dv[1], dv[2]])
	else:
		v = G.pick([dv[2], dv[3], dv[4], dv[1]])
	return {
		"variant": v, "truth": {"draw": v.ok},
		"said": {"draw": v.said + " — " + v.why},
		"seq": [{"q": "ยื่นรูปห้าเหลี่ยม 2 รูปทับกัน พร้อมกระดาษและดินสอ", "a": "…", "who": "ผู้ป่วยกำลังวาด", "fx_after": "think"},
			{"q": "ผู้ป่วยวาดเสร็จแล้วส่งกระดาษคืน", "a": D.t("วาดเสร็จแล้ว{k}"), "fx_before": "unthink"}],
		"proof": "draw",
	}


# ---------- feedback ----------
static func feedback(id: String, rec: Dictionary, out: Array) -> void:
	var t: String = rec.type
	var sc: Dictionary = rec.sc
	match id:
		"place":
			if t == "good":
				out.append(G.fb("good", "ข้อ 2 ถามครบทั้ง 5 ข้อแบบปลายเปิด", "ข้อแรกถามครบทั้ง “อยู่ที่ไหน” และ “ที่นี่ชื่ออะไร” ซึ่งเป็นเงื่อนไขของการได้ 1 คะแนนในข้อนั้น"))
			elif t == "half":
				out.append(G.fb("tip", "ข้อ 2.1 ถามไม่ครบ", "ข้อ 2.1 ต้องได้คำตอบทั้ง “ตอนนี้อยู่ที่ไหน” และ “ที่นี่ชื่ออะไร” ถามแค่อย่างเดียวผู้ป่วยจึงไม่มีทางได้คะแนนข้อนี้ ทั้งที่อาจตอบได้ถ้าถามครบ",
					D.t("ควรถามว่า “ตอนนี้{c}อยู่ที่ไหนคะ แล้วที่นี่ชื่ออะไรคะ”")))
			else:
				out.append(G.fb("tip", "ข้อ 2 ใช้คำถามชี้นำ", "บอกชื่อโรงพยาบาล ชั้น และอำเภอไปในคำถามแล้ว ผู้ป่วยเพียงตอบรับ คะแนนที่ได้จึงไม่สะท้อนการรับรู้สถานที่จริง",
					D.t("ควรถามปลายเปิดทีละข้อ เช่น “ตอนนี้{c}อยู่ที่ไหนคะ แล้วที่นี่ชื่ออะไรคะ”")))
			out.append(G.fb("info", "เกณฑ์ที่ยืดหยุ่นของข้อ 2", "ชั้นของอาคาร ตอบ “ชั้นบน/ชั้นล่าง” ก็นับคะแนน · ภาค ตอบ “อีสานเหนือ” หรือ “อีสานใต้” ก็นับคะแนน อย่าหักคะแนนเพราะผู้ป่วยไม่ได้ตอบเป็นคำทางการ"))
		"reg":
			if t == "good":
				out.append(G.fb("good", "ข้อ 3 บอกชื่อของครั้งเดียวตามเกณฑ์", "พูดครบ 3 อย่างในครั้งเดียวแล้วให้ผู้ป่วยพูดตาม เป็นการวัดการบันทึกความจำที่ถูกต้อง"))
			elif t == "twice":
				out.append(G.fb("tip", "ข้อ 3 บอกชื่อของซ้ำ 2 รอบ", "เกณฑ์กำหนดให้บอกครั้งเดียว การบอกซ้ำทำให้ผู้ป่วยได้ยินถึงสองครั้ง คะแนนข้อ 3 สูงเกินจริง และข้อ 5 ที่ต้องทวนความจำก็แปลผลไม่ได้",
					"ควรพูดว่า “บอกครั้งเดียวนะคะ ฟังให้ดี — ดอกไม้ แม่น้ำ รถไฟ”"))
			else:
				out.append(G.fb("tip", "ข้อ 3 พูดทีละคำแล้วให้พูดตามทีละคำ", "การแบ่งพูดทีละคำทำให้ผู้ป่วยไม่ต้องจำทั้ง 3 อย่างพร้อมกัน ข้อนี้จึงไม่ได้วัดการบันทึกความจำตามที่ตั้งใจ",
					"ควรพูดว่า “บอกครั้งเดียวนะคะ ฟังให้ดี — ดอกไม้ แม่น้ำ รถไฟ”"))
		"calc":
			var better := D.t("ควรพูดว่า “{c}คิดเลขได้มั้ยคะ ถ้าได้ ให้เลข 100 มาลบออกทีละ 7 นะคะ”")
			if t == "good":
				out.append(G.fb("good", "ข้อ 4 ถามความพร้อมก่อนเริ่ม", "ถามว่าคิดเลขได้หรือไม่ก่อน ทำให้เปลี่ยนไปใช้การสะกดคำถอยหลังได้ทันทีเมื่อผู้ป่วยบวกลบไม่ได้"))
			elif t == "hint":
				out.append(G.fb("tip", "ข้อ 4 ใบ้คำตอบแรกให้ผู้ป่วย", "การบอกว่า “100 ลบ 7 ได้ 93” คือการให้คำตอบข้อแรกไปแล้ว คะแนนครั้งที่ 1 จึงไม่ได้มาจากผู้ป่วย", better))
			else:
				out.append(G.fb("tip", "ข้อ 4 ไม่ได้ถามความพร้อมก่อน", "เกณฑ์ให้ถามก่อนว่าคิดเลขได้หรือไม่ " +
					("ผู้ป่วยรายนี้คิดเลขไม่เป็น เมื่อไม่ได้เปลี่ยนไปใช้การสะกดคำว่า “มะนาว” กลับหลัง ข้อนี้จึงเสียไปทั้งข้อ" if sc.get("stuck", false)
					else "ผู้ป่วยรายนี้บังเอิญคิดเลขได้ แต่ถ้าเจอผู้ป่วยที่คิดไม่ได้จะเสียข้อนี้ทั้งข้อ"), better))
			if rec.get("prompt", "") == "bad":
				out.append(G.fb("tip", "ข้อ 4 กระตุ้นด้วยการทวนคำตอบเดิม", "การพูดว่า “… ลบอีก 7 เหลือเท่าไหร่” โดยใส่ตัวเลขคำตอบเดิมเข้าไป เป็นทั้งการทวนคำตอบและการใบ้ ผู้ป่วยไม่ต้องจำคำตอบของตัวเอง ข้อนี้จึงไม่ได้วัดสมาธิและความจำขณะทำงาน",
					"ควรกระตุ้นแค่ “ลบอีก 7 เหลือเท่าไหร่คะ”"))
			elif rec.get("prompt", "") == "good":
				out.append(G.fb("good", "ข้อ 4 กระตุ้นได้ถูกวิธี", "พูดเพียง “ลบอีก 7 เหลือเท่าไหร่” โดยไม่ทวนตัวเลขคำตอบเดิม เป็นการกระตุ้นที่เกณฑ์อนุญาต"))
			if sc.get("fingers", false):
				out.append(G.fb("info", "ผู้ป่วยนับนิ้วช่วยคิด", "เกณฑ์ระบุว่าถ้าผู้ป่วยจด บันทึก นับนิ้ว หรือเขียนบนฝ่ามือ จะไม่นับคะแนนข้อนี้ แม้ตัวเลขที่ตอบจะถูกก็ตาม — ผู้ประเมินต้องสังเกตมือของผู้ป่วยไปพร้อมกับฟังคำตอบ"))
			if sc.get("mode", "") == "spell":
				out.append(G.fb("info", "เปลี่ยนไปใช้การสะกดคำ “มะนาว” กลับหลัง", "คำตอบของผู้ป่วยคือ “" + sc.spell.out + "” — " + sc.spell.why + " · คำตอบที่ถูกต้องคือ ว-า-น-ะ-ม"))
		"recall":
			var better5 := "ควรถามว่า “เมื่อซักครู่ที่ให้จำของสามอย่าง จำได้มั้ยคะ มีอะไรบ้าง”"
			if t == "good":
				out.append(G.fb("good", "ข้อ 5 ถามทวนโดยไม่ใบ้", "ถามปลายเปิดแล้วรอให้ผู้ป่วยนึกเอง เป็นการวัดความจำระยะสั้นที่ถูกต้อง"))
			elif t == "cue":
				out.append(G.fb("tip", "ข้อ 5 ใบ้คำแรกให้ผู้ป่วย", "การบอกว่า “มีดอกไม้ แล้วอะไรอีก” คือการให้คำตอบไปแล้ว 1 คำ คะแนนของคำนั้นใช้ไม่ได้", better5))
			else:
				out.append(G.fb("tip", "ข้อ 5 บอกคำตอบครบทั้ง 3 คำ", "การถามแบบให้ตอบใช่/ไม่ใช่โดยบอกคำตอบครบ ทำให้ผู้ป่วยได้ 3 คะแนนโดยไม่ต้องจำอะไรเลย คะแนนนี้แปลผลไม่ได้", better5))
			out.append(G.fb("info", "ข้อ 5 ไม่ต้องเรียงลำดับ" + (" — ผู้ป่วยรายนี้ตอบสลับลำดับ" if sc.get("unordered", false) else ""),
				"ผู้ป่วยจะทวน ดอกไม้ · แม่น้ำ · รถไฟ ตามลำดับเดิมหรือสลับลำดับก็ได้ ได้คะแนนครบทุกคำที่ทวนได้ อย่าหักคะแนนเพราะลำดับไม่ตรง"))
		"name":
			if t == "good":
				out.append(G.fb("good", "ข้อ 6 ให้ดูอย่างเดียวไม่ให้จับ", "ถูกตามเกณฑ์ — ยื่นให้ดูและชี้ให้ดูโดยไม่ให้สัมผัส แล้วถามปลายเปิดว่าสิ่งนี้คืออะไร"))
			elif t == "touch":
				out.append(G.fb("tip", "ข้อ 6 ให้ผู้ป่วยสัมผัสสิ่งของ", "เกณฑ์ระบุว่าให้ดูเท่านั้น ห้ามให้สัมผัส เพราะการจับให้เบาะแสเพิ่มเรื่องน้ำหนักและรูปทรง",
					D.t("ควรพูดว่า “{c}ช่วยดูของชิ้นนี้นะคะ สิ่งนี้เรียกว่าอะไรคะ” โดยถือไว้ให้ดู")))
			else:
				out.append(G.fb("tip", "ข้อ 6 บอกชื่อของให้ผู้ป่วยเสียเอง", "การถามว่า “อันนี้ดินสอใช่มั้ย” คือการบอกคำตอบ ผู้ป่วยเพียงตอบรับ ข้อนี้จึงไม่ได้วัดการเรียกชื่อสิ่งของ",
					"ควรถามปลายเปิดว่า “สิ่งนี้เรียกว่าอะไรคะ”"))
		"repeat":
			if t == "good":
				out.append(G.fb("good", "ข้อ 7 พูดรวดเดียวทั้งประโยค", "ถูกตามเกณฑ์ ข้อนี้วัดการรับฟังและพูดซ้ำทั้งประโยคในครั้งเดียว"))
			elif t == "slow":
				out.append(G.fb("tip", "ข้อ 7 แยกพูดทีละคำ", "การพูดทีละคำแล้วให้พูดตามทีละคำ ทำให้ผู้ป่วยไม่ต้องจำทั้งประโยค ข้อนี้จึงง่ายกว่าที่เกณฑ์กำหนด", "ควรพูดรวดเดียวว่า “ใคร ใคร่ ขาย ไก่ ไข่”"))
			else:
				out.append(G.fb("tip", "ข้อ 7 พูดให้ฟังซ้ำ 2 รอบ", "เกณฑ์ให้พูดครั้งเดียว การพูดซ้ำทำให้ผู้ป่วยมีโอกาสฟังสองครั้ง คะแนนที่ได้สูงเกินจริง", "ควรพูดครั้งเดียวว่า “ใคร ใคร่ ขาย ไก่ ไข่”"))
			out.append(G.fb("info", "ข้อ 7 เป็นแบบได้หมดหรือไม่ได้เลย", "พูดตามถูกครบทุกคำจึงได้ 1 คะแนน ผิดคำเดียวหรือตกคำเดียวก็ได้ 0 คะแนน ไม่มีคะแนนบางส่วน"))
		"write":
			if t == "good":
				out.append(G.fb("good", "ข้อ 10 สั่งครบเงื่อนไข", "บอกชัดว่าให้เขียน “ประโยคที่มีความหมาย” โดยไม่กำหนดข้อความ ทำให้วัดการใช้ภาษาของผู้ป่วยได้จริง"))
			elif t == "dictate":
				out.append(G.fb("tip", "ข้อ 10 บอกข้อความให้ผู้ป่วยเขียนตาม", "เมื่อบอกว่าให้เขียนอะไร ข้อนี้กลายเป็นการเขียนตามคำบอก ไม่ใช่การเรียบเรียงภาษาด้วยตัวเอง คะแนนที่ได้ใช้ไม่ได้",
					"ควรพูดว่า “ช่วยเขียนประโยคอะไรก็ได้ที่มีความหมาย สัก 1 ประโยคนะคะ”"))
			else:
				out.append(G.fb("tip", "ข้อ 10 สั่งไม่ครบเงื่อนไข", "การบอกแค่ “เขียนอะไรก็ได้” ทำให้ผู้ป่วยอาจเขียนเป็นคำเดี่ยวหรือชื่อตัวเอง ซึ่งไม่เข้าเกณฑ์ ทั้งที่เขียนเป็นประโยคได้ถ้าสั่งให้ชัด",
					"ควรระบุว่า “เขียนประโยคที่มีความหมาย 1 ประโยค”"))
		"draw":
			var better11 := "ควรพูดเพียงว่า “ช่วยวาดตามรูปนี้ให้เหมือนที่สุดเท่าที่จะทำได้นะคะ”"
			if t == "good":
				out.append(G.fb("good", "ข้อ 11 สั่งตามเกณฑ์", "ให้ผู้ป่วยวาดตามแบบโดยไม่อธิบายวิธีวาด ข้อนี้จึงวัดการประสานงานระหว่างตากับมือได้จริง"))
			elif t == "guide":
				out.append(G.fb("tip", "ข้อ 11 อธิบายวิธีวาดให้ผู้ป่วย", "การบอกว่าเป็นห้าเหลี่ยมสองรูปและต้องซ้อนกันตรงกลาง คือการใบ้โครงสร้างของรูป ผู้ป่วยไม่ต้องวิเคราะห์รูปเอง คะแนนจึงสูงเกินจริง", better11))
			else:
				out.append(G.fb("tip", "ข้อ 11 เร่งผู้ป่วย", "MMSE ไม่ได้จับเวลาข้อนี้ การเร่งทำให้ผู้ป่วยวาดพลาดจากความรีบ ไม่ใช่จากความบกพร่องที่ต้องการวัด", better11))
			out.append(G.fb("info", "จุดที่มักให้คะแนนผิดในข้อ 11", "ต้องดู 2 อย่างเท่านั้น คือมุมครบ 5 มุมทั้งสองรูป และรอยตัดกันเป็นสี่เหลี่ยม — เส้นสั่น รูปเบี้ยว หรือขนาดไม่เท่าแบบ ไม่ใช่เหตุผลในการหักคะแนน"))
