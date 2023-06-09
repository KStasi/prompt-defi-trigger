const hre = require("hardhat");
const networkConfig = require("../networkConfig.js");

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}
const delay = 1000 * 20; //5s

async function main() {
  const [deployer] = await hre.ethers.getSigners();

  // Contract deployments
  const SimpleTriggerFactory = await hre.ethers.getContractFactory(
    "SimpleTriggerFactory"
  );
  const simpleTriggerFactory = await SimpleTriggerFactory.deploy();
  await simpleTriggerFactory.waitForDeployment();

  console.log("SimpleTriggerFactory deployed to:", simpleTriggerFactory.target);

  let triggerConfigs = networkConfig[hre.network.name];
  if (!triggerConfigs) {
    const TestToken = await hre.ethers.getContractFactory("TestToken");

    const tokenConfigs = [
      {
        initialSupply: hre.ethers.parseEther("1000"),
      },
      {
        initialSupply: hre.ethers.parseEther("500"),
      },
      {
        initialSupply: hre.ethers.parseEther("500"),
      },
    ];

    const tokens = [];
    for (const config of tokenConfigs) {
      const token = await TestToken.deploy(config.initialSupply);
      await token.waitForDeployment();

      console.log(`TestToken deployed to:`, token.target);
      tokens.push(token.target);
    }

    triggerConfigs = [
      {
        tokens: [
          {
            token: tokens[0],
            priceFeed: tokens[0],
            poolFee: 3000,
          },
          {
            token: tokens[1],
            priceFeed: tokens[1],
            poolFee: 3000,
          },
          // add more tokens if needed
        ],
        stopLoss: hre.ethers.parseEther("100"),
        takeProfit: hre.ethers.parseEther("200"),
        uniswapRouter: tokens[2],
        usdc: tokens[2],
      },
      {
        tokens: [
          {
            token: tokens[1],
            priceFeed: tokens[1],
            poolFee: 5000,
          },
        ],
        stopLoss: hre.ethers.parseEther("50"),
        takeProfit: hre.ethers.parseEther("150"),
        uniswapRouter: tokens[2],
        usdc: tokens[2],
      },
    ];
  }

  for (const config of triggerConfigs) {
    const op = await simpleTriggerFactory.createSimpleTrigger(
      config.tokens,
      config.stopLoss,
      config.takeProfit,
      config.uniswapRouter,
      config.usdc
    );
    console.log(op);
    await sleep(delay);
    const triggerCount = await simpleTriggerFactory.triggerCount();
    const triggerAddress = await simpleTriggerFactory.triggers(
      triggerCount - 1n
    );
    console.log(`Trigger deployed to:`, triggerAddress);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
