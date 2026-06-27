<a id="top"></a>

<div align="center">

<img src="https://dryforge.vercel.app/assets/icon-1024.png" width="84" height="84" alt="dryforge" />

# dryforge

### Claude Code와 Codex를 위한 올인원 플러그인 하네스.

<h2>Your agent works like a <strong>senior developer.</strong></h2>

<p><strong>One workflow that turns intent into verified changes and carries project knowledge forward.</strong></p>

<p>
  <a href="https://dryforge.vercel.app"><img alt="Website" src="https://img.shields.io/badge/website-dryforge.vercel.app-111111?style=flat-square"></a>
  <img alt="Claude Code" src="https://img.shields.io/badge/Claude%20Code-supported-6f4ad2?style=flat-square">
  <img alt="Codex" src="https://img.shields.io/badge/Codex-supported-0f172a?style=flat-square">
  <img alt="License MIT" src="https://img.shields.io/badge/license-MIT-blue?style=flat-square">
</p>

<p>
  <a href="#install">설치</a> ·
  <a href="#command-loop">Command Loop</a> ·
  <a href="#intent-realization">Intent Realization</a> ·
  <a href="#project-harness">Project Harness</a> ·
  <a href="#migration">Migration</a> ·
  <a href="./README.md">English</a>
</p>

</div>

<a id="install"></a>

## 설치 및 업데이트

Claude Code

```text
/plugin marketplace add fn-opt/dryforge
/plugin install dryforge
```

Codex

```text
codex plugin marketplace add fn-opt/dryforge
codex plugin add dryforge@dryforge
```

Auto update

Codex는 새 세션을 시작할 때마다 새 릴리스를 확인하고 자동으로 반영한다.

Claude Code는 `/plugins -> installed -> dryforge -> auto-update`를 켜야 자동 업데이트가 적용된다. 켜지 않았다면 아래 명령으로 직접 업데이트한다.

```text
# Claude Code
/plugin marketplace update dryforge
/plugin update dryforge@dryforge

# Codex
codex plugin marketplace upgrade dryforge
```

## Bounded Autonomy Architecture

dryforge의 중심 원리는 **bounded autonomy**다. 모델에게 생각하고, 계획하고, 병렬화하고, 실행할 권한은 준다. 대신 사용자의 의도를 마음대로 정할 권한은 주지 않는다.

대부분의 에이전트 도구는 두 방향 중 하나로 실패한다. 순정 모델은 너무 느슨해서 사용자의 말을 잘못 해석하고, 그 오해를 충실히 만족시킨다. 반대로 지나치게 prescriptive한 하네스는 모델을 실제 작업이 아니라 wrapper, checklist, guardrail 달성에 최적화시킨다.

dryforge의 해법은 **floor, not ceiling**이다. 모델이 반드시 지켜야 할 최소 구조만 고정한다: 검증된 의도, 권위 위계, 실행 그래프, evidence floor, durable project memory. 그 안에서는 모델이 충분히 추론하고 판단하게 둔다. 모델이 강해질수록 더 세게 묶을 필요가 없다. 기준선만 정확히 잡으면 된다.

그 기준선은 에이전트가 자주 탈선하는 지점에 맞춰져 있다. `ready`는 spec을 쓰기 전에 decision surface를 드러내서, 중요한 미결정이 "그럴듯한 기본값"으로 조용히 넘어가지 못하게 한다. `go`는 작업을 다시 계획하지 않고 승인된 dependency graph를 따른다. 검증은 self-report가 아니라 captured evidence를 요구한다. review와 gate는 목표가 아니라 안전장치다.

기준선은 많이 세우는 게 아니라 정확히 맞춘다. 입력이 부족하면 산출물을 대충 만드는 게 아니라 elicitation 기준을 올린다. 도메인 결정은 사용자에게 확인하고, 기술 결정은 trade-off와 함께 제시한다. 큰 의미가 없는 tuning value는 구현 단계에서 처리한다. 실행도 같은 원리로 right-sized된다. 낮은 리스크의 작업은 직접 처리하고, 위험하거나 병렬인 작업은 격리한다. 그래도 모든 실행 경로의 evidence 기준은 같다.

