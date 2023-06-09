const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("SimpleTriggerFactory", function () {

  async function deploySimpleTriggerFactoryFixture() {
    const [owner, otherAccount] = await ethers.getSigners();

    const SimpleTriggerFactory = await ethers.getContractFactory("SimpleTriggerFactory");
    const simpleTriggerFactory = await SimpleTriggerFactory.deploy();

    return { simpleTriggerFactory, owner, otherAccount };
  }

  describe("Create SimpleTrigger", function () {
    it("Should create a new SimpleTrigger contract", async function () {
      const { simpleTriggerFactory, owner } = await deploySimpleTriggerFactoryFixture();

      const tokens = [
        {
          token: ethers.ZeroAddress,
          priceFeed: ethers.ZeroAddress,
          poolFee: 3000
        }
      ];

      const stopLoss = ethers.parseEther("10");
      const takeProfit = ethers.parseEther("20");

      const uniswapRouter = ethers.ZeroAddress;
      const usdc = ethers.ZeroAddress;  

       await simpleTriggerFactory.createSimpleTrigger(
        tokens,
        stopLoss, 
        takeProfit,
        uniswapRouter,
        usdc
      );

      expect(await simpleTriggerFactory.triggers(0)).to.not.equal(ethers.ZeroAddress);
    });
  });

});
