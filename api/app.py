import base64
import json
import cv2
import numpy as np
from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from ultralytics import YOLO
from paddleocr import PaddleOCR
import uvicorn

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)
c
model = YOLO("best512.pt").to('cpu')
ocr = PaddleOCR(use_angle_cls=True, lang='en', show_log=False) 

@app.websocket("/ws/json_detect")
async def ws_json_detect(ws: WebSocket):
    await ws.accept()
    try:
        while True:
            data_str = await ws.receive_text()
            data = json.loads(data_str)

            img_bytes = base64.b64decode(data["image"])
            nparr = np.frombuffer(img_bytes, np.uint8)
            frame = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
            if frame is None or frame.size == 0:
                continue

            results = model.predict(
                source=frame,
                imgsz=512,
                conf=0.25,
                iou=0.45,
                device='cpu',
            )
            det = results[0].boxes

            detections = []

            for (x1, y1, x2, y2), score in zip(det.xyxy, det.conf):
                x1i, y1i, x2i, y2i = map(int, (x1, y1, x2, y2))
                roi = frame[y1i:y2i, x1i:x2i]
                if roi.size == 0:
                    continue

                ocr_res = ocr.ocr(roi, cls=True)

                texts = []
                def extract_text(obj):
                    if isinstance(obj, tuple) and len(obj) == 2 and isinstance(obj[0], str):
                        texts.append(obj[0])
                    elif isinstance(obj, (list, tuple)):
                        for item in obj:
                            extract_text(item)

                extract_text(ocr_res)
                text = " ".join(texts).strip()

                detections.append({
                    "x": float(x1),
                    "y": float(y1),
                    "w": float(x2 - x1),
                    "h": float(y2 - y1),
                    "score": float(score),
                    "text": text
                })

            total_dets = len(detections)
            speed_texts = sum(1 for d in detections if d["text"])
            print(f"Detections: {total_dets}, speed texts: {speed_texts}")

            resp = {
                "timestamp": data.get("timestamp"),
                "detections": detections
            }
            await ws.send_text(json.dumps(resp))

    except WebSocketDisconnect:
        print("⚠️ Client disconnected")

if __name__ == "__main__":
    uvicorn.run("app:app", host="0.0.0.0", port=8000, log_level="info")
