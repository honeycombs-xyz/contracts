import { loadFixture, mine } from '@nomicfoundation/hardhat-network-helpers'
import { deployHoneycombs } from './fixtures/deploy'
import { impersonateAccounts } from './fixtures/impersonate'
const { expect } = require('chai')
const hre = require('hardhat')

describe('WithReveal', () => {
  it('Should mint unrevealed tokens', async () => {
    const { honeycombs } = await loadFixture(deployHoneycombs)
    const { jalil } = await loadFixture(impersonateAccounts)

    await expect(honeycombs.connect(jalil).mint([808], jalil.address))
      .not.to.emit(honeycombs, 'NewEpoch')

    const beforeReveal = await honeycombs.getHoneycomb(808)
    expect(beforeReveal.isRevealed).to.equal(false)

    await mine(50)
    expect((await honeycombs.getHoneycomb(808)).isRevealed).to.equal(false)

    const firstEpoch = await honeycombs.getEpochData(1)
    const secondEpoch = await honeycombs.getEpochData(2)
    expect(firstEpoch.committed).to.equal(true)
    expect(firstEpoch.revealed).to.equal(false)
    expect(secondEpoch.committed).to.equal(false)
    expect(secondEpoch.revealed).to.equal(false)
  })

  it('Should mint and reveal tokens', async () => {
    const { honeycombs } = await loadFixture(deployHoneycombs)
    const { jalil } = await loadFixture(impersonateAccounts)

    await expect(honeycombs.connect(jalil).mint([808], jalil.address))
      .not.to.emit(honeycombs, 'NewEpoch')

    await mine(50)
    await expect(honeycombs.resolveEpochIfNecessary())
      .to.emit(honeycombs, 'NewEpoch')

    const afterReveal = await honeycombs.getHoneycomb(808)
    expect(afterReveal.isRevealed).to.equal(true)

    const firstEpoch = await honeycombs.getEpochData(1)
    const secondEpoch = await honeycombs.getEpochData(2)
    expect(firstEpoch.committed).to.equal(true)
    expect(firstEpoch.revealed).to.equal(true)
    expect(secondEpoch.committed).to.equal(true)
    expect(secondEpoch.revealed).to.equal(false)
  })

  it('Should mint and auto-reveal tokens on new mints', async () => {
    const { honeycombs } = await loadFixture(deployHoneycombs)
    const { jalil } = await loadFixture(impersonateAccounts)

    const tx = await honeycombs.connect(jalil).mint([808, 1444], jalil.address)
    await expect(tx).not.to.emit(honeycombs, 'NewEpoch')
    await mine(50)

    const revealBlock = (await tx.wait()).blockNumber + 50

    await expect(honeycombs.connect(jalil).mint([1750, 1909], jalil.address))
      .to.emit(honeycombs, 'NewEpoch')
      .withArgs(1, revealBlock)
    expect((await honeycombs.getHoneycomb(808)).isRevealed).to.equal(true)
    expect((await honeycombs.getHoneycomb(1444)).isRevealed).to.equal(true)
    expect((await honeycombs.getHoneycomb(1750)).isRevealed).to.equal(false)
    expect((await honeycombs.getHoneycomb(1909)).isRevealed).to.equal(false)

    const firstEpoch = await honeycombs.getEpochData(1)
    const secondEpoch = await honeycombs.getEpochData(2)
    expect(firstEpoch.committed).to.equal(true)
    expect(firstEpoch.revealed).to.equal(true)
    expect(secondEpoch.committed).to.equal(true)
    expect(secondEpoch.revealed).to.equal(false)
  })

  it('Should extend a previous commitment', async () => {
    const { honeycombs } = await loadFixture(deployHoneycombs)
    const { jalil } = await loadFixture(impersonateAccounts)

    await expect(honeycombs.connect(jalil).mint([808], jalil.address))
      .not.to.emit(honeycombs, 'NewEpoch')
    await mine(306)

    await expect(honeycombs.connect(jalil).mint([1444], jalil.address))
      .not.to.emit(honeycombs, 'NewEpoch')
    expect((await honeycombs.getHoneycomb(808)).isRevealed).to.equal(false)
    expect((await honeycombs.getHoneycomb(1444)).isRevealed).to.equal(false)

    await mine(50)
    await expect(honeycombs.connect(jalil).mint([1750], jalil.address))
      .to.emit(honeycombs, 'NewEpoch')

    expect((await honeycombs.getHoneycomb(808)).isRevealed).to.equal(true)
    expect((await honeycombs.getHoneycomb(1444)).isRevealed).to.equal(true)
    expect((await honeycombs.getHoneycomb(1750)).isRevealed).to.equal(false)

    const firstEpoch = await honeycombs.getEpochData(1)
    const secondEpoch = await honeycombs.getEpochData(2)
    expect(firstEpoch.committed).to.equal(true)
    expect(firstEpoch.revealed).to.equal(true)
    expect(secondEpoch.committed).to.equal(true)
    expect(secondEpoch.revealed).to.equal(false)
  })

  it('Should allow manually creating new epochs between mints', async () => {
    const { honeycombs } = await loadFixture(deployHoneycombs)
    const { jalil } = await loadFixture(impersonateAccounts)

    await honeycombs.connect(jalil).mint([808], jalil.address)
    expect(await honeycombs.getEpoch()).to.equal(1)
    await mine(50)
    await (await honeycombs.resolveEpochIfNecessary()).wait()
    expect((await honeycombs.getHoneycomb(808)).isRevealed).to.equal(true)
    expect(await honeycombs.getEpoch()).to.equal(2)
    await mine(50)
    await (await honeycombs.resolveEpochIfNecessary()).wait()
    await (await honeycombs.resolveEpochIfNecessary()).wait()
    await (await honeycombs.resolveEpochIfNecessary()).wait()
    expect(await honeycombs.getEpoch()).to.equal(3)
    await mine(50)
    await honeycombs.connect(jalil).mint([1444], jalil.address)
    expect(await honeycombs.getEpoch()).to.equal(4)
    await mine(50)
    expect(await honeycombs.getEpoch()).to.equal(4)
    expect((await honeycombs.getHoneycomb(1444)).isRevealed).to.equal(false)
    await (await honeycombs.resolveEpochIfNecessary()).wait()
    expect((await honeycombs.getHoneycomb(1444)).isRevealed).to.equal(true)
    expect(await honeycombs.getEpoch()).to.equal(5)
    await mine(306)
    await honeycombs.connect(jalil).mint([1750], jalil.address)
    expect(await honeycombs.getEpoch()).to.equal(5)
    await mine(3)
    await (await honeycombs.resolveEpochIfNecessary()).wait()
    expect((await honeycombs.getHoneycomb(1750)).isRevealed).to.equal(false)
    expect(await honeycombs.getEpoch()).to.equal(5)
    await mine(50)
    await (await honeycombs.resolveEpochIfNecessary()).wait()
    expect((await honeycombs.getHoneycomb(1750)).isRevealed).to.equal(true)
    expect(await honeycombs.getEpoch()).to.equal(6)
    await mine(50)

    let epoch = await honeycombs.getEpochData(1)
    expect(epoch.committed).to.equal(true)
    expect(epoch.revealed).to.equal(true)
    epoch = await honeycombs.getEpochData(4)
    expect(epoch.committed).to.equal(true)
    expect(epoch.revealed).to.equal(true)
    epoch = await honeycombs.getEpochData(5)
    expect(epoch.committed).to.equal(true)
    expect(epoch.revealed).to.equal(true)
    epoch = await honeycombs.getEpochData(6)
    expect(epoch.committed).to.equal(true)
    expect(epoch.revealed).to.equal(false)
  })
})
