import { task } from 'hardhat/config';
import { fetchAndRender } from '../helpers/render';

task('render', 'Mint tokens')
  .addParam('contract', 'The Honeycombs Contract address')
  .addParam('id', 'Which token ID to render')
  .setAction(async ({ contract, id }, hre) => {
    const honeycombs = await hre.ethers.getContractAt('Honeycombs', contract);

    if (id) {
      await fetchAndRender(honeycombs, id);
    }
  });
