import { parseEther } from 'ethers/lib/utils';
import {
  USER_1,
  USER_2,
  WHALE,
  RESERVE_ADDRESS_1,
  RESERVE_ADDRESS_2,
  VAULT,
} from '../../helpers/constants';
import { impersonate } from '../../helpers/impersonate';
const hre = require('hardhat');

export async function impersonateAccounts() {
  const user1 = await impersonate(USER_1, hre);
  const user2 = await impersonate(USER_2, hre);
  const vault = await impersonate(VAULT, hre);
  const reserve1 = await impersonate(RESERVE_ADDRESS_1, hre);
  const reserve2 = await impersonate(RESERVE_ADDRESS_2, hre);
  const whale = await impersonate(WHALE, hre);

  await user2.sendTransaction({ to: USER_1, value: parseEther('1') });

  return {
    user1,
    user2,
    whale,
    vault,
    reserve1,
    reserve2,
  };
}
