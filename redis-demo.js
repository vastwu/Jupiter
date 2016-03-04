var redis = require('redis')

var client = redis.createClient (6379,'127.0.0.1', {})

client.set("string key", "string val", redis.print);
client.get("string key", redis.print);

client.quit();
