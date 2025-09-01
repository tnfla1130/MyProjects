import base64, os
import numpy as np
from flask import Flask, request, jsonify, render_template
from datetime import datetime
from PIL import Image
from tensorflow.keras.preprocessing.image import img_to_array
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import Conv2D, MaxPooling2D, Activation, Dropout, Flatten, Dense

app = Flask(__name__)

SAVE_DIR = "saveFiles"
os.makedirs(SAVE_DIR, exist_ok=True)
MODEL_PATH = "./smartParm_model.pth"

image_size = 256
categories = [
    "블루베리_탄저병",
    "블루베리_세균구멍병",
    "블루베리_정상",
    "블루베리_흰가루병",
    "상추_탄저병",
    "상추_세균연부병",
    "상추_노균병",
    "상추_정상",
    "시금치_세르코스포라잎마름병",
    "시금치_노균병",
    "시금치_정상",
    "시금치_흰녹병",
    "딸기_탄저병",
    "딸기_정상",
    "딸기_잎마름병",
    "딸기_흰가루병",
    "토마토_세균점무늬병",
    "토마토_정상",
    "토마토_잎마름병",
    "토마토_흰가루병"
]


nb_classes = len(categories)

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

# CNN 모델 구축
def build_model(in_shape):
   # 모델 생성
   model = Sequential()
   # 입력층 : 첫번째 합성곱(Convolution) 층. padding은 same으로 설정.
   model.add(Conv2D(32, 3, 3, padding='same', input_shape=in_shape))
   model.add(Activation('relu')) # ReLU 활성화 함수
   model.add(MaxPooling2D(pool_size=(2, 2))) #최대 풀링 적용
   model.add(Dropout(0.25)) #과적합 방지를 위한 드롭아웃
   # 은닉층1 : 두번째 합성곱 층
   model.add(Conv2D(64, 3, 3, padding='same'))
   model.add(Activation('relu'))
   # 은닉층2 : 세번째 합성곱 층
   model.add(Conv2D(64, 3, 3))
   model.add(MaxPooling2D(pool_size=(2, 2), padding='same'))
   model.add(Dropout(0.25))
   # 은닉층3 : 완전 연결층(Fully Connected Layer)
   model.add(Flatten())
   model.add(Dense(512))
   model.add(Activation('relu'))
   model.add(Dropout(0.5))
   # 출력층
   model.add(Dense(nb_classes))
   model.add(Activation('softmax'))
   # 모델 컴파일 : 손실 함수, 옵티마이저, 평가 지표
   model.compile(loss='binary_crossentropy', optimizer='rmsprop',
                 metrics=['accuracy'])
   return model


def predict_image(img_path):
   # 저장된 이미지를 불러와 모델을 통해 예측
   try:
       # 이미지 로드 및 전처리
       img = Image.open(img_path).convert("RGB")
       img = img.resize((image_size, image_size))
       img_array = img_to_array(img) / 255.0  # 정규화
       img_array = np.expand_dims(img_array, axis=0)  # 배치 차원 추가
       # 예측 수행
       predictions = model.predict(img_array)[0]
       max_index = np.argmax(predictions)  # 가장 확률이 높은 클래스
       plant_name = categories[max_index]  # 예측된 음식
       confidence = float(predictions[max_index])  # 확률
       return {"plant and disease": plant_name}
   except Exception as e:
       return {"error": str(e)}

if __name__ == "__main__":
    global model
    model = build_model((image_size, image_size, 3))
    model.load_weights(MODEL_PATH)
    print("가중치 로드 완료")
    app.run(debug=True)