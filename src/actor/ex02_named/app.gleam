import gleam/erlang/process
import gleam/otp/actor

pub type Msg {
  Ping(reply: process.Subject(String))
}

pub type State =
  Nil

fn handle(_state: State, msg: Msg) -> actor.Next(State, Msg) {
  case msg {
    Ping(reply) -> {
      process.send(reply, "pong")
      actor.continue(Nil)
    }
  }
}

pub fn start_named(name: process.Name(Msg)) {
  let assert Ok(_started) =
    actor.new(Nil)
    |> actor.on_message(handle)
    // 시작 시 이름 등록 시도(이름 중복이면 시작 실패)
    |> actor.named(name)
    |> actor.start
}

pub fn main() {
  let name = process.new_name("ping_server")
  let _ = start_named(name)

  let s = process.named_subject(name)
  let res = actor.call(s, 100, Ping)
  echo res
}
