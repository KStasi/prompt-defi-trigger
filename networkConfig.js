const hre = require("hardhat");
module.exports = {
  goerli: [
    {
      tokens: [
        {
          token: "0x45AC379F019E48ca5dAC02E54F406F99F5088099",
          priceFeed: "0xA39434A63A52E749F02807ae27335515BA4b07F7", // BTC Price Feed
          poolFee: 3000,
        },
      ],
      stopLoss: hre.ethers.parseEther("100"),
      takeProfit: hre.ethers.parseEther("200"),
      uniswapRouter: "0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45",
      usdc: "0x65aFADD39029741B3b8f0756952C74678c9cEC93",
    },
    {
      tokens: [
        {
          token: "0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6",
          priceFeed: "0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e", // ETH price feed
          poolFee: 3000,
        },
      ],
      stopLoss: hre.ethers.parseEther("50"),
      takeProfit: hre.ethers.parseEther("150"),
      uniswapRouter: "0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45",
      usdc: "0x65aFADD39029741B3b8f0756952C74678c9cEC93",
    },
  ],
};
