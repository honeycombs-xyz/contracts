import { task } from 'hardhat/config';
import { USER_1 } from '../helpers/constants';
import { impersonate } from '../helpers/impersonate';

task('withdraw', 'Withdraw the mint proceeds from the contract')
  .addParam('contract', 'The address of the contract')
  .addParam('amount', 'The amount to withdraw')
  .addOptionalParam('deployer', 'The address of the deployer')
  .setAction(async ({ contract, amount, deployer }, hre) => {
    const honeycombs = await hre.ethers.getContractAt('Honeycombs', contract);
    console.log(`Honeycombs are at ${honeycombs.address}`);
    const deployerAddress = (deployer) ? deployer : USER_1;
    const deployerAccount = await impersonate(deployerAddress, hre);

    // Get the balance of the contract
    const balance = await hre.ethers.provider.getBalance(honeycombs.address);
    console.log(`Balance of ${honeycombs.address} is ${hre.ethers.utils.formatEther(balance)}`);

    // Withdraw mint funds
    const amountWei = hre.ethers.utils.parseEther(amount);
    const tx = await honeycombs.connect(deployerAccount).withdraw(amountWei)
    console.log(`Withdrew ${amount} ETH from ${honeycombs.address} to ${deployerAddress} for network ${hre.network.name}`);
  });