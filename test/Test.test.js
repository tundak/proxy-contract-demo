const { ethers, upgrades } = require('hardhat');

describe('Test', function () {
  it('deploys', async function () {
    const Test = await ethers.getContractFactory('Test');
    await upgrades.deployProxy(Test);
  });
});