| 실패 압력 | dryforge의 대응 |
|---|---|
| 모델이 사용자 의도를 추측한다 | `ready`가 spec을 쓰기 전에 이해된 의도와 근거 없는 default를 분리한다 |
| 하네스 자체가 달성 목표가 된다 | 결론을 과하게 처방하지 않고 권위 경계를 고정한다 |
| 모델이 쉬운 checklist 경로를 탄다 | 완전성과 conformance를 앞단에서 책임지고, review는 안전망으로 둔다 |
| 병렬 작업이 서로 다른 방향으로 흐른다 | plan이 의존성을 한 번만 인코딩하고, `go`는 그 graph를 실행한다 |
| "괜찮아 보임"이 증거를 대체한다 | command output, diff, runtime smoke, 명시적 evidence를 기준으로 검증한다 |

권위는 나뉘어 있다. **의도는 사용자에게 있다.** **동작은 spec이 정한다.** **스케줄링은 plan이 정한다.** **검증은 evidence로 한다.** **durable knowledge는 project harness에 남긴다.**

```text
conventional loop: prompt -> implementation -> correction -> lost context

dryforge loop:     elicited intent -> executable contract -> evidence-backed execution -> durable project state
```

결국 모델을 더 좁게 가두는 게 아니다. 모델의 추론 능력이 실제 작업으로 향하도록 기준선을 잡는 일이다. 보상해킹과 게으름을 막을 만큼의 구조, 추론을 살릴 만큼의 자유를 동시에 둔다.

## Failure Model

코딩 에이전트는 이미 충분히 잘 만든다. 문제는 모델의 능력보다 작업이 흘러가는 방식에 있다.

일반 에이전트는 불완전한 prompt에서 출발한다. 빠진 결정을 그럴듯한 default로 채우고, 그 default를 사용자의 의도처럼 구현한다. 검증도 자기 관점에서 끝내고, 이유는 세션이 끝나면 사라지는 transcript에 남긴다.

다음 세션에는 코드가 남아 있지만, 코드는 결과만 보여준다. 어떤 trade-off를 왜 택했는지, 어떤 edge case를 의도적으로 제외했는지, auth check가 전체 정책인지까지는 알 수 없다.

dryforge는 코드가 생기기 전, 실행 중, 실행 후의 세 지점에서 이 실패를 막는다. 실제 의도를 추출하고 executable contract로 고정한다. 그 contract 안에서 실행하고, captured evidence로 검증하고, 다음 에이전트가 읽는 위치에 durable project knowledge를 남긴다.

그래서 품질과 토큰 경제성이 동시에 개선된다. 잘못된 방향의 구현을 더 일찍 잡고, correction loop를 줄이고, 프로젝트 맥락을 매번 다시 설명하지 않아도 된다.

## One Agent Workflow

dryforge는 사람들이 코딩 에이전트 주변에 따로 붙이던 planning mode, deep-interview prompt, ad-hoc project harness, AGENTS convention, memory file, review checklist, parallel runner를 하나의 워크플로로 대체한다.

| 기존에 따로 쓰던 것 | dryforge에서 맡는 역할 |
|---|---|
| planning prompt | **`ready` implicit-decision discovery** |
| deep-interview workflow | **intent-first elicitation** |
| spec generator | **executable contract** |
| parallel runner | **dependency-aware `go` execution** |
| restrictive guardrails | **bounded autonomy that keeps reasoning on-task** |
| project memory file | **committed project harness와 local contract archive** |
| hand-written agent instructions | generated `CLAUDE.md`, `AGENTS.md`, and module `AGENTS.md` |
| migration notes | **existing-project migration** |

중요한 점은 이 기능들이 단순히 한곳에 모인 게 아니라는 데 있다. 하나의 철학과 하나의 워크플로를 공유한다. dryforge는 모델이 자신의 추론 능력을 제대로 쓰기 위한 작업 조건을 만든다.

<a id="command-loop"></a>

## Command Loop

```text
/ready <INPUT>  ->  /go  ->  working software + the project harness

Already have running code?
/migration brings the project into the dryforge harness first.
```

