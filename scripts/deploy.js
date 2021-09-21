const { ethers, upgrades } = require('hardhat');

async function main() {
  // We get the contract to deploy
  const Test = await ethers.getContractFactory('Test');
  const ref =   await upgrades.deployProxy(Test);

  console.log("Test deployed to:", ref.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });