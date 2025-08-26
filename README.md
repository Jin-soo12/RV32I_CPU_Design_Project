# RISC-V CPU Design (RV32I)
![language](https://img.shields.io/badge/HDL-SystemVerilog-blue?style=flat-square)
![language](https://img.shields.io/badge/Software-C-green?style=flat-square)

---

## 목차
- [개요](#개요)
- [설계 목표](#설계-목표)
- [아키텍처](#아키텍처)

---

## 개요
**RISC**  
RISC는 *Reduced Instruction Set Computer*의 약어로, 간소화된 명령어셋을 가진 컴퓨터 아키텍처입니다. CISC와 달리 명령어 수가 적고 구조가 단순하여 CPU 설계 학습에 매우 적합합니다.

**하버드 구조**  
한 저장장치가 Fetch/Store를 모두 하던 폰 노이만 구조와 달리, 명령어 메모리와 데이터 메모리를 분리하여 병목을 줄이고 파이프라인 구성을 용이하게 합니다.

<p align="center">
  <!-- 이미지/다이어그램 중앙 정렬 -->
  <img width="465" height="288" alt="image" src="https://github.com/user-attachments/assets/11455178-77b7-4268-98df-66b95ee38be2" />
</p>

---

## 🎯설계 목표
> RV32I 명령어셋의 이해 → CPU 설계 구현 → 시뮬레이션/검증  
최종 목표는 **전체 CPU 동작 원리 이해와 검증 완료** 입니다.

---

## 아키텍처
<p align="center">
  <img width="1465" height="895" alt="image" src="https://github.com/user-attachments/assets/05a19830-1b96-4832-8ac0-2b57fb5a72cb" />
</p>

기본적으로 하버드 구조 및 Multi Cycle 구조로 설계하였습니다. Multi Cycle 구조는 기존 Single Cycle에 비해 보다 효율적인 Clock 사용을 할 수 있게 해줍니다. Single Cycle의 경우 CPU의 모든 로직이 Combinatinal Logic으로 이루어져 있어 Critical Path가 길어질 경우 소요되는 한 Clock이 매우 길어진다는 단점을 가지고 있습니다. 이 부분을 보완하고자 특정 기능을 하는 부분마다 
F/F을 넣어주어 각 Clock마다 정해진 역할 **(Fetch, Decode, Execute, Memory Access, Write Back)** 만 수행할 수 있도록 **Multi Cycle**구조로 구현하였습니다.

<p align="center">
    <img width="1522" height="937" alt="image" src="https://github.com/user-attachments/assets/a2a5493a-7bd0-4d0f-8f35-a5d58df316a5" />
</p>
