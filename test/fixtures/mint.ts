import { loadFixture, mine } from '@nomicfoundation/hardhat-network-helpers'
import { USER_1, USER_2 } from '../../helpers/constants'
import { deployHoneycombs } from './deploy'
import { impersonateAccounts } from './impersonate'
import hre from 'hardhat'

export async function mintedFixture() {
  const { honeycombs } = await loadFixture(deployHoneycombs)
  const { user1, user2 } = await loadFixture(impersonateAccounts)

  await honeycombs.connect(user1).mint(0, USER_1)
  await honeycombs.connect(user2).mint(1, USER_2)

  await mine(50)
  await (await honeycombs.resolveEpochIfNecessary()).wait()

  return {
    honeycombs,
    user1,
    user2
  }
}