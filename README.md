# 📌 512 Point Radix-2 FFT Filter Design

### 🎯 프로젝트 개요
전반적인 Front-End 과정을 진행했습니다.
- MATLAB을 활용해 Radix-2 FFT의 Butterfly 구조를 이해
- Floating-Point와 Fixed-Point 차이를 분석
- BFP와 CBFP를 적용한 알고리즘을 분석
- 소프트웨어 모델링을 기반으로 하드웨어 모듈을 설계
- Synopsys EDA Tool을 이용해 RTL 및 Gate Level 검증.
- Vivado를 활용해 FPGA 검증과 Bitstream생성
---

### 🙋‍♂️ 역할 분담

#### 🐲윤종민
- 역할
#### 🦖이현수
- 역할 
#### 🐉이은성
- 역할
#### 🥊장환
- 역할

---

### 💻 개발 환경

| 구분        | 사용 도구 / 언어 |
|------------|----------------|
| **EDA Tools** | Xilinx Vivado HLx Editions, Synopsys VCS, Synopsys Verdi |
| **Languages** | SystemVerilog, MATLAB |
| **IDE / Tools** | Visual Studio Code, MobaXterm |

---

### 📂 프로젝트 구조

```
FFT-Design/
├── docs/            # 설계 보고서, 참고 자료
├── software/        # 알고리즘 검증
├── hardware/   
│    ├── rtl/        # SystemVerilog 설계 소스
│    ├── sim/        # RTL Level 합성
│    ├── syn/        # 합성 스크립트 및 리포트
│    ├── verilog/    # Gate Level 합성
│    └── testbench/  # 시뮬레이션 테스트벤치
└── README.md
```

---

### 🔎 알고리즘 검증

📂 [참고문헌](./Docs) <br>
📂 [MATLAB 알고리즘 검증 코드](./Software)

cos_in_gen
→  FFT 입력 신호로 사용할 코사인 함수의 
     복소수 벡터 및 고정소수점으로 양자화된 벡터 생성
ran_in_gen
→  FFT 입력 신호로 사용할 랜덤 함수의 
     복소수 벡터 및 고정소수점으로 양자화된 벡터 생성
fft_float
→  입력 신호를 받아 512-floating point FFT를 계산하는 함수
fft_fixed
→  입력 신호를 받아 512-fixed point FFT를 계산하는 함수

### BFP vs CBFP
| 구분 | BFP (Block Floating Point) | CBFP (Convergent Block Floating Point) |
| :---: | :---: | :---: |
| **방식** | 블록 내 최대값 기준으로 shift 수행 | 여러 조건(real/imag, max/min 등) 고려해 지수 결정 |
| **블록 처리** | 전체 블록 단위 | 세분화된 블록 단위 (N/4, N/8, N/16 …) |
| **정밀도** | 큰 값에 의해 작은 값이 underflow → 손실 가능 | 블록마다 다른 지수 사용 가능 → underflow 감소 |
| **파이프라이닝** | 블록 전체를 알아야 함 → 어려움 | 블록 단위로 가능 → 파이프라이닝 유리 |
| **성능** | 기준 성능 | BFP 대비 약 **+0.5 dB 향상** |
| **적합한 경우** | 단순 구현, 하드웨어 복잡도 낮음 | 정밀도 중요, 다양한 신호(OFDM, Dirac 등) 입력 시 효과적 |


### ➕➖✖️➗ BIT 계산
| module0                     | module1                          | module2                          |
|-----------------------------|----------------------------------|----------------------------------|
| <3.6> din (9bits)           | bfly02 (11 bits)                 | bfly12 (12 bits)                 |
| ↓ (bfly00)                  | ↓ (bfly)                         | ↓ (bfly)                         |
| <4.6> (10bits)              | bfly10 (12 bits)                 | bfly20 (13 bits)                 |
| ↓ (bfly01)                  | ↓ (bfly)                         | ↓ (bfly)                         |
| <5.6> * <2.8> (TW)           | bfly11 (13 bits) * TW<2.8>       | bfly21 (14 bits) * TW<2.8>       |
| ↓                           | ↓                                | ↓                                |
| <7.14> (21bits)             | 23bits                           | 24bits                           |
| ↓ (/256 = <<2^8)             | ↓ (/256 = <<2^8)                  | ↓ (/256 = <<2^8)                  |
| <7.6> (13bits)              | bfly11 (15bits)                  | bfly21 (16bits)                  |
| ↓ (bfly02)                  | ↓ (bfly)                         | ↓ (bfly)                         |
| <8.6> (14bits)              | bfly12 (16bits) * TW<2.7>        | bfly22 (17bits)                  |
| ↓ (sat)                     | ↓                                | ↓ (sat)                          |
| <7.6> × TW<2.7>             | bfly12 (25bits)                  | bfly22 (16bits)                  |
| ↓                           | ↓ (CBFP)                         | ↓ (CBFP)                         |
| <9.13>                      | bfly12 (12 bits)                 | <9.4> bfly22 (13 bits)           |
| ↓ (CBFP)                    |                                  |                                  |
| bfly02 (11 bits)            |                                  |                                  |

---

### 🏗️ FFT 구조

| **Algorithm Diagram** | **FFT Block Diagram** |
| :-----------: | :-----------: |
| ![Butterfly Algorithm](img/bf_algorithm.png) | ![FFT Block Diagram](img/fft_block_diagram.png) |

---

### 🔎 검증 및 시뮬레이션

🔎 **RTL Level 검증 (Synopsys 시뮬레이션)**

- 주요 모듈: Butterfly 단위 연산, 파이프라인 레지스터, Twiddle ROM, 제어 로직, BFP/CBFP 모듈 등  
- 데이터 흐름, 제어 신호, 모듈 인터페이스 및 역할 설명  

---

🔎 **Gate Level 검증 (Synopsys 시뮬레이션)**
- 합성 도구 (예: Synopsys Design Compiler) 사용  
- 면적(area), 타이밍(timing), 파워 및 클록 제약 등 분석 

---

🔎 **FPGA 검증 (Vivado 시뮬레이션)**
- FPGA에서의 실제 동작 시험, 리소스(utilization)

---

### 🛠️ Trouble Shooting

---

### 🧠 고찰 및 개선 점

```
Area 개선
Clock 줄이기
Code 최적화
```


---





