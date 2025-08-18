// Singularity 소스 코드를 참고해서 옮겨온 간단한 레지스트리.
import gleam/dict.{type Dict}
import gleam/erlang/process.{type Monitor, type Pid, type Selector, type Subject}
import gleam/option.{None, Some}
import gleam/otp/actor

const require_retry_delay_ms = 100

pub opaque type State(wrap) {
  State(
    self: Subject(Msg(wrap)),
    selector: Selector(Msg(wrap)),
    actors: Dict(String, Actor(wrap)),
    times: Dict(String, #(Int, Int)),
  )
}

type Actor(wrap) {
  Actor(actor: wrap, pid: Pid, monitor: Monitor)
}

pub fn start() {
  actor.new_with_initialiser(100, fn(self: Subject(Msg(wrap))) {
    let selector =
      process.new_selector()
      |> process.select(self)

    let state = State(self:, selector:, actors: dict.new(), times: dict.new())

    state
    |> actor.initialised()
    |> actor.selecting(selector)
    |> actor.returning(state)
    |> Ok
  })
  |> actor.on_message(handle)
  |> actor.start
}

pub fn register(
  registry: State(wrap),
  key variant: fn(Subject(msg)) -> wrap,
  subject subj: Subject(msg),
) {
  let assert Ok(pid) = process.subject_owner(subj)
  let wrapped = variant(subj)
  let key = to_actor_variant_name(variant)
  process.send(registry.self, Register(key, wrapped, pid))
}

pub fn require(
  registry: State(wrap),
  key variant: fn(Subject(msg)) -> wrap,
  timeout_ms timeout: Int,
) -> wrap {
  let key = to_actor_variant_name(variant)
  actor.call(registry.self, timeout, Require(_, key, timeout))
}

pub opaque type Msg(wrap) {
  Require(reply_with: Subject(wrap), key: String, timeout: Int)
  Register(key: String, wrapped: wrap, pid: Pid)
  ActorExit(key: String, pdown: process.Down)
}

fn handle(
  state: State(wrap),
  msg: Msg(wrap),
) -> actor.Next(State(wrap), Msg(wrap)) {
  case msg {
    Require(reply_with, key, timeout) -> {
      get_with_retry(state, key, reply_with, timeout)
    }
    Register(key:, wrapped:, pid:) -> {
      let state = handle_register(state, key, wrapped, pid)
      state
      |> actor.continue()
      |> actor.with_selector(state.selector)
    }

    ActorExit(key, pdown: process.ProcessDown(_, pid, _)) -> {
      let state = remove(state, key, Some(pid))
      state
      |> actor.continue()
      |> actor.with_selector(state.selector)
    }

    ActorExit(_key, _pdown) -> actor.continue(state)
  }
}

fn handle_register(state: State(wrap), key: String, wrapped: wrap, pid: Pid) {
  let state = remove(state, key, None)

  let monitor = process.monitor(pid)
  let selector =
    state.selector
    |> process.select_specific_monitor(monitor, ActorExit(key, _))

  let actor = Actor(actor: wrapped, pid:, monitor:)
  let actors = dict.insert(state.actors, key, actor)
  State(..state, actors:, selector:)
}

fn remove(
  state: State(wrap),
  key: String,
  when_pid: option.Option(Pid),
) -> State(wrap) {
  let rm = fn(actor: Actor(wrap)) {
    process.demonitor_process(actor.monitor)
    let actors = dict.delete(state.actors, key)
    let selector = build_selector(state.self, actors)

    State(..state, actors: actors, selector: selector)
  }

  case dict.get(state.actors, key) {
    Ok(Actor(actor: _, pid: pid, monitor: _) as actor) if when_pid == Some(pid) ->
      rm(actor)

    Ok(actor) if when_pid == None -> rm(actor)
    Ok(_) -> state
    Error(Nil) -> state
  }
}

fn build_selector(
  self: Subject(Msg(wrap)),
  actors: Dict(String, Actor(wrap)),
) -> Selector(Msg(wrap)) {
  let base_selector =
    process.new_selector()
    |> process.select(self)

  dict.fold(over: actors, from: base_selector, with: fn(selector, key, actor) {
    process.select_specific_monitor(selector, actor.monitor, fn(pdown) {
      ActorExit(key, pdown)
    })
  })
}

fn get_with_retry(
  state: State(wrap),
  key: String,
  reply_with: Subject(wrap),
  millis timeout: Int,
) -> actor.Next(State(wrap), Msg(wrap)) {
  case dict.get(state.actors, key) {
    Ok(actor) -> {
      process.send(reply_with, actor.actor)
      Nil
    }
    Error(Nil) -> {
      case timeout > require_retry_delay_ms {
        True -> {
          process.send_after(
            state.self,
            require_retry_delay_ms,
            Require(reply_with, key, timeout - require_retry_delay_ms),
          )
          Nil
        }
        False -> Nil
      }
    }
  }

  actor.continue(state)
}

@external(erlang, "erlang_utils_ffi", "to_actor_variant_name")
fn to_actor_variant_name(v: fn(Subject(msg)) -> wrap) -> String
