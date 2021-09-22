require('@nomiclabs/hardhat-ethers');
require('@openzeppelin/hardhat-upgrades');
require("@nomiclabs/hardhat-waffle");

// Go to https://www.alchemyapi.io, sign up, create
// a new App in its dashboard, and replace "KEY" with its key
const ALCHEMY_API_KEY = "rVOVNhQIVi9jSsItwblvgvieCIIbzrlT";

// Replace this private key with your Kovan account private key
// To export your private key from Metamask, open Metamask and
// go to Account Details > Export Private Key
// Be aware of NEVER putting real Ether into testing accounts
const KOVAN_PRIVATE_KEY = "ad0bca56a437c4961f56499f54f48a8d7cf1128e0201abcc7115994042cb6713";


/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.0",
  networks: {
    kovan: {
      url: `https://eth-kovan.alchemyapi.io/v2/${ALCHEMY_API_KEY}`,
      accounts: [`0x${KOVAN_PRIVATE_KEY}`],
    },
  },
};