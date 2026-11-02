# SnapMark for macOS

**[ภาษาไทย](#ภาษาไทย) · [English](#english)**

Capture → annotate → copy. Paste it straight into LINE, Slack, or any chat — **no file saved to disk**.

แคปหน้าจอ → วาด วงสี ใส่ข้อความ → Copy แล้ววางส่งต่อได้ทันที **โดยไม่ต้องเซฟไฟล์ลงเครื่อง**

![SnapMark editor](docs/images/editor.png)

<p align="center">
  <a href="https://github.com/madara1150/snapmark-macos/raw/main/dist/SnapMark.dmg"><b>⬇️ Download SnapMark.dmg</b></a><br>
  macOS 12+ · Apple Silicon &amp; Intel · ~180 KB
</p>

---

## ภาษาไทย

### ทำไมต้อง SnapMark
เครื่องมือแคปหน้าจอของ macOS ใช้ Markup ได้ก็จริง แต่ถ้าอยากวงสีแล้วส่งรูปให้คนอื่น มักจะต้องเซฟรูปเป็นไฟล์ก่อน SnapMark แก้ปัญหานี้: แคปเสร็จ แก้รูป แล้วกด **⌘C** ได้ทันที รูปที่วาดแล้วจะอยู่ในคลิปบอร์ด ไปกด **⌘V** ในแชทไหนก็ได้

### ความสามารถ
- 📸 แคปบางส่วน (**⌘⇧2**) หรือทั้งจอ จากไอคอนบนแถบเมนู ระหว่างเลือกพื้นที่กด Space เพื่อเปลี่ยนเป็นแคปทั้งหน้าต่าง
- ✏️ เครื่องมือ: ปากกา, ไฮไลต์, ลูกศร, เส้นตรง, สี่เหลี่ยม, วงกลม, ข้อความ (ภาษาไทยใช้ได้), เบลอ/ปิดข้อมูลส่วนตัว
- 🎨 เลือกได้ 8 สี หรือเลือกเองจาก color well ปรับความหนาเส้นและขนาดตัวอักษรได้ 4 ระดับ
- 📝 แก้ข้อความที่ใส่ไปแล้วได้ ทั้งคลิกแก้และลากย้ายตำแหน่ง
- ↩️ ย้อนกลับ / ทำซ้ำ
- 📋 Copy ได้ความละเอียดเต็ม (Retina 2x) ใช้ได้ทั้งรูปแบบ PNG และ TIFF
- 🖼 แก้ไขรูปที่อยู่ในคลิปบอร์ดอยู่แล้วได้ด้วย ใช้เมนู "แก้ไขรูปจากคลิปบอร์ด"
- 🪶 เป็นไฟล์ Swift ไฟล์เดียว ไม่ต้องใช้ Xcode และไม่มี dependency

### ตัวอย่างรูปที่ได้หลัง Copy
![Result](docs/images/result.png)

### ดาวน์โหลดและติดตั้ง (แนะนำ)
1. ดาวน์โหลด **[SnapMark.dmg](https://github.com/madara1150/snapmark-macos/raw/main/dist/SnapMark.dmg)**
2. เปิดไฟล์ .dmg แล้วลาก **SnapMark** ไปวางที่โฟลเดอร์ **Applications**
3. เปิดแอปครั้งแรก: แอปนี้ไม่ได้เซ็นด้วย Apple Developer ID macOS จึงจะเตือนว่า *"ไม่สามารถตรวจสอบผู้พัฒนาได้"* ให้กด **Done** แล้วไปที่
   **System Settings → Privacy & Security** เลื่อนลงไปจะเจอข้อความเกี่ยวกับ SnapMark ให้กด **Open Anyway**
   หรือจะรันคำสั่งนี้ใน Terminal แทนก็ได้:
   ```bash
   xattr -dr com.apple.quarantine /Applications/SnapMark.app
   ```

### Build เอง
ต้องใช้ macOS 12 ขึ้นไป และต้องมี Command Line Tools ของ Xcode (`xcode-select --install`)

```bash
git clone https://github.com/madara1150/snapmark-macos.git
cd snapmark-macos
./build.sh --install
open ~/Applications/SnapMark.app
```

ถ้าต้องการสร้างไฟล์ .dmg เอง ให้รัน `./build.sh --dmg` ไฟล์จะอยู่ที่ `dist/SnapMark.dmg`

ครั้งแรกที่แคป macOS จะขอสิทธิ์ **Screen Recording** ให้เปิดสิทธิ์ที่
**System Settings → Privacy & Security → Screen & System Audio Recording → SnapMark** แล้วปิดแอปและเปิดใหม่

### ปุ่มลัด
| ปุ่ม | การทำงาน |
|---|---|
| **⌘⇧2** | แคปบางส่วน (ใช้ได้จากทุกแอป) |
| **P / H / A / L / R / O / T / B** | ปากกา / ไฮไลต์ / ลูกศร / เส้นตรง / สี่เหลี่ยม / วงกลม / ข้อความ / เบลอ |
| **Shift** ค้างระหว่างวาด | ได้สี่เหลี่ยมจัตุรัส / วงกลมกลมพอดี / เส้นล็อกมุมทีละ 45° |
| ดับเบิลคลิกที่ข้อความ | แก้ข้อความ (ใช้ได้กับทุกเครื่องมือ) |
| **⌘Z / ⇧⌘Z** | ย้อนกลับ / ทำซ้ำ |
| **⌘C** | คัดลอกรูปไปคลิปบอร์ด |
| **⌘↩** | คัดลอกแล้วปิดหน้าต่าง |
| **⌘S** | เซฟเป็นไฟล์ PNG (ถ้าต้องการ) |
| **⌘W** | ปิดหน้าต่างโดยไม่คัดลอก |

### แก้ปัญหาเบื้องต้น
- **แคปไม่ได้ หรือได้มาแค่วอลเปเปอร์:** แอปยังไม่ได้รับสิทธิ์ Screen Recording ถ้าใน System Settings มี SnapMark อยู่แล้ว ให้ลบออกด้วยปุ่ม − แล้วเพิ่มใหม่ เพราะทุกครั้งที่ build ใหม่ macOS จะมองว่าเป็นแอปใหม่
- **หาไอคอนบนแถบเมนูไม่เจอ:** อาจโดนรอยบากของจอบัง ให้กด ⌘⇧2 หรือดับเบิลคลิกแอปซ้ำแทน แอปจะเริ่มแคปทันที
- **ดู log:** อยู่ที่ `~/Library/Logs/SnapMark.log`

### ถอนการติดตั้ง
ปิดแอปจากไอคอนบนแถบเมนู แล้วลบ `SnapMark.app` ออกจาก `/Applications` (หรือ `~/Applications` ถ้า build เอง)

---

## English

### Why SnapMark
The built-in macOS screenshot tool has Markup, but if you want to annotate a screenshot and send it to someone, you usually have to save it as a file first. SnapMark fixes that: capture, annotate, press **⌘C**. The annotated image goes to your clipboard, ready to **⌘V** into any chat.

### Features
- 📸 Capture an area (**⌘⇧2**, works from any app) or the full screen from the menu bar icon. Press Space while selecting to capture a whole window.
- ✏️ Tools: pen, highlighter, arrow, line, rectangle, ellipse, text (Thai supported), and pixelate for hiding sensitive info
- 🎨 8 quick colors plus a custom color well, and 4 sizes for stroke width and font size
- 📝 Edit existing text: click to change it, drag to move it
- ↩️ Undo / redo
- 📋 Copies at full Retina resolution, as both PNG and TIFF
- 🖼 "Edit image from clipboard" lets you annotate an image you've already copied
- 🪶 A single Swift file, with no Xcode project and no dependencies

### Example output after Copy
![Result](docs/images/result.png)

### Download & install (recommended)
1. Download **[SnapMark.dmg](https://github.com/madara1150/snapmark-macos/raw/main/dist/SnapMark.dmg)**
2. Open the .dmg and drag **SnapMark** into **Applications**
3. First launch: the app isn't signed with an Apple Developer ID, so macOS will say it *"cannot verify the developer"*. Click **Done**, then go to
   **System Settings → Privacy & Security**, scroll down to the message about SnapMark, and click **Open Anyway**.
   Or run this in Terminal instead:
   ```bash
   xattr -dr com.apple.quarantine /Applications/SnapMark.app
   ```

### Build from source
Requires macOS 12+ and the Xcode Command Line Tools (`xcode-select --install`).

```bash
git clone https://github.com/madara1150/snapmark-macos.git
cd snapmark-macos
./build.sh --install
open ~/Applications/SnapMark.app
```

To build the .dmg yourself, run `./build.sh --dmg`. The output goes to `dist/SnapMark.dmg`.

The first time you capture, macOS asks for **Screen Recording** permission. Turn it on in
**System Settings → Privacy & Security → Screen & System Audio Recording → SnapMark**, then quit and reopen the app.

### Shortcuts
| Key | Action |
|---|---|
| **⌘⇧2** | Capture an area (works from any app) |
| **P / H / A / L / R / O / T / B** | Pen / Highlighter / Arrow / Line / Rectangle / Ellipse / Text / Blur |
| Hold **Shift** while drawing | Square / perfect circle / lines snapped to 45° |
| Double-click a text | Edit that text (works with any tool) |
| **⌘Z / ⇧⌘Z** | Undo / Redo |
| **⌘C** | Copy the image to the clipboard |
| **⌘↩** | Copy and close the window |
| **⌘S** | Save as PNG (optional) |
| **⌘W** | Close the window without copying |

### Troubleshooting
- **Nothing gets captured, or you only get the wallpaper:** the app doesn't have Screen Recording permission yet. If SnapMark is already listed in System Settings, remove it with the − button and add it again. Every rebuild looks like a new app to macOS.
- **Can't find the menu bar icon:** it may be hidden behind the notch. Press ⌘⇧2, or double-click the app again, and it starts a capture right away.
- **Logs:** `~/Library/Logs/SnapMark.log`

### Uninstall
Quit the app from the menu bar icon, then delete `SnapMark.app` from `/Applications` (or `~/Applications` if you built it yourself).
