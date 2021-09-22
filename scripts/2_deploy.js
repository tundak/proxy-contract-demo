const { ethers, upgrades } = require('hardhat');

async function main() {
  // We get the contract to deploy
  const ReferralV2 = await ethers.getContractFactory('ReferralV2');
  const ref =   await upgrades.upgradeProxy('0xB7bb8f008f304d4CfC9ED7425B4C518BD892B91a', ReferralV2);

  console.log("ReferralV2 deployed to:", ref.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });