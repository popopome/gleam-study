# Actor - 슈퍼바이저

`Supervision` 트리를 이용해서 `Actor`를 실행시킨다. 
`supervision.worker`를 이용해서 자식 프로세스를 실행시킬 명세를 생성한다.
이제 이 명세를 `static_supervisor`를 사용해서 구동시킨다.
여기 `restart_tolerance`를 사용하면 조금 더 세밀하게 재식작을 안하고 
포기하는 정책을 세울 수가 있다.

* `OneForOne` 전략을 사용하면 `Permanent` 재시작 정책 때문에 `Crash`로
   비정상 종료가 되면 그 자식만 초기 상태로 재시작된다.
* `panic as `로 해당 프로세스는 스스로 크래쉬할 수 있다.