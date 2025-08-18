import actor/ex04_supervisor/counter_actor
import gleam/erlang/process
import gleam/io
import gleam/otp/static_supervisor
import gleam/otp/supervision

pub fn main() {
  let name = process.new_name("counter")
  let assert Ok(_started) =
    static_supervisor.new(static_supervisor.OneForOne)
    |> static_supervisor.add(
      counter_actor.supervised(name)
      |> supervision.timeout(5000),
    )
    |> static_supervisor.start

  let inbox = process.named_subject(name)
  process.send(inbox, counter_actor.Inc)
  process.send(inbox, counter_actor.Inc)
  process.send(inbox, counter_actor.Inc)

  let n1 = process.call(inbox, 100, counter_actor.Read)
  echo n1

  io.println("crash!!!!")
  process.send(inbox, counter_actor.Crash)

  process.sleep(250)

  let n2 = process.call(inbox, 100, counter_actor.Read)
  echo n2
}
