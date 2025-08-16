# Actor 

## Actor란?
gleam에서 BEAM 프로세스를 기반으로 상태를 가지고 메시지를 처리하는 완전히 독립된
실행 단위입니다. Erlang OTP의 `gen_server`와 대응하는 빌딩 블럭입니다.
하지만 특별히 완전히 타잎 안전한 인터페이스를 제공합니다.

### 핵심 API들
* `actor.new` - 초기 상태 정보를 가지고 `Actor`를 생성합니다
* `actor.on_message` - 메시지 핸들러를 등록합니다
* `actor.start` - BEAM 프로세스를 시작합니다
* `actor.call` - 동기로 호출하는 RPC입니다
* `actor.send` - 메시지를 대상 actor에게 호출합니다


## 예제 - 가장 작은 카운터 Actor

Actor는 단일 스레드적으로 메시지를 순서대로 처리합니다.
Actor 핸들러에서는 메시지를 받고 처리합니다. 각 처리 후에는 그 다음 상태를 `actor.Next` 타잎으로
돌려주어야 합니다. `actor.continue`는 계속 처리를 하는 것을 나타냅니다. 바로 종료하고 싶다면
`actor.stop`을 돌려줍니다.

주의 깊게 볼 내용은 `actor.start`가 `Actor.Started`를 돌려줍니다. 성공한
경우에 이 값에서 해당 `actor`에게 보낼 수 있는 `Subject`를 돌려줍니다.

