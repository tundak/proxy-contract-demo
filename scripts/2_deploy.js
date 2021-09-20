const { ethers, upgrades } = require('hardhat');

async function main() {
  // We get the contract to deploy
  const ReferralV2 = await ethers.getContractFactory('ReferralV2');
  const ref =   await upgrades.upgradeProxy('0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0', ReferralV2);

  console.log("ReferralV2 deployed to:", ref.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });