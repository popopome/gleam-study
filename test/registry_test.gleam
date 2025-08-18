import gleam/erlang/process.{type Subject}
import gleam/otp/actor
import gleeunit/should
import registry/registry

type MsgA

type MsgB

type Actors {
  ActorA(Subject(MsgA))
  ActorB(Subject(MsgB))
}

pub fn registry_test() {
  let assert Ok(reg) = registry.start()

  let assert Ok(actor_a) =
    actor.new(Nil)
    |> actor.on_message(fn(state, _msg: MsgA) { actor.continue(state) })
    |> actor.start

  let assert Ok(actor_b) =
    actor.new(Nil)
    |> actor.on_message(fn(state, _msg: MsgB) { actor.continue(state) })
    |> actor.start

  registry.register(reg.data, ActorA, actor_a.data)
  registry.register(reg.data, ActorB, actor_b.data)

  let assert ActorA(got_a) = registry.require(reg.data, ActorA, 1000)
  let assert ActorB(got_b) = registry.require(reg.data, ActorB, 1000)

  should.equal(got_a, actor_a.data)
  should.equal(got_b, actor_b.data)
}
