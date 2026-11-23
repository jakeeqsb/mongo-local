DC := docker compose
ALL := --profile single --profile rs --profile sharded --profile atlas

.PHONY: single rs sharded atlas ps logs down clean

single:
	$(DC) --profile single up -d --wait

rs:
	$(DC) --profile rs up -d
	$(DC) --profile rs logs -f mongo-rs-init

sharded:
	$(DC) --profile sharded up -d
	$(DC) --profile sharded logs -f mongo-sharded-init

atlas:         ## Atlas Local (Search / Vector Search 포함), healthy 될 때까지 대기
	$(DC) --profile atlas up -d --wait

ps:
	$(DC) $(ALL) ps -a

logs:
	$(DC) $(ALL) logs -f

down:          ## 컨테이너만 정지/삭제 (데이터 유지)
	$(DC) $(ALL) down

clean:         ## 컨테이너 + 데이터 볼륨까지 삭제
	$(DC) $(ALL) down -v