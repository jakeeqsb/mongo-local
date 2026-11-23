# mongo-local

로컬 전용 MongoDB 환경 (Docker Compose profiles).

| Profile   | 구성                                   | 접속 |
|-----------|----------------------------------------|------|
| `single`  | mongod 1대                              | `mongodb://localhost:27017` |
| `rs`      | Replica Set `rs0` (3노드)               | `mongodb://mongo-rs1:27021,mongo-rs2:27022,mongo-rs3:27023/?replicaSet=rs0` |
| `sharded` | config RS 1 + shard 3 + mongos 1        | `mongodb://localhost:27030` |

## 실행

```bash
make single     # docker compose --profile single up -d --wait
make rs         # init 컨테이너 로그까지 따라감 (Ctrl+C로 빠져나와도 됨)
make sharded
make down       # 정지 (데이터 유지)
make clean      # 볼륨까지 삭제
```

## Replica Set 호스트 접속

RS 멤버는 컨테이너 호스트명으로 자신을 광고하므로, 호스트에서 `replicaSet=rs0`로 접속하려면 `/etc/hosts`에 추가:

```
127.0.0.1 mongo-rs1 mongo-rs2 mongo-rs3
```

hosts를 건드리기 싫으면 `mongodb://localhost:27021/?directConnection=true` 로 개별 노드에 접속.

## 구조

```
config/
  single/mongod.conf
  replicaset/mongod.conf        # 3멤버 공용, 포트는 --port 로 오버라이드
  sharded/configsvr.conf
  sharded/shard.conf            # 3샤드 공용, replSet 이름은 --replSet 로 지정
  sharded/mongos.conf
scripts/
  init-replicaset.js            # 멱등
  init-sharded.sh               # 멱등
```

설정 파일은 read-only bind mount 이므로 수정 후 `docker compose --profile <p> restart` 로 반영.
