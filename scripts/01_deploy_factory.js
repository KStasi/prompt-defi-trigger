const hre = require("hardhat");
const networkConfig = require("../configNetwork.js");

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}
const delay = 1000 * 20; //5s

async function main() {
  const [deployer] = await hre.ethers.getSigners();

  let factoryConfigs = networkConfig[hre.network.name];
  const SimpleTriggerFactory = await hre.ethers.getContractFactory(
    "SimpleTriggerFactory"
  );
  const simpleTriggerFactory = await SimpleTriggerFactory.deploy(factoryConfigs.link, factoryConfigs.registrar, factoryConfigs.uniswapRouter);
  await simpleTriggerFactory.waitForDeployment();

  console.log("SimpleTriggerFactory deployed to:", simpleTriggerFactory.target);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
