import gleam/erlang/process
import gleam/otp/actor
import gleam/otp/supervision

pub type Msg {
  Inc
  Read(reply: process.Subject(Int))
  Crash
}

fn handle(n: Int, msg: Msg) -> actor.Next(Int, Msg) {
  case msg {
    Inc -> actor.continue(n + 1)
    Read(reply) -> {
      process.send(reply, n)
      actor.continue(n)
    }
    Crash -> {
      panic as "boom!"
    }
  }
}

pub fn supervised(
  name: process.Name(Msg),
) -> supervision.ChildSpecification(process.Subject(Msg)) {
  supervision.worker(fn() {
    actor.new(0)
    |> actor.named(name)
    |> actor.on_message(handle)
    |> actor.start
  })
}
