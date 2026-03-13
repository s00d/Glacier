# Glacier 상태 및 모드 설계

작성일: 2026-03-13

## 문서 역할

- 이 문서는 Glacier의 사용자 인지 상태와 내부 제품 상태를 정리한다.
- 구현 전에 상태 전이를 분명히 하기 위한 설계 문서다.

## 설계 목표

- 사용자 입장에서 상태가 이해 가능해야 한다.
- 제품 내부에서 상태 전이가 단순해야 한다.
- 사용 모드와 편집 모드가 섞이지 않아야 한다.

## 최상위 모드

Glacier는 두 개의 모드로 구분한다.

### 1. 사용 모드

목적:

- 숨긴 아이콘을 빠르게 꺼내고 사용하기

### 2. 편집 모드

목적:

- 구역과 marker를 조정하기

## 사용 모드 상태

### A. Closed

의미:

- 메뉴바가 정리된 기본 상태

화면 특징:

- `●`만 최소한으로 노출
- hidden / all 구역은 접힘

### B. HiddenOpen

의미:

- hidden 영역이 열려 실제 사용 가능한 상태

화면 특징:

- `●`가 열린 상태로 보임
- hidden 구역 아이콘 노출

### C. AllOpen

의미:

- always hidden 포함 전체가 열린 상태

화면 특징:

- `●`와 `◆` 모두 강조 가능
- 고급 사용 상태로 인식 가능

## 편집 모드 상태

### D. Editing

의미:

- 배치 조정이 우선되는 상태

화면 특징:

- 구역 의미 표시
- marker 강조
- 완료 / reset 진입점 노출

## 상태 전이 규칙

### Closed -> HiddenOpen

트리거:

- `●` 클릭

### Closed -> AllOpen

트리거:

- `Option + ●` 클릭

### HiddenOpen -> Closed

트리거:

- `●` 재클릭
- `Esc`
- 허용된 외부 종료 입력

### HiddenOpen -> AllOpen

트리거:

- `Option + ●` 클릭

### AllOpen -> Closed

트리거:

- `●` 클릭
- `Option + ●` 클릭
- `Esc`
- 허용된 외부 종료 입력

### Any Using State -> Editing

트리거:

- 우클릭 메뉴의 편집 모드 선택

### Editing -> Closed

트리거:

- 완료
- 취소
- reset 후 종료

## 상태 전이 표

| 현재 | 입력 | 다음 | 비고 |
|---|---|---|---|
| Closed | `●` 클릭 | HiddenOpen | 기본 진입 |
| Closed | `Option + ●` | AllOpen | 고급 진입 |
| HiddenOpen | `●` 클릭 | Closed | 명시적 종료 |
| HiddenOpen | `Option + ●` | AllOpen | 범위 확장 |
| HiddenOpen | `Esc` | Closed | 명시적 종료 |
| AllOpen | `●` 클릭 | Closed | 명시적 종료 |
| AllOpen | `Option + ●` | Closed | 명시적 종료 |
| Any | 편집 모드 진입 | Editing | 우클릭 메뉴 |
| Editing | 완료/취소 | Closed | 기본 복귀 |

## 시각 설계 원칙

### Closed

- 가장 작은 시각 노이즈
- 평상시 상태

### HiddenOpen

- "지금 사용 가능"이 보여야 함
- 닫힘과 확실히 구분

### AllOpen

- HiddenOpen보다 더 강한 상태 표현
- 고급 상태라는 차이 표시

### Editing

- 사용 상태와 명확히 분리
- 구역 라벨, reset, 완료가 보이게

## 텍스트 와이어프레임

### Closed

```text
[ ...hidden offscreen... ] ● [ visible items ]
```

### HiddenOpen

```text
[ ...always hidden offscreen... ] ◆ [ hidden items ] ● [ visible items ]
```

### AllOpen

```text
[ always hidden items ] ◆ [ hidden items ] ● [ visible items ]
```

### Editing

```text
[ always hidden ] ◆ [ hidden ] ● [ visible ]
  reset / done / help
```

## 상태 설계 원칙

- 상태 수는 적게 유지한다.
- 한 상태는 하나의 명확한 사용자 의도를 대표해야 한다.
- 상태 전이는 예측 가능해야 한다.
- 편집은 사용 흐름을 오염시키지 않아야 한다.

## 최종 정리

Glacier의 상태 설계는 복잡할 필요가 없다.

핵심은:

- 사용 모드와 편집 모드를 분리하고
- 사용 모드에서는 `Closed / HiddenOpen / AllOpen`
- 편집 모드에서는 `Editing`

이 네 상태만 명확히 유지하는 것이다.
