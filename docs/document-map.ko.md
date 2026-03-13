# Glacier 문서 맵

작성일: 2026-03-13

이 문서는 Glacier 레포 안의 주요 문서가 각각 무엇을 설명하는지 정리한 안내서다.

## 원칙

Glacier 문서는 아래 세 층위로 나눈다.

1. 현재 배포 동작
2. 현재 구현 진단
3. 목표 제품 방향

이 세 층위를 섞어 쓰면 README와 기획 문서가 서로 충돌해 보이기 쉽다. 따라서 각 문서는 자기 역할만 명확히 담당한다.

## 문서 역할

### 1. README

대상 문서:

- [`README.ko.md`](/Users/fran/Workspace/Glacier/README.ko.md)
- [`README.md`](/Users/fran/Workspace/Glacier/README.md)

역할:

- 현재 레포의 배포 기준 동작 설명
- 현재 설치 방법 설명
- 현재 사용자에게 보여 주는 핵심 개념 설명

포함해야 하는 내용:

- 지금 실제로 동작하는 조작 방식
- 현재 설치/빌드 방법
- 현재 제품 소개

넣지 말아야 하는 내용:

- 아직 구현되지 않은 목표 UX
- 미래 버전의 편집 모드 설계
- 리팩터링 제안

### 2. 코드 평가 문서

대상 문서:

- [`code-evaluation.ko.md`](/Users/fran/Workspace/Glacier/docs/code-evaluation.ko.md)

역할:

- 현재 구현의 강점, 약점, 안정성 리스크 진단
- 왜 현재 코드가 제품 목적을 충분히 수행하지 못하는지 설명

포함해야 하는 내용:

- 구조 분석
- 이벤트 정책 문제
- AppKit 의존성 리스크
- 더 나은 설계 대안

넣지 말아야 하는 내용:

- 현재 제품 소개 문구
- 최종 사용자용 사용 설명서

### 3. 행동 동선 PRD

대상 문서:

- [`product-behavior-prd.ko.md`](/Users/fran/Workspace/Glacier/docs/product-behavior-prd.ko.md)

역할:

- 목표 제품의 행동 원칙과 UX 요구사항 정의
- 사용 모드, 편집 모드, 접힘 규칙, 성공 조건 정리

포함해야 하는 내용:

- 사용자가 어떤 흐름으로 앱을 써야 하는가
- 제품이 어떤 행동을 허용/금지해야 하는가
- 우선순위와 목표 상태

넣지 말아야 하는 내용:

- "현재 이미 이렇게 동작한다"는 단정
- 구현 세부 코드 분석

## 읽는 순서

새로 합류한 사람이면 다음 순서로 읽는 것이 좋다.

1. [`README.ko.md`](/Users/fran/Workspace/Glacier/README.ko.md) 또는 [`README.md`](/Users/fran/Workspace/Glacier/README.md)
2. [`code-evaluation.ko.md`](/Users/fran/Workspace/Glacier/docs/code-evaluation.ko.md)
3. [`product-behavior-prd.ko.md`](/Users/fran/Workspace/Glacier/docs/product-behavior-prd.ko.md)

이 순서는 각각 다음 질문에 답한다.

1. 지금 이 앱은 무엇인가
2. 지금 구현은 왜 부족한가
3. 앞으로 어떤 제품이 되어야 하는가

## 정합성 규칙

앞으로 문서를 수정할 때는 다음을 지킨다.

- README는 현재 동작만 쓴다.
- 코드 평가 문서는 현재 구현만 평가한다.
- PRD는 목표 상태만 정의한다.
- 현재와 목표가 다르면, README를 PRD에 맞춰 고치지 말고 차이를 명시한다.

## 최종 정리

Glacier 문서 체계는 아래처럼 이해하면 된다.

- README: 현재 배포 동작
- 코드 평가: 현재 구현 진단
- PRD: 목표 제품 방향

이 역할이 유지되면 문서 간 충돌이 크게 줄어든다.
