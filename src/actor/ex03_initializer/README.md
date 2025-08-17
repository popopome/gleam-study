# Actor 초기화 로직과 다중 소스 수신

`new_with_initialiser`로 `actor` 시작 시에 준비 작업을 수행한다. 초기화
함수에는 기본 `Subject`가 전달된다. 그리고 이 함수에서 다중 `Subject`에서
메시지를 받을 수 있도록 `Selector`를 셋업할 수가 있다.
