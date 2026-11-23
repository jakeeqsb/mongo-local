#!/bin/bash
# config RS / shard RS 초기화 후 mongos에 샤드 등록 (여러 번 실행해도 안전)
set -euo pipefail

init_rs() {
  local host=$1 port=$2 rs=$3 extra=${4:-}
  echo ">> ${rs} 초기화 (${host}:${port})"
  mongosh --host "$host" --port "$port" --quiet --eval "
    try { rs.status(); print('${rs}: already initialized'); }
    catch (e) {
      if (e.codeName !== 'NotYetInitialized') throw e;
      rs.initiate({ _id: '${rs}', ${extra} members: [{ _id: 0, host: '${host}:${port}' }] });
    }
    let i = 0;
    while (!db.hello().isWritablePrimary) {
      if (++i > 60) throw new Error('${rs}: PRIMARY 타임아웃');
      sleep(1000);
    }
    print('${rs}: PRIMARY ready');
  "
}

init_rs mongo-cfg1   27019 cfgrs  "configsvr: true,"
init_rs mongo-shard1 27018 shard1
init_rs mongo-shard2 27018 shard2
init_rs mongo-shard3 27018 shard3

echo ">> mongos 대기"
for i in $(seq 1 60); do
  if mongosh --host mongo-mongos --port 27017 --quiet --eval "db.adminCommand('ping').ok" >/dev/null 2>&1; then
    break
  fi
  [ "$i" -eq 60 ] && { echo "mongos 타임아웃"; exit 1; }
  sleep 2
done

echo ">> 샤드 등록"
mongosh --host mongo-mongos --port 27017 --quiet --eval "
  const existing = db.adminCommand({ listShards: 1 }).shards.map(s => s._id);
  for (const s of ['shard1', 'shard2', 'shard3']) {
    if (existing.includes(s)) { print(s + ': already added'); continue; }
    const r = sh.addShard(s + '/mongo-' + s + ':27018');
    print(s + ': added (ok=' + r.ok + ')');
  }
  print('--- shards ---');
  db.adminCommand({ listShards: 1 }).shards.forEach(s => print('  ' + s._id + '  ' + s.host));
"
echo ">> sharded cluster ready (mongodb://localhost:27030)"
