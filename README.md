# 📜 김수림 포트폴리오

---
# 🚀 About Me

> **AI와 백엔드를 융합하여 실질적인 서비스를 구현하는 개발자 김수림입니다.**  
> AI정보공학과 전공을 통해 **딥러닝 모델의 구조와 원리**를 익혔고,  
> 국비지원 과정을 통해 **Spring Boot·Flask 기반 백엔드 개발과 데이터 연동 기술**을 습득했습니다.  
>  
> 단순히 모델을 만드는 것을 넘어, **AI 결과를 실제 서비스에 통합하고 사용자에게 전달하는 과정**에 집중해왔습니다.  
>  
> 💡 *제가 지향하는 개발자는 문제를 “코드”로만 해결하지 않고, “구조와 흐름”으로 이해하는 사람입니다.*  
>  
> 💡 **주요 역량 (Core Skills)**  
> 
> **🧠 AI / Data Science**  
> - TensorFlow, PyTorch 기반 모델 설계 및 최적화 (CNN, ResNet18, LSTM 등)  
> - OpenCV, Pandas, Matplotlib을 활용한 데이터 전처리 및 시각화  
> 
> **⚙️ Back-End Development**  
> - Spring Boot, Flask 기반 설계 및 서버 구축  
> - MyBatis, JDBC를 활용한 DB 연동 및 CRUD 구현  
> - Oracle, MySQL 기반 데이터베이스 설계 및 쿼리 최적화  
> 
> **💻 Front-End & Integration**  
> - JavaScript, HTML5, CSS3, React 활용한 웹 UI 구성  
> - `fetch()` 기반 비동기 통신으로 프론트–백엔드 데이터 연동  
> 
> **🧩 Tooling & DevOps**  
> - Git을 통한 버전 관리 및 협업 환경 구축  
> 

---

# 📝 Projects

> 학교와 국비지원 과정에서 진행한 주요 프로젝트들입니다.  
> 각 프로젝트마다 데이터 처리, 모델 설계, 웹 연동 등 **핵심 기능의 주도적 구현자 역할**을 담당했습니다.

---

## 🎮 1. AtariGame  
> **OpenAI 기반 Atari 게임 환경 구축 (개인 프로젝트)**  
> - **개발기간:** 2023.01  
> - **핵심 역할:** OpenAI Gym을 이용한 강화학습용 게임 시뮬레이터 제작  
> - **기술스택:** `Python3`, `OpenCV`, `Pygame`, `Gym`

**주요 내용**
- OpenAI Gym과 Pygame을 연동하여 사용자가 직접 조작 가능한 게임 환경 구현  
- 강화학습 Agent가 실시간으로 환경과 상호작용하도록 구조 설계  
- 조이스틱/키보드 입력, 예외처리, 더미 이미지 자동 대체로 **실행 안정성 확보**  
- 강화학습 실험용 환경으로 확장 가능하도록 모듈화된 코드 작성  

---

## 😐 2. FaceRecognition  
> **얼굴 인식 정확도 향상을 위한 CNN 모델 비교 (개인 프로젝트)**  
> - **개발기간:** 2024.02 – 2024.08  
> - **핵심 역할:** 얼굴 데이터 전처리, 모델 학습 및 성능 분석  
> - **기술스택:** `Python3`, `OpenCV`, `NumPy`, `PyTorch`, `Matplotlib`

**주요 내용**
- 얼굴 이미지 3종(원본, 원근변환, 랜드마크)을 동일 CNN 모델에 적용해 **각도 변화 대응력 비교**  
- 전이학습 기반 CNN 분류기 구축, 학습 루프와 하이퍼파라미터를 동일하게 유지해 공정성 확보  
- 성능지표(Accuracy, Precision, Loss, Time)를 기반으로 모델별 효율 분석  
- **결과:** 원근변환 이미지 학습 시 정확도 **99%** 달성  

