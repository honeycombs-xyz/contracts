import { task } from 'hardhat/config'
import { deploy } from '../helpers/deploy'

task('deploy', 'Deploys all contracts for testing', async (_, hre) => {
  const { honeycombs } = await deploy(hre.ethers)

  console.log(`Successfully deployed Honeycombs at ${honeycombs.address}`)
})
