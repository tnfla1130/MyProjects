import base64, os
import numpy as np
import torchvision
from flask import Flask, request, jsonify, render_template
from datetime import datetime
from PIL import Image
import torch
import torch.nn as nn
import torch.nn.functional as F
from torchvision import transforms, models

app = Flask(__name__)

SAVE_DIR = "saveFiles"
os.makedirs(SAVE_DIR, exist_ok=True)
# MODEL_PATH = "./pest_disease_resnet18_full_finetune.pth"
MODEL_PATH = "./smartParm_model.pth"

image_size = 128
categories = [
    "블루베리_탄저병", "블루베리_세균구멍병", "블루베리_정상", "블루베리_흰가루병",
    "상추_탄저병", "상추_세균연부병", "상추_노균병", "상추_정상",
    "시금치_세르코스포라잎마름병", "시금치_노균병", "시금치_정상", "시금치_흰녹병",
    "딸기_탄저병", "딸기_정상", "딸기_잎마름병", "딸기_흰가루병",
    "토마토_세균점무늬병", "토마토_정상", "토마토_잎마름병", "토마토_흰가루병"
]
# categories = [
#     "Blueberry_Anthracnose", "Blueberry_Bacterial_Canker", "Blueberry_Healthy", "Blueberry_Powdery_Mildew",
#     "Lettuce_Anthracnose", "Lettuce_Bacterial_Soft_Rot", "Lettuce_Downy_Mildew", "Lettuce_Healthy",
#     "Spinach_Cercospora_Leaf_Spot", "Spinach_Downy_Mildew", "Spinach_Healthy", "Spinach_White_Rust",
#     "Strawberry_Anthracnose", "Strawberry_Healthy", "Strawberry_Leaf_Blight", "Strawberry_Powdery_Mildew",
#     "Tomato_Bacterial_Spot", "Tomato_Healthy", "Tomato_Leaf_Blight", "Tomato_Powdery_Mildew"
# ]

nb_classes = len(categories)

device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')





@app.route('/')
def home():
    return render_template("main.html")

@app.route('/getDecodeImage.fk', methods=['POST'])
def decode_image():
    print("요청들어옴")
    try:
        image_name = request.args.get("imageName")
        _, ext = os.path.splitext(image_name)
        now = datetime.now()
        filename = now.strftime("%Y%m%d_%H%M%S") + ext.lower()
        base64_string = request.data.decode("utf-8")
        image_data = base64.b64decode(base64_string)
        file_path = os.path.join(SAVE_DIR, filename)

        with open(file_path, "wb") as f:
            f.write(image_data)

        print(f"저장완료: {file_path}")

        predict_result = predict_image(file_path)

        return jsonify({"result": "success",
                        "file_path": file_path,
                        "predict": predict_result})

    except Exception as e:
        return jsonify({"result": "fail",
                        "error": str(e)}), 400

# PyTorch CNN 모델 정의 (Keras와 유사하게)
class SimpleCNN(nn.Module):
    def __init__(self, num_classes=nb_classes):
        super().__init__()
        self.conv1 = nn.Conv2d(3, 32, 3, padding=1)
        self.conv2 = nn.Conv2d(32, 64, 3, padding=1)
        self.conv3 = nn.Conv2d(64, 64, 3)
        self.pool = nn.MaxPool2d(2, 2)
        self.dropout1 = nn.Dropout(0.25)
        self.dropout2 = nn.Dropout(0.5)
        self.fc1 = nn.Linear(64 * 62 * 62, 512)   # 3rd conv: 64채널, 62x62 feature map (계산필요)
        self.fc2 = nn.Linear(512, num_classes)

    def forward(self, x):
        x = F.relu(self.conv1(x))
        x = self.pool(x)
        x = self.dropout1(x)
        x = F.relu(self.conv2(x))
        x = F.relu(self.conv3(x))
        x = self.pool(x)
        x = self.dropout1(x)
        x = x.view(x.size(0), -1)  # flatten
        x = F.relu(self.fc1(x))
        x = self.dropout2(x)
        x = self.fc2(x)
        x = F.softmax(x, dim=1)
        return x

# 이미지 전처리 (torchvision transforms 사용)
transform = transforms.Compose([
    transforms.Resize((image_size, image_size)),
    transforms.ToTensor(),
])

def predict_image(img_path):
    try:
        img = Image.open(img_path).convert("RGB")
        x = transform(img).unsqueeze(0).to(device)     # [1,3,H,W]

        model.eval()
        with torch.no_grad():
            logits = model(x)                          # [1,C]
            probs = torch.softmax(logits, dim=1)       # [1,C]
            probs_np = probs.squeeze(0).cpu().numpy()  # [C]

        idx = int(np.argmax(probs_np))
        return {
            "plant_and_disease": categories[idx],
            "confidence": float(probs_np[idx])         # 0~1 사이
        }
    except Exception as e:
        return {"error": str(e)}


if __name__ == "__main__":
    global model
    model = models.resnet18(weights=None)  # 또는 pretrained=False, but weights=None이 최신!
    model.fc = torch.nn.Linear(512, 20)  # 클래스 20개로 수정
    model.load_state_dict(torch.load(MODEL_PATH, map_location=device))
    model.to(device)
    model.eval()
    print("가중치 로드 완료")
    app.run(debug=True)
