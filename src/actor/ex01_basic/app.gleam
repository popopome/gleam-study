import gleam/erlang/process
import gleam/otp/actor

pub type Msg {
  Add(Int)
  Get(reply: process.Subject(Int))
  Shutdown
}

type State =
  Int

fn handle(state: State, msg: Msg) -> actor.Next(State, Msg) {
  case msg {
    Shutdown -> actor.stop()

    Add(n) -> actor.continue(state + n)
    Get(reply) -> {
      process.send(reply, state)
      actor.continue(state)
    }
  }
}

pub fn main() {
  let assert Ok(started) =
    actor.new(0)
    |> actor.on_message(handle)
    |> actor.start

  let inbox = started.data

  process.send(inbox, Add(5))
  process.send(inbox, Add(3))

  let sum = actor.call(inbox, waiting: 100, sending: Get)
  echo sum
  process.send(inbox, Shutdown)
}
