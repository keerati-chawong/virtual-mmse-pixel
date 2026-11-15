extends Control
## สมัครสมาชิก / เข้าสู่ระบบ (เดโม — เก็บในเครื่องนี้เท่านั้น)

var mode := "login"
var head: Label
var mail: LineEdit
var pass1: LineEdit
var pass2: LineEdit
var pass2_box: Control
var err: Label
var go: Button
var tab_login: Button
var tab_reg: Button


func _ready() -> void:
	add_child(UI.backdrop(0.45))
	var c := CenterContainer.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(c)
	var p := UI.frame("panel", 26)
	p.custom_minimum_size = Vector2(460, 0)
	c.add_child(p)
	var v := UI.vbox(10)
	p.add_child(v)
	var top := UI.hbox(12)
	var pf := UI.frame("slot", 4)
	pf.add_child(UI.pix(Px.portrait("head", "smile"), 2.0))
	top.add_child(pf)
	var tv := UI.vbox(2)
	head = UI.title("เข้าสู่ระบบ", 28, UI.GOLD)
	tv.add_child(head)
	tv.add_child(UI.wrap(UI.label("ระบบจะเก็บคะแนนของแต่ละบัญชีไว้ให้ติดตามผลได้", 13, UI.MUTED)))
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(tv)
	v.add_child(top)
	var tabs := UI.hbox(6)
	tab_login = UI.btn("เข้าสู่ระบบ", func(): _set_mode("login"))
	tab_reg = UI.btn("สมัครสมาชิก", func(): _set_mode("register"))
	tab_login.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tab_reg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tabs.add_child(tab_login)
	tabs.add_child(tab_reg)
	v.add_child(tabs)
	v.add_child(UI.label("อีเมล", 13, UI.INK_2, true))
	mail = LineEdit.new()
	mail.placeholder_text = "you@example.com"
	v.add_child(mail)
	v.add_child(UI.label("รหัสผ่าน", 13, UI.INK_2, true))
	pass1 = LineEdit.new()
	pass1.secret = true
	pass1.placeholder_text = "อย่างน้อย 6 ตัวอักษร"
	v.add_child(pass1)
	pass2_box = UI.vbox(6)
	pass2_box.add_child(UI.label("ยืนยันรหัสผ่าน", 13, UI.INK_2, true))
	pass2 = LineEdit.new()
	pass2.secret = true
	pass2_box.add_child(pass2)
	v.add_child(pass2_box)
	err = UI.wrap(UI.label("", 13, Color("c0392b")))
	v.add_child(err)
	go = UI.btn("เข้าสู่ระบบ", _submit, "primary", 18)
	v.add_child(go)
	v.add_child(UI.btn("กลับหน้าหลัก", func(): G.goto("home"), "ghost"))
	v.add_child(UI.wrap(UI.label("เดโมนี้ยังไม่มีเซิร์ฟเวอร์จริง — บัญชีและคะแนนถูกเก็บไว้ในเครื่องนี้เท่านั้น (รหัสผ่านเก็บเป็นค่าแฮช) กรุณาอย่าใช้รหัสผ่านจริง", 11, UI.FAINT)))
	for le in [mail, pass1, pass2]:
		le.text_submitted.connect(func(_t): _submit())
	_set_mode("login")
	mail.grab_focus.call_deferred()


func _set_mode(m: String) -> void:
	mode = m
	head.text = "เข้าสู่ระบบ" if m == "login" else "สมัครสมาชิก"
	go.text = head.text
	pass2_box.visible = m == "register"
	err.text = ""
	tab_login.add_theme_stylebox_override("normal", UI.tbox("btn" if m == "login" else "btn_light", 10))
	tab_reg.add_theme_stylebox_override("normal", UI.tbox("btn" if m == "register" else "btn_light", 10))
	tab_login.add_theme_color_override("font_color", Color.WHITE if m == "login" else UI.INK)
	tab_reg.add_theme_color_override("font_color", Color.WHITE if m == "register" else UI.INK)


func _submit() -> void:
	var m := mail.text.strip_edges().to_lower()
	var e := ""
	if mode == "register":
		e = G.register(m, pass1.text, pass2.text)
	else:
		e = G.login(m, pass1.text)
	if e != "":
		err.text = e
		return
	G.say("สมัครสมาชิกเรียบร้อย · ยินดีต้อนรับ" if mode == "register" else "เข้าสู่ระบบเรียบร้อย")
	G.goto(G.after_login)
