const common = require("../utils/common.js");
const PRIVATE_KEY_FILE_NAME = process.env.PRIVATE_KEY_FILE || "./oracle/oracle_private_key";
const PRIVATE_KEY_FILE_NAME_1 = process.env.PRIVATE_KEY_FILE_1 || "./oracle/oracle_private_key_1";
const PRIVATE_KEY_FILE_NAME_2 = process.env.PRIVATE_KEY_FILE_2 || "./oracle/oracle_private_key_2";
const OracleJSON = require("../oracle/build/contracts/EthPriceOracle.json");

const oracleAddress1 = common.getAddress(PRIVATE_KEY_FILE_NAME_1);
const oracleAddress2 = common.getAddress(PRIVATE_KEY_FILE_NAME_2);

async function getOracleContract(web3js) {
  const networkId = await web3js.eth.net.getId();
  return new web3js.eth.Contract(
    OracleJSON.abi,
    OracleJSON.networks[networkId].address
  );
}


async function init() {
  const { ownerAddress, web3js, client } = common.loadAccount(
    PRIVATE_KEY_FILE_NAME
  );
  const oracleContract = await getOracleContract(web3js);
  return { oracleContract, ownerAddress, client };
}

async function addOracle(oracleContract, ownerAddress, oracleAddress) {
  try {
    const tx = await oracleContract.methods.addOracle(oracleAddress).send({
      from: ownerAddress
    });
    console.log(tx);
  } catch (e) {
    console.log(e);
  }

}

(async () => {
  const { oracleContract, ownerAddress, client } = await init();
  process.on("SIGINT", () => {
    console.log("Calling client.disconnect()");
    client.disconnect();
    process.exit();
  });
  console.log("Updating oracle threshold...");
  await oracleContract.methods.setThreshold(2).send({
    from: ownerAddress
  });
  console.log("Setting oracles...");
  await addOracle(oracleContract, ownerAddress, ownerAddress);
  await addOracle(oracleContract, ownerAddress, oracleAddress1);
  await addOracle(oracleContract, ownerAddress, oracleAddress2);
  console.log("Oracle Updated...");
  client.disconnect();
  process.exit();
})();
