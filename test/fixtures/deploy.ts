import { deploy } from '../../helpers/deploy';
import { ethers } from 'hardhat';

export async function deployHoneycombs() {
  const { honeycombArt, honeycombsMetadata, honeycombs } = await deploy(ethers);

  return {
    honeycombArt,
    honeycombsMetadata,
    honeycombs,
  };
}
