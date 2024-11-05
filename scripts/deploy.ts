import { ethers } from 'hardhat';

async function main() {
  const tokenName = "CheddarToken";
  const minterAddress = "0x2Ba014E86c5c7878e8B2B44B97A5b6d3549d33bd";
  const cheddarToken = await ethers.deployContract('CheddarToken', [tokenName, minterAddress]);

  await cheddarToken.waitForDeployment();

  console.log('Token Contract Deployed at ' + cheddarToken.target);

  const cheddarMazeMinter = await ethers.deployContract('CheddarMazeMinter', [cheddarToken.target, minterAddress]);

  await cheddarMazeMinter.waitForDeployment();

  console.log('Maze minter Contract Deployed at ' + cheddarMazeMinter.target);

  await cheddarToken.addMinter(cheddarMazeMinter.target);

}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});