
const EthPriceOracle = require("./EthPriceOracle.js");
const PRIVATE_KEY_FILE_NAME = process.env.PRIVATE_KEY_FILE || "./oracle/oracle_private_key";
const SLEEP_INTERVAL = process.env.SLEEP_INTERVAL || 2000;

(async () => {
  const { oracleContract, ownerAddress, client } = await EthPriceOracle.init(PRIVATE_KEY_FILE_NAME);
  process.on("SIGINT", () => {
    console.log("Calling client.disconnect()");
    client.disconnect();
    process.exit();
  });
  console.log("Oracle1 started...");
  setInterval(async () => {
    await EthPriceOracle.processQueue(oracleContract, ownerAddress);
  }, SLEEP_INTERVAL);
})();