| Command | Consumes | Boundary | Produces |
|---|---|---|---|
| `/dryforge:ready` | 아이디어, spec, plan, 메모, 섞인 입력, 또는 아직 아무것도 없는 상태 | 사용자 의도는 elicitation과 승인 이후에만 기준이 된다 | executable contract |
| `/dryforge:go` | 승인된 contract | 승인된 spec 안에서만 자율적으로 실행한다 | 검증된 구현, harness update, archived contract |
| `/dryforge:migration` | 기존 코드베이스 | 잘못 추론했을 때 비용이 큰 지점은 코드만 보고 확정하지 않는다 | 첫 project harness, 이후 `ready -> go` |

짧은 alias로 `/ready`, `/go`, `/migration`도 사용할 수 있다.

<a id="intent-realization"></a>

## Intent Realization

`ready`는 dryforge의 시작점이자, 일반 planning tool과 dryforge를 갈라놓는 핵심 기능이다.

대부분의 planning tool은 사용자가 이미 말할 수 있었던 내용을 정리한다. deep-interview prompt는 더 나은 질문을 던지지만, 여전히 질문 목록이나 brainstorming pattern, 입력에 보이는 내용에서 출발한다.

`ready`는 목표가 암시하지만 사용자가 아직 말하지 않은 것을 찾는다.

모든 입력은 ground truth가 아니라 material로 취급한다. 한 줄 아이디어, 요구사항 문서, 모델이 만든 plan, 설계 메모, 흩어진 노트는 모두 유용하지만 그대로 믿지는 않는다. 사용자의 의도로 검증되기 전까지 기준이 아니다.

핵심 메커니즘은 **decision surface accounting**이다. 설계가 반드시 답해야 하는 load-bearing decision을 내부적으로 열거한다. 엔티티, 액터, 상태, 관계, 생명주기, edge case, 기술 형태, 정책 안에 숨어 있는 선호값은 그럴듯하게 채울 빈칸이 아니라 반드시 확정해야 할 결정이다.

조용한 default는 종료 상태가 아니다.

이것이 이해와 추측의 차이다. 사용자의 목표와 제약만으로 결정할 수 있는 내용은 `ready`가 다시 묻지 않고 반영한다. 근거가 없다면 합리적인 default를 고르고 넘어가지 않는다. 도메인 결정은 사용자에게 확인하고, 기술 결정은 구체적인 옵션과 trade-off, 추천안을 함께 제시한다.

`ready`의 장점은 질문량이 아니다. 더 많이 내부적으로 열거하고, 도출 후에도 남는 질문만 묻는다. 사용자는 낮은 가치의 질문을 덜 받고, 나중에 비싼 잘못된 가정이 될 질문을 더 많이 받는다.

정보가 적다고 기준을 낮추지 않는다. 오히려 더 엄격해진다. prompt에 신호가 적을수록 `ready`가 도출할 것은 줄고, 코드가 생기기 전에 빠진 결정을 드러낼 책임은 커진다.

출력은 더 예쁜 plan이 아니다. 사용자가 뜻한 것을 담은 executable contract다.

## Executable Contract Layer

`ready`는 `.dryforge` 아래에 세 개의 plain file을 만든다.

| Document | Role |
|---|---|
| `spec` | **무엇을 만들지에 대한 기준**: behavior, invariant, edge case, API surface, required verification |
| `plan` | **구현 blueprint**: behavioral task contract와 machine-readable execution graph |
| `handoff` | **실행 기준 문서**: document role, execution boundary, execution shape, non-derivable intent |

contract는 유연한 prose와 엄격한 scheduling core를 함께 둔다. prose에는 의도와 제약을 담고, execution graph는 machine-parsed되어 `go`가 dependency를 다시 추측하지 않고 작업을 스케줄링한다.

권위 위계는 명확하다. Spec은 plan보다 우선하고, 기존 코드보다도 우선한다. Spec이 틀린 것처럼 보이면 에이전트가 조용히 고치지 않는다. 사용자에게 돌아온다.

첫 cycle에서는 `handoff`가 첫 harness를 만들기 위한 project-wide foundation까지 포함한다. 이후 cycle에서는 harness가 프로젝트 맥락을 제공하고, contract는 현재 변경에 집중한다.

