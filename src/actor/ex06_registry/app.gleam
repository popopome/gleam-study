import gleam/erlang/process.{type Subject}
import gleam/otp/actor
import gleam/otp/static_supervisor as ssup
import gleam/otp/supervision.{type ChildSpecification}
import gleam/result
import registry/registry

type Msg {
  Inc
  Read(reply: Subject(Int))
}

type Actors {
  Counter(Subject(Msg))
}

fn supervised_with_registry(reg) -> ChildSpecification(Subject(Msg)) {
  supervision.worker(fn() {
    actor.new(0)
    |> actor.on_message(fn(n, msg) {
      echo msg
      case msg {
        Inc -> actor.continue(n + 1)
        Read(reply) -> {
          process.send(reply, n)
          actor.continue(n)
        }
      }
    })
    |> actor.start
    |> result.map(fn(started) {
      registry.register(reg, Counter, started.data)
      started
    })
  })
}

pub fn main() {
  let assert Ok(reg_started) = registry.start()
  let reg = reg_started.data

  let assert Ok(_sup) =
    ssup.new(ssup.OneForOne)
    |> ssup.add(supervised_with_registry(reg))
    |> ssup.start

  let Counter(counter) = registry.require(reg, key: Counter, timeout_ms: 2000)

  process.send(counter, Inc)
  process.send(counter, Inc)

  let value = actor.call(counter, waiting: 2000, sending: Read)
  echo value
}
