-module(erlang_utils_ffi).

-export([to_actor_variant_name/1]).

%% @doc Convert a variant function to a string.
%% gleam에서는 타입 variant가 tagged tuple로 표시가 된다
%% {tag_name, 안에 담은 데이터}
%% 따라서 이 함수에는 variant 함수를 호출해주고 (파라미터는 subject로 이미 정해진 상태이다)
%% 그러면 타입 이름과 안에 담은 데이터가 나오는데 이 데이터는 무시하고 타입 이름만 문자열로 변환해서 반환한다
to_actor_variant_name(Varfn) ->
    {Name, {_, _}} = Varfn({nil, nil}),
    atom_to_binary(Name).
