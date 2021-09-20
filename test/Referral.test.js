const { ethers, upgrades } = require('hardhat');

describe('Referral', function () {
  it('deploys', async function () {
    const Referral = await ethers.getContractFactory('Referral');
    await upgrades.deployProxy(Referral);
  });
});