import { task } from 'hardhat/config'
import { VV_TOKENS } from '../helpers/constants'
import { fetchAndRender } from '../helpers/render'

task('render', 'Mint tokens')
  .addParam('contract', 'The Honeycombs Contract address')
  .addOptionalParam('id', 'Which token ID to render')
  .setAction(async ({ contract, id }, hre) => {
    const honeycombs = await hre.ethers.getContractAt('Honeycombs', contract)

    console.log(await honeycombs.getEpochData(1))

    if (id) {
      await fetchAndRender(id, honeycombs)
    } else {
      for (const id of VV_TOKENS) {
        await fetchAndRender(id, honeycombs)
      }
    }
  })
