// rs0 초기화 (여러 번 실행해도 안전)
const config = {
  _id: "rs0",
  members: [
    { _id: 0, host: "mongo-rs1:27021", priority: 2 },
    { _id: 1, host: "mongo-rs2:27022", priority: 1 },
    { _id: 2, host: "mongo-rs3:27023", priority: 1 },
  ],
};

try {
  rs.status();
  print("rs0: already initialized");
} catch (e) {
  if (e.codeName !== "NotYetInitialized") throw e;
  printjson(rs.initiate(config));
}

let tries = 0;
while (!db.hello().isWritablePrimary) {
  if (++tries > 60) throw new Error("rs0: PRIMARY 선출 타임아웃");
  sleep(1000);
}

print("rs0: ready");
rs.status().members.forEach((m) => print(`  ${m.name}  ${m.stateStr}`));
