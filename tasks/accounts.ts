import { parseEther } from 'ethers/lib/utils';
import { task } from 'hardhat/config';
import { USER_1, USER_2, WHALE, VAULT } from '../helpers/constants';
import { impersonate } from '../helpers/impersonate';

task('accounts', 'Prints the list of accounts', async (_, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

task('fund-users', 'Funds users for testing', async (_, hre) => {
  const user2 = await impersonate(USER_2, hre);
  await user2.sendTransaction({ to: USER_1, value: parseEther('1') });
  await user2.sendTransaction({ to: WHALE, value: parseEther('1') });
  await user2.sendTransaction({ to: VAULT, value: parseEther('1') });
});
