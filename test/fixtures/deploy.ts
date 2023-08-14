import { deploy } from '../../helpers/deploy'
import { ethers } from 'hardhat';

export async function deployHoneycombs() {
  const { honeycombs } = await deploy(ethers)

  return {
    honeycombs
  }
}
