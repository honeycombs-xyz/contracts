import { task } from 'hardhat/config';
import { deploy } from '../helpers/deploy';

task('deploy', 'Deploys all contracts for testing', async (_, hre) => {
  const accounts = await hre.ethers.getSigners();
  const deployer = accounts[0];
  console.log('\nDeploying with the account:', await deployer.getAddress());

  const { name: network } = hre.network;
  console.log(`\nRunning on network [${network}]`);

  const { honeycombs } = await deploy(hre.ethers, deployer);

  console.log(`Successfully deployed Honeycombs at ${honeycombs.address}`);
});
