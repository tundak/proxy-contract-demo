const { ethers, upgrades } = require('hardhat');

async function main() {
  // We get the contract to deploy
  const TestV2 = await ethers.getContractFactory('TestV2');
  const ref =   await upgrades.upgradeProxy('0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0', TestV2);

  console.log("TestV2 deployed to:", ref.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });