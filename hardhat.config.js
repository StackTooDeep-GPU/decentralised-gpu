require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.20",
  networks: {
    goerli: {
      url : "https://rpc.ankr.com/eth_goerli",
      chainId: 1337
    }
  },
};
