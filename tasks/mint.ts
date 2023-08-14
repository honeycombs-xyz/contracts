import { mine } from '@nomicfoundation/hardhat-network-helpers'
import { Wallet } from 'ethers'
import { task } from 'hardhat/config'
import { USER_1 } from '../helpers/constants'
import { impersonate } from '../helpers/impersonate'

task('mint-testing', 'Mint single token for testing')
  .addParam('contract', 'The Honeycombs Contract address')
  .setAction(async ({ contract }, hre) => {
    const honeycombs = await hre.ethers.getContractAt('Honeycombs', contract)
    console.log(`Honeycombs are at ${honeycombs.address}`)
    const user1 = await impersonate(USER_1, hre)

    // Mint token 0
    await honeycombs.connect(user1).mint(0, USER_1)

    await mine(50)
    await (await honeycombs.resolveEpochIfNecessary()).wait()

    console.log(`Minted Honeycomb token #0`)
  })

task('mint-live', 'Mint multiple honeycombs tokens')
  .addParam('contract', 'The Honeycombs Contract address')
  .addParam('from', 'The min token ID (inclusive)')
  .addParam('to', 'The max token ID (inclusive)')
  .setAction(async ({ contract, from, to }, hre) => {
    const signer = new Wallet(process.env.SIGNER_PK || '', hre.ethers.provider)
    const honeycombs = await hre.ethers.getContractAt('Honeycombs', contract)

    const tokens = [...Array(parseInt(to) - parseInt(from) + 1).keys()].map(t => t + parseInt(from))

    for (let i = 0; i < tokens.length; i+=100) {
      const ids = tokens.slice(i, i + 100)
      const tx = await honeycombs.connect(signer).mint(ids, signer.address, {
        gasLimit: 20_000_000,
      })
      console.log(`Minted honeycomb ${tokens[i]} - ${tokens[i + 100 - 1]}`)

      if (i > 0 && i % 500 === 0) {
        console.log(`Waiting for tx batch`)
        await tx.wait()
      }
    }
  })

task('reveal', 'Reveal tokens')
  .addParam('contract', 'Honeycombs contract address')
  .setAction(async ({ contract }, hre) => {
    const honeycombs = await hre.ethers.getContractAt('Honeycombs', contract)
    const user1 = await impersonate(USER_1, hre)
    await honeycombs.connect(user1).resolveEpochIfNecessary()
  })
