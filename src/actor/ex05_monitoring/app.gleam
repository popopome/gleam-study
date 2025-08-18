import gleam/erlang/process
import gleam/io
import gleam/otp/actor

pub type Msg {
  Ping(reply: process.Subject(String))
  Crash
}

pub type Ev {
  FromActor(Msg)
  FromDown(process.Down)
}

fn handle(state: Nil, msg: Msg) -> actor.Next(Nil, Msg) {
  case msg {
    Ping(r) -> {
      process.send(r, "pong")
      actor.continue(state)
    }
    Crash -> actor.stop_abnormal("by user request")
  }
}

pub fn main() {
  // 부모가 링크되어 있으니까 종료 시그널을 받아도 같이 죽지 않도록 설정해둠
  process.trap_exits(True)

  let assert Ok(started) =
    actor.new(Nil)
    |> actor.on_message(handle)
    |> actor.start

  let pid = started.pid
  let inbox = started.data

  let mon = process.monitor(pid)

  let sel =
    process.new_selector()
    |> process.select_map(inbox, FromActor)
    |> process.select_specific_monitor(mon, FromDown)

  process.send(inbox, Crash)

  let assert Ok(ev) = process.selector_receive(from: sel, within: 1000)
  echo ev
  case ev {
    FromDown(process.ProcessDown(_, _, reason)) ->
      io.println(
        "DOWN: "
        <> case reason {
          process.Normal -> "normal"
          process.Killed -> "killed"
          process.Abnormal(_) -> "abnormal"
        },
      )

    FromActor(_) -> io.println("actor message")
    _ -> Nil
  }
}
