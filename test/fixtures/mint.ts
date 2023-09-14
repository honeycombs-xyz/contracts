import { loadFixture, mine } from '@nomicfoundation/hardhat-network-helpers';
import { USER_1, USER_2 } from '../../helpers/constants';
import { deployHoneycombs } from './deploy';
import { impersonateAccounts } from './impersonate';
import { ethers } from 'hardhat';

export async function mintedFixture() {
  const { honeycombs } = await loadFixture(deployHoneycombs);
  const { user1, user2 } = await loadFixture(impersonateAccounts);

  // mint all of user 1's tokens
  await honeycombs
    .connect(user1)
    .mint(5, USER_1, { value: ethers.utils.parseEther('0.5') });

  // mint all of user 2's tokens
  await honeycombs
    .connect(user2)
    .mint(5, USER_2, { value: ethers.utils.parseEther('0.5') });

  await mine(50);
  await (await honeycombs.resolveEpochIfNecessary()).wait();

  return {
    honeycombs,
    user1,
    user2,
  };
}
