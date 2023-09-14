import { mine } from '@nomicfoundation/hardhat-network-helpers';
import { task } from 'hardhat/config';
import { USER_1 } from '../helpers/constants';
import { impersonate } from '../helpers/impersonate';

task('mint-testing', 'Mint single token for testing')
  .addParam('contract', 'The Honeycombs Contract address')
  .addParam('numberOfTokens', 'The number of tokens to mint')
  .setAction(async ({ contract, numberOfTokens }, hre) => {
    const honeycombs = await hre.ethers.getContractAt('Honeycombs', contract);
    console.log(`Honeycombs are at ${honeycombs.address}`);
    const user1 = await impersonate(USER_1, hre);

    // Mint tokens
    await honeycombs.connect(user1).mint(numberOfTokens, USER_1);

    await mine(50);
    await (await honeycombs.resolveEpochIfNecessary()).wait();

    console.log(`Minted Honeycombs for ${USER_1}: ${numberOfTokens}`);
  });

task('reveal', 'Reveal tokens')
  .addParam('contract', 'Honeycombs contract address')
  .setAction(async ({ contract }, hre) => {
    const honeycombs = await hre.ethers.getContractAt('Honeycombs', contract);
    const user1 = await impersonate(USER_1, hre);
    await honeycombs.connect(user1).resolveEpochIfNecessary();
  });
