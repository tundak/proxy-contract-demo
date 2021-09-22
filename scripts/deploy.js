const { ethers, upgrades } = require('hardhat');

async function main() {
  // We get the contract to deploy
  const Referral = await ethers.getContractFactory('Referral');
  const ref =   await upgrades.deployProxy(Referral);

  console.log("Referral deployed to:", ref.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });