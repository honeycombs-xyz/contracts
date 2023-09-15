import { task } from 'hardhat/config';
import { deploy } from '../helpers/deploy';

task('deploy', 'Deploys all contracts for testing', async (_, hre) => {
  const [deployer] = await hre.ethers.getSigners();
  console.log('\nDeploying with the account:', await deployer.getAddress());

  const { name: network } = hre.network;
  console.log(`\nRunning on network [${network}]`);

  const { honeycombs } = await deploy(hre.ethers);

  console.log(`Successfully deployed Honeycombs at ${honeycombs.address}`);
});