[🔗 프로젝트 PPT 보기](https://drive.google.com/file/d/1jwn0ZlroGkqCevT4tjdjrDmN5X4gZhGS/view?usp=sharing)

---

## 🏦 3. JavaConsoleBank  
> **은행 계좌 관리 프로그램 (개인 프로젝트)**  
> - **개발기간:** 2025.04.07 – 04.14  
> - **핵심 역할:** 계좌 CRUD 기능 및 DB 연동  
> - **기술스택:** `Java`, `OracleDB`, `JDBC`

**주요 내용**
- **객체지향 설계(OOP)** 기반으로 계좌 유형별 클래스 상속 구조 설계  
- 일반·저축·대출 계좌 기능별 모듈화, 공통 로직 재사용  
- JDBC를 통해 DB와 연동하여 **실제 금융 트랜잭션 흐름을 시뮬레이션**  
- 데이터의 영속성과 일관성을 확보하여 오류 없는 CRUD 구현  

---

## ⛵ 4. Sailing_guard  
> **해양 관측 데이터를 활용한 출항 여부 예측 시스템 (팀 프로젝트)**  
> - **개발기간:** 2025.06.12 – 06.19  
> - **핵심 역할:** 시계열 모델 학습 및 실시간 그래프 시각화  
> - **기술스택:** `Python3`, `TensorFlow`, `Flask`, `Pandas`, `Matplotlib`, `JavaScript`

**주요 내용**
- LSTM 기반 시계열 모델로 풍속·조위·유속·기압을 예측 (**MAE 9.28%**)  
- 2층 LSTM 구조와 Dropout 적용으로 과적합 방지 및 장기 의존성 학습  
- Flask를 통해 예측 결과를 실시간 시각화하는 **웹 대시보드** 구현  
- 모델 성능 및 UI를 통합하여 **어업 종사자의 출항 판단을 지원**  

[🔗 프로젝트 PPT 보기](https://drive.google.com/file/d/1x6frPBHeeYRn8xf3UgW75zMLdDGAHDPu/view?usp=sharing)

---

## 🪴 5. MariFarm  
> **가정용 스마트팜 사용자 커뮤니티 플랫폼 (팀 프로젝트)**  
> - **개발기간:** 2025.07.23 – 08.27  
> - **핵심 역할:** AI 모델 통합, 지도·채팅 기능 개발, 웹 프론트 담당  
> - **기술스택:** `SpringBoot`, `Flask`, `OracleDB`, `MyBatis`, `JSP`, `Kakao Map API`, `JavaScript`, `HTML5`, `CSS3`

**주요 내용**
- MVC 아키텍처 기반으로 **AI 식물 추천 / 병해충 진단 / 환경 안내** 3대 기능 구현  
- `ResNet18` 전이학습으로 병해충 진단 모델 개발 (**정확도 98%**)  
- `Kakao Map REST API`를 활용해 거래 위치 지정 및 약속 기능 개발  
- `fetch()` 기반 **비동기 REST API 통신**으로 실시간 채팅 기능 구현  
- MyBatis로 채팅 로그 및 사용자 정보를 DB에 저장·조회, **데이터 영속성 확보**  
- Flask와 Spring Boot를 연동해 **AI 모델과 웹 서비스 간 실시간 데이터 통합**  

[🔗 프로젝트 PPT 보기](https://drive.google.com/file/d/11U3Ca5L3dR7XlFbd2A1oVrioBkQCzJPg/view?usp=sharing)

---

# 📞 Contact

> 저에 대한 더 자세한 내용은  
> [![Profile](https://img.shields.io/badge/-Profile-8AC926?style=for-the-badge)](https://www.notion.so/2761aeae3bb98043ba5bd21988871207?pvs=48)  

- 이메일 : **ksr113030@gmail.com**  
- 깃허브 : <a href="https://github.com/tnfla1130"> <img src="https://user-images.githubusercontent.com/68724828/185908612-22f4d219-78a7-4de7-bb02-deecaa63bffa.png" height="28px" style="margin-top: 10px" />

---
