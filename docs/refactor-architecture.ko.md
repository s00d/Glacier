# Glacier 리팩터링 구조안

작성일: 2026-03-13

## 문서 역할

- 이 문서는 현재 단일 파일 중심 구조를 어떻게 나눌지 제안한다.
- 목적은 테스트 가능성, 안정성, 책임 분리를 높이는 것이다.

## 현재 구조 문제

현재 구현은 하나의 컨트롤러가 다음을 모두 담당한다.

- 상태 관리
- `NSStatusItem` 생성
- 위치/길이 조작
- 입력 해석
- 이벤트 모니터 등록
- 메뉴 구성

이 구조는 작을 때는 읽기 쉽지만, 예외 규칙이 늘면 빠르게 취약해진다.

## 목표 구조

리팩터링 후에는 다음 다섯 레이어로 나눈다.

### 1. `GlacierStateMachine`

책임:

- 현재 제품 상태 보유
- 입력을 상태 전이로 변환
- 순수 로직 유지

입력 예:

- primaryClick
- alternateClick
- escape
- outsideDismiss
- enterEditing
- exitEditing

출력 예:

- nextState
- sideEffects intention

### 2. `MenuBarLayoutController`

책임:

- 상태에 맞는 메뉴바 레이아웃 적용
- separator 길이 변경
- marker 표시 상태 변경
- 위치 저장/복원 연계

주의:

- AppKit 해킹 성격의 코드는 이 레이어에만 격리한다.

### 3. `EventMonitorController`

책임:

- global/local monitor 시작/정지
- 어떤 입력을 dismissal로 해석할지 정책 적용
- 메뉴 사용 중 dismissal 금지 규칙 반영

### 4. `StatusItemViewController`

책임:

- `●`, `◆`, 컨텍스트 메뉴 구성
- 아이콘/상태 표시 업데이트
- 사용자 액션을 상위 레이어에 전달

### 5. `RecoveryController`

책임:

- reset
- first-run help
- diagnostics
- 잘못된 상태 감지 시 복구 흐름 제공

## 데이터 흐름

권장 흐름:

1. 사용자 입력 발생
2. `StatusItemViewController` 또는 `EventMonitorController`가 입력 수집
3. `GlacierStateMachine`이 다음 상태 계산
4. `MenuBarLayoutController`가 실제 UI 적용
5. 필요한 경우 `RecoveryController`가 보조 동작 처리

## 테스트 전략

### 순수 로직 테스트

대상:

- `GlacierStateMachine`

검증:

- Closed + primaryClick -> HiddenOpen
- HiddenOpen + alternateClick -> AllOpen
- HiddenOpen + itemInteraction -> HiddenOpen 유지
- Editing + complete -> Closed

### 통합 테스트

대상:

- `MenuBarLayoutController`
- `EventMonitorController`

검증:

- monitor 시작/중지 타이밍
- 레이아웃 적용 순서
- reset 이후 기본 상태 복귀

## 단계별 리팩터링

### 1단계

- 상태 enum과 입력 enum 분리
- 상태 전이를 순수 함수로 추출

### 2단계

- 메뉴바 레이아웃 적용 코드를 별도 타입으로 분리

### 3단계

- 이벤트 모니터 등록/해제 로직 분리

### 4단계

- 사용법, reset, 편집 진입을 recovery/navigation 영역으로 분리

### 5단계

- 시각 상태 표현 정리

## 설계 원칙

- 상태 계산은 순수하게
- AppKit 부수효과는 한곳에
- 이벤트 해석과 UI 적용을 분리
- reset과 help는 별도 복구 축으로 유지

## 최종 정리

리팩터링의 목표는 코드를 멋지게 만드는 것이 아니다.

목표는 다음 두 가지다.

1. 펼친 뒤 실제 사용 가능한 동작을 안정적으로 유지하는 것
2. 앞으로 정책이 늘어나도 한 파일에 모든 예외가 쌓이지 않게 하는 것
