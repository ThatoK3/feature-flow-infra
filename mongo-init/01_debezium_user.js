// Runs on the primary after rs0 is initialised
db = db.getSiblingDB("admin");
db.createUser({
  user: "debezium",
  pwd: "debezium_pass_change_me",
  roles: [
    { role: "read", db: "admin" },
    { role: "readAnyDatabase", db: "admin" },
    { role: "clusterMonitor", db: "admin" }
  ]
});