미래의 에이전트가 코드만 보고 다시 도출할 수 없는 결정은 contract 안에 이유를 남긴다. 그래서 원래 대화가 없어도 실행이 이어진다.

## Spec-Bound Execution

`go`는 승인된 contract를 읽고 그 시점부터 실행을 맡는다. 에이전트는 spec boundary 안에서만 자율적이다. 사용자의 의도 자체를 다시 정하지 않는다.

plan의 dependency graph가 scheduling truth다. `go`는 비싼 작업을 시작하기 전에 graph를 검증하고, 그 graph에서 작업 순서를 만든다. 방향이 고정된 뒤에만 독립 작업을 병렬로 실행한다. 승인된 의도 아래의 parallelism은 유용하다. 병렬 추측은 아니다.

리스크에 따라 검증 깊이를 조절한다. 기계적인 rename과 상태가 얽힌 edge-case 구현은 같은 프로세스를 가질 필요가 없다. 낮은 리스크의 순차 작업은 직접 처리할 수 있다. 위험하거나 병렬인 작업은 격리, 독립 implementer, merge control, 더 강한 verification을 거친다. 최적화는 overhead를 줄이는 것이지 evidence requirement를 줄이는 것이 아니다.

Self-report는 완료가 아니다. 구현자가 끝났다고 말해도 끝난 것이 아니다. `go`는 commit, diff, declared target, command output, exit code, spec이 live behavior를 요구할 때의 runtime smoke를 확인한다. assertion까지 가지 못하고 죽은 verification command는 pass가 아니라 failure다.

`go`가 막히면 빠진 답을 지어내지 않는다. 맥락과 함께 escalate한다. Bounded autonomy는 승인된 boundary 안에서는 빠르게 움직이고, boundary에 닿으면 멈추는 방식이다.

기존 프로젝트도 보호한다. `go`는 올바른 branch에서 작업하고, dirty하거나 unsafe한 base state를 거부하며, 최종 integration은 사용자가 통제하게 둔다.

검증과 최종 사용자 승인 후 `go`는 project harness를 업데이트하고 active contract를 `.dryforge/NNN/` 아래에 보관한다. 다음 cycle은 오래된 root contract가 아니라 harness에서 시작한다.

## Reward-Hack Resistance

이것은 review add-on이 아니라 dryforge의 핵심 설계 선택이다.

하네스가 에이전트의 목표가 되어서는 안 된다. 지시가 너무 좁으면 모델은 사용자가 아니라 wrapper를 만족시키는 법을 배운다. 지시가 너무 느슨하면 모델은 사용자 의도를 추측하고 그 추측에 최적화된다. dryforge는 모델의 힘을 살리면서 권위 경계를 명확히 한다.

`ready`는 contract가 생기기 전에 intent를 확정한다. decision surface는 spec 작성 전에 닫혀야 한다. 그래야 모델이 잘못 해석한 내용을 자신 있게 구현하는 쪽으로 보상받지 않는다.

`go`도 실행 중 같은 규칙을 따른다. 승인된 spec 안에서는 빠르게 움직일 수 있지만, task를 편한 해석이나 checklist 모양의 shortcut으로 바꿀 수는 없다.

목표는 더 많은 guardrail이 아니다. 모델이 하네스를 우회하거나 하네스를 만족시키는 법을 배우게 하는 것이 아니라, 모델의 추론이 실제 작업으로 향하게 만드는 harness다.

<a id="project-harness"></a>

## Durable Project Memory

실행 후 dryforge는 project harness를 작성하거나 갱신한다. 다음 에이전트가 가장 먼저 읽는 durable documentation layer다. 완료된 프로젝트에는 cycle 기록과 initialization marker를 담는 local `.dryforge/` 작업 공간도 함께 생긴다.

프로젝트에 남는 harness:

```text
your-project/
├── CLAUDE.md
├── AGENTS.md
├── docs/
│   ├── architecture.md
│   ├── business-rules.md
│   ├── security.md
│   ├── standards.md
│   ├── engineering-notes.md
│   ├── operations.md
│   ├── contracts.md
│   └── tracking/
│       ├── status.md
│       ├── decisions/
│       └── findings.md
└── <module>/AGENTS.md
```

