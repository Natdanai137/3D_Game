# Just go up!!

เกม 3D ของอ๊อฟ: เมนูหลัก เมืองลอยฟ้า กระโดดได้ 3 ครั้ง และเช็กพอยต์ UncleOli

## เล่นบนเว็บ

[เปิดเกม](https://natdanai137.github.io/3D_Game/)

ลิงก์จะใช้งานได้หลังเปิด GitHub Pages และ deployment สำเร็จ

## เผยแพร่เวอร์ชันล่าสุด

1. Repository Settings → Pages → Build and deployment → Source: **GitHub Actions**
2. Push ไฟล์ Web ล่าสุดและ workflow ไป branch main
3. ดู Actions → Deploy latest Web game ให้สำเร็จ แล้วเปิดลิงก์ข้างบน

Workflow นำ Web build ที่ export แล้วจาก `Builds/Web` ไปเผยแพร่ ไม่ได้ export โค้ด Godot ใหม่โดยอัตโนมัติ

เมื่อแก้เกม: Export ด้วย preset Web ไป `Builds/Web/index.html` แล้วรัน `python tools/publish_web.py` จากโฟลเดอร์นี้ ก่อน commit และ push

WASD เดิน / Shift วิ่ง / Space กระโดด 3 ครั้ง / R กลับเช็กพอยต์ / Esc ปล่อยเมาส์
หลังเริ่มเล่นให้คลิกพื้นที่ฉากเพื่อควบคุมกล้อง ใช้ Chrome หรือ Edge

Starter assets based on 3D Platformer Kit by Silver Demon Studios; see LICENSE.md.
