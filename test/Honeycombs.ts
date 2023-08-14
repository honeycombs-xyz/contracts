import fs from 'fs'
import { loadFixture, mine, time } from '@nomicfoundation/hardhat-network-helpers'
import { deployHoneycombs } from './fixtures/deploy'
import { impersonateAccounts } from './fixtures/impersonate'
import { mintedFixture } from './fixtures/mint'
import { USER_1, USER_2, VAULT } from '../helpers/constants'
import { fetchAndRender } from '../helpers/render'
import { decodeBase64URI } from '../helpers/decode-uri'
const { expect } = require('chai')
const hre = require('hardhat')
const ethers = hre.ethers

describe.only('Honeycombs', () => {
  it('Should deploy honeycombs', async () => {
    const { honeycombs } = await loadFixture(deployHoneycombs)

    expect(await honeycombs.name()).to.equal('Honeycombs')
    expect(await honeycombs.symbol()).to.equal('HONEYCOMBS')
  })

  describe('Mint', () => {
    // it('Should allow to mint originals', async () => {
    //   const { honeycombs } = await loadFixture(deployHoneycombs)
    //   const { user1 } = await loadFixture(impersonateAccounts)

    //   expect(await honeycombs.totalSupply()).to.equal(0)

    //   await expect(honeycombs.connect(user1).mint([1001], VAULT))
    //     .to.emit(honeycombs, 'Transfer')
    //     .withArgs(ethers.constants.AddressZero, USER_1, 1001)
    //     .to.emit(honeycombs, 'Transfer')
    //     .withArgs(USER_1, VAULT, 1001)

    //   expect(await honeycombs.totalSupply()).to.equal(1)
    //   await mine(50)

    //   const tx = await honeycombs.connect(user1).mint([808], USER_1)
    //   await expect(tx)
    //     .to.emit(honeycombs, 'Transfer')
    //     .withArgs(ethers.constants.AddressZero, USER_1, 808)
    //   const receipt = await tx.wait()
    //   expect(receipt.events.length).to.equal(4) // Reset approval + burn transfer + new mint + new epoch

    //   // Or multiple
    //   await expect(honeycombs.connect(user1).mint([44, 222], VAULT))
    //     .to.emit(honeycombs, 'Transfer')
    //     .withArgs(ethers.constants.AddressZero, USER_1, 44)
    //     .to.emit(honeycombs, 'Transfer')
    //     .withArgs(USER_1, VAULT, 44)
    //     .to.emit(honeycombs, 'Transfer')
    //     .withArgs(ethers.constants.AddressZero, USER_1, 222)
    //     .to.emit(honeycombs, 'Transfer')
    //     .withArgs(USER_1, VAULT, 222)

    //   expect(await honeycombs.totalSupply()).to.equal(4)
    // })

    // it('Should set the token birth date correctly at mint', async () => {
    //   const { checksEditions, checks } = await loadFixture(deployHoneycombs)
    //   const { user1 } = await loadFixture(impersonateAccounts)

    //   // First we need to approve the Originals contract on the Editions contract
    //   await checksEditions.connect(user1).setApprovalForAll(checks.address, true)

    //   // Then we can mint one
    //   await expect(checks.connect(user1).mint([1001], USER_1))
    //     .to.emit(checks, 'Transfer')
    //     .withArgs(ethers.constants.AddressZero, USER_1, 1001)
    //   expect((await checks.getCheck(1001)).stored.day).to.equal(1)

    //   await time.increase(3600 * 24)

    //   await expect(checks.connect(user1).mint([808], USER_1))
    //     .to.emit(checks, 'Transfer')
    //     .withArgs(ethers.constants.AddressZero, USER_1, 808)
    //   expect((await checks.getCheck(808)).stored.day).to.equal(2)
    // })

    // it('Should allow to mint many originals at once', async () => {
    //   const { checksEditions, checks } = await loadFixture(deployHoneycombs)
    //   const { user2 } = await loadFixture(impersonateAccounts)

    //   await checksEditions.connect(user2).setApprovalForAll(checks.address, true)

    //   await expect(checks.connect(user2).mint(USER_2_TOKENS, VAULT))
    //     .to.emit(checks, 'Transfer')
    //     .withArgs(ethers.constants.AddressZero, USER_2, 9696)
    //     .to.emit(checks, 'Transfer')
    //     .withArgs(USER_2, VAULT, 9696)
    // })
  })

  // describe('Burning', () => {
  //   it('Should not allow non approved operators to burn tokens', async () => {
  //     const { checks } = await loadFixture(mintedFixture)

  //     await expect(checks.burn(USER_2_TOKENS[0]))
  //       .to.be.revertedWithCustomError(checks, 'NotAllowed')
  //   })

  //   it('Should allow holders to burn their tokens', async () => {
  //     const { checks, user2 } = await loadFixture(mintedFixture)

  //     const id = USER_2_TOKENS[0]

  //     await expect(checks.connect(user2).burn(id))
  //       .to.emit(checks, 'Transfer')
  //       .withArgs(user2.address, ethers.constants.AddressZero, id)
  //   })

  //   it('Should properly track total supply when users burn burn their tokens', async () => {
  //     const { checks, user2 } = await loadFixture(mintedFixture)

  //     expect(await checks.totalSupply()).to.equal(134)
  //     await checks.connect(user2).burn(USER_2_TOKENS[0])
  //     expect(await checks.totalSupply()).to.equal(133)
  //   })
  // })

  // describe('Swapping', () => {
  //   it('Should not allow people to swap tokens of other users', async () => {
  //     const { checks } = await loadFixture(mintedFixture)

  //     const [toKeep, toBurn] = USER_2_TOKENS.slice(0, 2)
  //     await expect(checks.inItForTheArt(toKeep, toBurn))
  //       .to.be.revertedWithCustomError(checks, 'NotAllowed')
  //   })

  //   it('Should allow people to swap their own tokens', async () => {
  //     const { checks, user2 } = await loadFixture(mintedFixture)

  //     const [toKeep, toBurn] = USER_2_TOKENS.slice(0, 2)

  //     const toBurnSVG = await checks.svg(toBurn)
  //     const toKeepSVG = await checks.svg(toKeep)
  //     fs.writeFileSync('test/dist/sacrifice-burn-before.svg', toBurnSVG)
  //     fs.writeFileSync('test/dist/sacrifice-keep-before.svg', toKeepSVG)

  //     await expect(checks.connect(user2).inItForTheArt(toKeep, toBurn))
  //       .to.emit(checks, 'Sacrifice')
  //       .withArgs(toBurn, toKeep)

  //     const toKeepSVGAfter = await checks.svg(toKeep)
  //     fs.writeFileSync('test/dist/sacrifice-keep-after.svg', toKeepSVGAfter)

  //     expect(toBurnSVG).to.equal(toKeepSVGAfter)
  //     expect(toKeepSVG).not.to.equal(toKeepSVGAfter)
  //   })

  //   it('Should allow people to swap approved tokens', async () => {
  //     const { checks, user2, user1 } = await loadFixture(mintedFixture)
  //     const [toKeep, toBurn] = USER_2_TOKENS.slice(0, 2)

  //     await expect(checks.connect(user1).inItForTheArt(toKeep, toBurn))
  //       .to.be.reverted

  //     await checks.connect(user2).setApprovalForAll(user1.address, true)

  //     await expect(checks.connect(user1).inItForTheArt(toKeep, toBurn))
  //       .to.emit(checks, 'Sacrifice')
  //       .withArgs(toBurn, toKeep)
  //   })

  //   it('Should allow people to swap multiple tokens at once', async () => {
  //     const { checks, user2 } = await loadFixture(mintedFixture)

  //     const toKeep = USER_2_TOKENS.slice(0, 3)
  //     const toBurn = USER_2_TOKENS.slice(3, 6)
  //     await expect(checks.connect(user2).inItForTheArts(toKeep, toBurn))
  //       .to.emit(checks, 'Sacrifice')
  //       .withArgs(toBurn[0], toKeep[0])
  //       .to.emit(checks, 'Sacrifice')
  //       .withArgs(toBurn[1], toKeep[1])
  //       .to.emit(checks, 'Sacrifice')
  //       .withArgs(toBurn[2], toKeep[2])
  //   })

  //   it('Should update the token birth date when swapping tokens', async () => {
  //     const { checks, user2 } = await loadFixture(mintedFixture)
  //     const [toKeep, toBurn] = USER_2_TOKENS.slice(0, 2)

  //     await time.increase(3600 * 24 * 3)

  //     await expect(checks.connect(user2).inItForTheArt(toKeep, toBurn))
  //       .to.emit(checks, 'Sacrifice')
  //       .withArgs(toBurn, toKeep)

  //     expect((await checks.getCheck(toKeep)).stored.day).to.equal(4)
  //   })
  // })

  // describe('Metadata', () => {
  //   it('Should show correct metadata', async () => {
  //     const { checks, user2 } = await loadFixture(mintedFixture)

  //     const uri = await checks.tokenURI(USER_2_TOKENS[0])
  //     fs.writeFileSync(`test/dist/tokenuri-${USER_2_TOKENS[0]}`, uri)

  //     const uri2 = await checks.tokenURI(USER_2_TOKENS[1])
  //     fs.writeFileSync(`test/dist/tokenuri-${USER_2_TOKENS[1]}`, uri2)

  //   })

  //   it('Should render unrevealed tokens', async () => {
  //     const { checksEditions, checks } = await loadFixture(deployHoneycombs)
  //     const { user1 } = await loadFixture(impersonateAccounts)
  //     await checksEditions.connect(user1).setApprovalForAll(checks.address, true)

  //     await checks.connect(user1).mint([1001], VAULT)
  //     await fetchAndRender(1001, checks, 'pre_reveal_')
  //   })

  //   it('Should render metadata for unrevealed tokens', async () => {
  //     const { checksEditions, checks } = await loadFixture(deployHoneycombs)
  //     const { user1 } = await loadFixture(impersonateAccounts)
  //     await checksEditions.connect(user1).setApprovalForAll(checks.address, true)

  //     await checks.connect(user1).mint([1001], VAULT)

  //     const metadataURI = await checks.tokenURI(1001)
  //     expect(decodeBase64URI(metadataURI).attributes).to.deep.equal([
  //       { trait_type: 'Revealed', value: 'No' },
  //       { trait_type: 'Checks', value: '80' },
  //       { trait_type: 'Day', value: '1' }
  //     ])
  //   })

  //   it('Should render metadata for revealed tokens', async () => {
  //     const { checksEditions, checks } = await loadFixture(deployHoneycombs)
  //     const { user1 } = await loadFixture(impersonateAccounts)
  //     await checksEditions.connect(user1).setApprovalForAll(checks.address, true)

  //     await checks.connect(user1).mint([1001], VAULT)
  //     await mine(50)
  //     await checks.resolveEpochIfNecessary()

  //     const afterReveal = decodeBase64URI(await checks.tokenURI(1001))
  //     expect(afterReveal.attributes)
  //       .to.not.have.deep.members([{ trait_type: 'Revealed', value: 'No' }])

  //     expect(afterReveal.attributes.map(a => a.trait_type))
  //       .to.have.members([ 'Color Band', 'Gradient', 'Speed', 'Shift', 'Checks', 'Day' ])
  //       .but.not.include('Revealed')
  //   })
  // })
})
