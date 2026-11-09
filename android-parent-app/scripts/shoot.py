import os, re, subprocess, sys, time, traceback
import xml.etree.ElementTree as ET

PKG = "sd.alumrabi.parent.debug"
APK = "android-parent-app/app/build/outputs/apk/debug/app-debug.apk"
OUT = "shots"
os.makedirs(OUT, exist_ok=True)
MODE = os.environ.get("SHOT_MODE", "demo")
ACCT = os.environ.get("ACCT", "")
PW = os.environ.get("PW", "")
counter = [0]


def adb(*a):
    return subprocess.run(["adb", *a], capture_output=True, text=True).stdout


def shot(name):
    counter[0] += 1
    data = subprocess.run(["adb", "exec-out", "screencap", "-p"], capture_output=True).stdout
    with open(f"{OUT}/{counter[0]:02d}_{name}.png", "wb") as f:
        f.write(data)
    print("shot", counter[0], name, len(data), flush=True)


def nodes():
    for _ in range(3):
        adb("shell", "uiautomator", "dump", "/sdcard/u.xml")
        x = adb("shell", "cat", "/sdcard/u.xml")
        try:
            root = ET.fromstring(x[x.index("<?xml"):] if "<?xml" in x else x)
        except Exception:
            time.sleep(1)
            continue
        res = []
        for e in root.iter("node"):
            b = re.findall(r"\d+", e.get("bounds", ""))
            if len(b) != 4:
                continue
            x1, y1, x2, y2 = map(int, b)
            res.append(dict(text=e.get("text") or "", desc=e.get("content-desc") or "",
                            cls=e.get("class") or "", x=(x1 + x2) // 2, y=(y1 + y2) // 2))
        return res
    return []


def match(o, sub, exact):
    if exact:
        return o["text"] == sub or o["desc"] == sub
    return sub in o["text"] or sub in o["desc"]


def find(sub, exact=False, last=False, index=None):
    m = sorted([o for o in nodes() if match(o, sub, exact)], key=lambda o: o["y"])
    if not m:
        return None
    if index is not None:
        return m[index] if index < len(m) else None
    return m[-1] if last else m[0]


def tap_node(o):
    adb("shell", "input", "tap", str(o["x"]), str(o["y"]))
    time.sleep(1.2)


def tap(sub, exact=False, last=False, index=None, timeout=15):
    end = time.time() + timeout
    while time.time() < end:
        o = find(sub, exact, last, index)
        if o:
            tap_node(o)
            return True
        time.sleep(1)
    print("NOT FOUND", sub, flush=True)
    return False


def wait_for(sub, timeout=40):
    end = time.time() + timeout
    while time.time() < end:
        if find(sub):
            return True
        time.sleep(1.5)
    return False


def size():
    m = re.search(r"(\d+)x(\d+)", adb("shell", "wm", "size"))
    return int(m.group(1)), int(m.group(2))


W, H = 1080, 2400


def swipe_up(frac=0.5):
    adb("shell", "input", "swipe", str(W // 2), str(int(H * 0.78)), str(W // 2), str(int(H * (0.78 - frac))), "350")
    time.sleep(1.0)


def back():
    adb("shell", "input", "keyevent", "4")
    time.sleep(1.2)


def hide_keyboard():
    if "mInputShown=true" in adb("shell", "dumpsys", "input_method"):
        back()


def tab(label):
    return tap(label, exact=True, last=True)


def step(name, fn):
    try:
        fn()
    except Exception:
        print("STEP FAILED", name, flush=True)
        traceback.print_exc()
        try:
            shot("failed_" + name)
        except Exception:
            pass


def login_real():
    edits = sorted([o for o in nodes() if "EditText" in o["cls"]], key=lambda o: o["y"])
    print("edits", len(edits), flush=True)
    if len(edits) < 2:
        raise RuntimeError("login fields not found")
    tap_node(edits[0])
    adb("shell", "input", "text", ACCT)
    time.sleep(0.5)
    edits = sorted([o for o in nodes() if "EditText" in o["cls"]], key=lambda o: o["y"])
    tap_node(edits[1])
    adb("shell", "input", "text", PW)
    time.sleep(0.5)
    shot("login_filled")
    hide_keyboard()
    tap("دخول", exact=True, last=True)


def main():
    global W, H
    adb("wait-for-device")
    W, H = size()
    print("size", W, H, flush=True)
    adb("install", "-r", "-t", APK)
    adb("shell", "pm", "grant", PKG, "android.permission.POST_NOTIFICATIONS")
    adb("shell", "monkey", "-p", PKG, "-c", "android.intent.category.LAUNCHER", "1")
    time.sleep(0.8)
    shot("splash_a")
    time.sleep(1.2)
    shot("splash_b")
    time.sleep(1.4)
    shot("splash_c")
    wait_for("تسجيل الدخول", 30)
    time.sleep(1.5)
    shot("login")

    if MODE == "login" and ACCT and PW:
        step("login", login_real)
    else:
        step("demo", lambda: tap("تجربة ببيانات تجريبية"))
    if not wait_for("خدماتي", 60):
        shot("after_login_timeout")
        print("home not reached", flush=True)
        return
    time.sleep(2.2)
    shot("home_top")
    step("pager", lambda: (adb("shell", "input", "swipe", str(int(W * 0.8)), "700", str(int(W * 0.2)), "700", "300"), time.sleep(1.2), shot("home_next_child")))
    swipe_up(0.5)
    shot("home_scrolled")
    swipe_up(0.5)
    shot("home_bottom")

    def results():
        tab("النتائج"); time.sleep(1.5); shot("results")
        o = find("نتيجة", index=1)
        if o:
            tap_node(o); time.sleep(1.0); shot("results_expanded")
    step("results", results)

    def attendance():
        tab("الحضور"); time.sleep(1.5); shot("attendance")
        swipe_up(0.5); shot("attendance_scrolled")
    step("attendance", attendance)

    def fees():
        tab("الرسوم"); time.sleep(1.5); shot("fees")
        swipe_up(0.5); shot("fees_scrolled")
        swipe_up(0.6); shot("fees_bottom")
    step("fees", fees)

    def more():
        tab("المزيد"); time.sleep(1.5); shot("more")
    step("more", more)

    def schedule():
        if tap("الجدول الدراسي"):
            time.sleep(1.5); shot("schedule")
            back()
    step("schedule", schedule)

    def announcements():
        if tap("الإعلانات والتقويم"):
            time.sleep(1.5); shot("announcements")
            if tap("التقويم", exact=True):
                time.sleep(1.0); shot("calendar")
            back()
    step("announcements", announcements)

    def assistant():
        if tap("المساعد الذكي"):
            time.sleep(1.5); shot("assistant")
            back()
    step("assistant", assistant)

    def settings():
        if tap("الإعدادات وحسابي"):
            time.sleep(1.5); shot("settings")
            back()
    step("settings", settings)

    def home_again():
        tab("الرئيسية"); time.sleep(1.5); shot("home_again")
    step("home_again", home_again)


try:
    main()
finally:
    print("files:", sorted(os.listdir(OUT)), flush=True)
