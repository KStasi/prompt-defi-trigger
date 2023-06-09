require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

const INFURA_API_KEY = "KEY";
const GOERLI_PRIVATE_KEY = "KEY";

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.18",
  networks: {
    hardhat: {
      allowUnlimitedContractSize: true,
    },
    // goerli: {
    //   url: `https://goerli.infura.io/v3/${INFURA_API_KEY}`,
    //   accounts: [GOERLI_PRIVATE_KEY],
    // },
  },
};