Local `.dryforge` 작업 공간:

```text
your-project/.dryforge/
├── 001/
│   ├── handoff.md
│   ├── spec.md
│   └── plan.md
└── status.json
```

Harness는 Claude Code와 Codex가 이미 읽는 entry path에 저장되는 committed project knowledge다. 한 세션, 한 host, 한 에이전트의 private memory에 갇히지 않고 프로젝트에 남는다.

Harness는 코드가 잘 담지 못하는 것을 기록한다: intent, domain rule, security policy, 운영 절차, trap, decision, 그리고 그 이유.

`.dryforge/`는 local cycle 작업 공간이자 보관소다. 완료된 contract snapshot과 local initialization marker는 여기에 남고, committed harness는 프로젝트가 읽는 문서층으로 남는다.

Harness는 옮겨도 쓸 수 있다. 생성된 프로젝트 문서는 dryforge가 없어도 유효하다. 나중에 dryforge를 제거해도 표준 entry file, plain Markdown, 다음 에이전트가 읽을 프로젝트 지식은 그대로 남는다.

<a id="migration"></a>

## Existing-Project Onboarding

dryforge는 greenfield뿐 아니라 기존 코드베이스에도 바로 붙일 수 있게 만들었다.

기존 프로젝트에는 코드, convention, 오래된 README, 손으로 쓴 AGENTS instruction, stale plan, tacit owner knowledge가 이미 있다. `migration`은 코드베이스를 읽고, 기존 문서는 reference material로 다루며, 코드가 증명하는 것과 owner만 확인할 수 있는 것을 분리한다.

코드를 보면 authorization check가 무엇을 하는지는 알 수 있다. 하지만 그것이 전체 정책인지는 증명하지 못한다. state field도 마찬가지다. 필드가 있다는 사실만으로 어떤 transition이 비즈니스상 금지되는지는 알 수 없다. `migration`은 잘못 추론하면 프로젝트가 깨지는 지점을 묻는다.

결과는 같은 project harness다. `migration` 이후의 작업은 일반적인 `ready -> go` loop로 이어진다. 다른 도구, prompt pack, 수동 memory file, 문서화되지 않은 팀 습관으로 만들어진 프로젝트를 dryforge 체계로 옮겨오는 진입로다.

## Quality and Cost Model

dryforge가 효율적인 이유는 얕게 일해서가 아니라 중복 작업을 없애기 때문이다.

일반 에이전트는 같은 비용을 반복해서 낸다. 프로젝트를 추론하고, 빠진 의도를 추측하고, 그 추측을 구현하고, 지적받고, 다시 쓴다. 세션이 끝나면 이유를 잃고, 다음 세션은 더 적은 단서로 다시 시작한다.

dryforge는 clarification cost를 한 번 지불하고, 그 결과를 executable contract로 만든다. 실행은 그 contract에 맞춰 진행하고, 재사용 가능한 project knowledge는 harness에 저장한다.

그래서 품질과 비용이 함께 좋아진다. 잘못된 방향의 build가 줄어 rewrite가 줄고, 반복 설명이 줄어 context token도 줄어든다. planning, execution, review, memory 사이의 경계가 줄어 다른 도구가 다시 해석할 summary도 줄어든다.

목표는 덜 해서 싸게 만드는 게 아니다. 같은 discovery, correction, context reconstruction에 계속 비용을 내지 않게 만드는 것이다.

## Usage Notes

dryforge는 명시적으로 호출할 때만 실행된다. 기능 개발, 프로젝트 셋업, migration, 잘못된 가정의 비용이 큰 작업에 가장 잘 맞는다. 아주 작은 기계적 수정에는 전체 loop가 필요하지 않을 수 있다.

Claude Code와 Codex 빌드는 하나의 platform-neutral source에서 나온다. 사용자에게 보이는 output은 사용자의 언어를 따르고, stack detail은 실행 시 프로젝트를 읽어 발견한다.

## Requirement

**git is required.**

## License

MIT

<div align="center"><sub><a href="#top">back to top</a> · ready / go / migration</sub></div>
