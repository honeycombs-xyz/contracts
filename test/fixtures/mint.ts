import { loadFixture, mine } from '@nomicfoundation/hardhat-network-helpers';
import {
  USER_1,
  USER_2,
  USER_1_TOKENS,
  USER_2_TOKENS,
} from '../../helpers/constants';
import { deployHoneycombs } from './deploy';
import { impersonateAccounts } from './impersonate';

export async function mintedFixture() {
  const { honeycombs } = await loadFixture(deployHoneycombs);
  const { user1, user2 } = await loadFixture(impersonateAccounts);

  // mint all of user 1's tokens
  for (let i = 0; i < USER_1_TOKENS.length; i++) {
    await honeycombs.connect(user1).mint(USER_1_TOKENS[i], USER_1);
  }

  // mint all of user 2's tokens
  for (let i = 0; i < USER_2_TOKENS.length; i++) {
    await honeycombs.connect(user2).mint(USER_2_TOKENS[i], USER_2);
  }

  await mine(50);
  await (await honeycombs.resolveEpochIfNecessary()).wait();

  return {
    honeycombs,
    user1,
    user2,
  };
}
