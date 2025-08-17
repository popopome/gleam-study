import gleam/erlang/process
import gleam/otp/actor

pub type Msg {
  Tick
  Set(n: Int)
  Get(reply: process.Subject(Int))
}

type State {
  State(count: Int, tick: process.Subject(Msg))
}

/// Actor 초기화 함수
fn init(
  default_inbox: process.Subject(Msg),
) -> Result(actor.Initialised(State, Msg, process.Subject(Msg)), String) {
  // Tick subject를 생성해서 주기적으로 Tick message를 보내도록 셋팅
  let tick = process.new_subject()
  let _t = process.send_after(tick, 1000, Tick)

  // Selector를 사용해서 여러 채널에서 메시지를 수신하도록 함.
  // tick은 내부 에서 보내는 메시지
  // 외부에서 보내는 메시지도 같이 수신할 수 있음.
  let sel =
    process.new_selector()
    |> process.select(default_inbox)
    |> process.select(tick)

  actor.initialised(State(0, tick))
  // 커스텀 셀렉터 지정
  |> actor.selecting(sel)
  // 부모에게 넘겨줄 데이터(일반적으로 inbox)
  |> actor.returning(default_inbox)
  |> Ok
}

fn handle(state: State, msg: Msg) -> actor.Next(State, Msg) {
  case msg {
    Tick -> {
      let _ = process.send_after(state.tick, 1000, Tick)
      actor.continue(State(state.count + 1, state.tick))
    }
    Set(n) -> actor.continue(State(n, state.tick))
    Get(reply) -> {
      process.send(reply, state.count)
      actor.continue(state)
    }
  }
}

pub fn main() {
  let assert Ok(started) =
    actor.new_with_initialiser(2000, init)
    |> actor.on_message(handle)
    |> actor.start

  let inbox = started.data
  process.send(inbox, Set(10))
  let now = actor.call(inbox, 50, Get)
  echo now
}
