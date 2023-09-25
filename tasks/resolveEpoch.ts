import { task } from 'hardhat/config';
import { USER_1 } from '../helpers/constants';
import { impersonate } from '../helpers/impersonate';

task('resolve-epoch', 'Resolves the epoch to allow for rendering')
  .addParam('contract', 'The address of the contract')
  .setAction(async ({ contract }, hre) => {
    const honeycombs = await hre.ethers.getContractAt('Honeycombs', contract);
    console.log(`Honeycombs are at ${honeycombs.address}`);

    // Resolve the epoch
    const tx = await honeycombs.resolveEpochIfNecessary();
    console.log(`Resolved the epoch for network ${hre.network.name}`);
  });