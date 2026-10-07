# Just go up!! — Web build

อัปโหลดไฟล์ทั้งหมดในโฟลเดอร์นี้ไปยังเว็บโฮสต์ โดยใช้ index.html เป็นหน้าแรก (WebGL 2.0, single-threaded)

เปิดทดสอบในเครื่อง: เปิด Terminal ในโฟลเดอร์นี้แล้วรัน:
python -m http.server 8067 --bind 127.0.0.1
จากนั้นเปิด http://127.0.0.1:8067/ ใน Chrome หรือ Edge
อย่าเปิด index.html ด้วยการดับเบิลคลิกโดยตรง

กดเริ่มเล่น แล้วคลิกพื้นที่ฉากเพื่อจับเมาส์และเริ่มควบคุม
WASD เดิน / Shift วิ่ง / Space กระโดดได้ 3 ครั้ง / R กลับเช็กพอยต์ / Esc ปล่อยเมาส์
ปิดแท็บเพื่อออกจากเกม เวอร์ชันเว็บจึงซ่อนปุ่มออกจากเกม

เกมขนาดประมาณ 145 MB ก่อนบีบอัด แนะนำให้เว็บโฮสต์เปิด gzip/Brotli และส่ง .wasm ด้วย Content-Type: application/wasm
ฟอนต์ Noto Sans Thai ใช้ SIL Open Font License ดู FONT-LICENSE.txt
