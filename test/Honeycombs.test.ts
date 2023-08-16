import fs from 'fs';
import {
  loadFixture,
  mine,
  time,
} from '@nomicfoundation/hardhat-network-helpers';
import { deployHoneycombs } from './fixtures/deploy';
import { impersonateAccounts } from './fixtures/impersonate';
import { mintedFixture } from './fixtures/mint';
import {
  USER_1,
  USER_2,
  USER_1_TOKENS,
  USER_2_TOKENS,
  VAULT,
} from '../helpers/constants';
import { fetchAndRender } from '../helpers/render';
const { expect } = require('chai');
const hre = require('hardhat');
const ethers = hre.ethers;

describe('Honeycombs', () => {
  it('Should deploy honeycombs', async () => {
    const { honeycombs } = await loadFixture(deployHoneycombs);

    expect(await honeycombs.name()).to.equal('Honeycombs');
    expect(await honeycombs.symbol()).to.equal('HONEYCOMBS');
  });

  describe('Mint', () => {
    it('Should mint and render', async () => {
      const { honeycombs } = await loadFixture(deployHoneycombs);
      const { user1 } = await loadFixture(impersonateAccounts);

      expect(await honeycombs.totalSupply()).to.equal(0);

      await expect(honeycombs.connect(user1).mint(111, VAULT))
        .to.emit(honeycombs, 'Transfer')
        .withArgs(ethers.constants.AddressZero, USER_1, 111)
        .to.emit(honeycombs, 'Transfer')
        .withArgs(USER_1, VAULT, 111);

      expect(await honeycombs.totalSupply()).to.equal(1);
      await mine(50);
      await fetchAndRender(honeycombs, 111, 'post_reveal_');

      const tx = await honeycombs.connect(user1).mint(222, USER_1);
      await expect(tx)
        .to.emit(honeycombs, 'Transfer')
        .withArgs(ethers.constants.AddressZero, USER_1, 222)
        .to.emit(honeycombs, 'NewEpoch');
      const receipt = await tx.wait();
      expect(receipt.events.length).to.equal(2); // new mint + new epoch

      expect(await honeycombs.totalSupply()).to.equal(2);
    });

    it('Should set the token birth date correctly at mint', async () => {
      const { honeycombs } = await loadFixture(deployHoneycombs);
      const { user1 } = await loadFixture(impersonateAccounts);

      // Then we can mint one
      await expect(honeycombs.connect(user1).mint(333, USER_1))
        .to.emit(honeycombs, 'Transfer')
        .withArgs(ethers.constants.AddressZero, USER_1, 333);
      expect((await honeycombs.getHoneycomb(333)).stored.day).to.equal(1);

      await time.increase(3600 * 24);

      await expect(honeycombs.connect(user1).mint(444, USER_1))
        .to.emit(honeycombs, 'Transfer')
        .withArgs(ethers.constants.AddressZero, USER_1, 444);
      expect((await honeycombs.getHoneycomb(444)).stored.day).to.equal(2);
    });

    it.only('Should not allow minting of the same token twice', async () => {
      const { honeycombs } = await loadFixture(deployHoneycombs);
      const { user1 } = await loadFixture(impersonateAccounts);

      await honeycombs.connect(user1).mint(555, USER_1);

      await expect(
        honeycombs.connect(user1).mint(555, USER_1),
      ).to.be.revertedWithCustomError(honeycombs, 'ERC721__TokenExists');
    });
  });

  describe('Burning', () => {
    it('Should not allow non approved operators to burn tokens', async () => {
      const { honeycombs, user2 } = await loadFixture(mintedFixture);

      await expect(
        honeycombs.connect(user2).burn(USER_1_TOKENS[0]),
      ).to.be.revertedWithCustomError(honeycombs, 'NotAllowed');
    });

    it('Should allow holders to burn their tokens', async () => {
      const { honeycombs, user2 } = await loadFixture(mintedFixture);

      await expect(honeycombs.connect(user2).burn(USER_2_TOKENS[0]))
        .to.emit(honeycombs, 'Transfer')
        .withArgs(
          user2.address,
          ethers.constants.AddressZero,
          USER_2_TOKENS[0],
        );
    });

    it('Should properly track total supply when users burn burn their tokens', async () => {
      const { honeycombs, user2 } = await loadFixture(mintedFixture);

      expect(await honeycombs.totalSupply()).to.equal(
        USER_1_TOKENS.length + USER_2_TOKENS.length,
      );
      await honeycombs.connect(user2).burn(USER_2_TOKENS[0]);
      expect(await honeycombs.totalSupply()).to.equal(
        USER_1_TOKENS.length + USER_2_TOKENS.length - 1,
      );
    });
  });

  describe('Reveal Mechanics - Detailed', () => {
    it('Should mint unrevealed tokens', async () => {
      const { honeycombs } = await loadFixture(deployHoneycombs);
      const { user1 } = await loadFixture(impersonateAccounts);

      await expect(
        honeycombs.connect(user1).mint(369, user1.address),
      ).not.to.emit(honeycombs, 'NewEpoch');

      const beforeReveal = await honeycombs.getHoneycomb(369);
      expect(beforeReveal.isRevealed).to.equal(false);

      await mine(50);
      expect((await honeycombs.getHoneycomb(369)).isRevealed).to.equal(false);

      const firstEpoch = await honeycombs.getEpochData(1);
      const secondEpoch = await honeycombs.getEpochData(2);
      expect(firstEpoch.committed).to.equal(true);
      expect(firstEpoch.revealed).to.equal(false);
      expect(secondEpoch.committed).to.equal(false);
      expect(secondEpoch.revealed).to.equal(false);
    });

    it('Should mint and reveal tokens', async () => {
      const { honeycombs } = await loadFixture(deployHoneycombs);
      const { user1 } = await loadFixture(impersonateAccounts);

      await expect(
        honeycombs.connect(user1).mint(369, user1.address),
      ).not.to.emit(honeycombs, 'NewEpoch');

      await mine(50);
      await expect(honeycombs.resolveEpochIfNecessary()).to.emit(
        honeycombs,
        'NewEpoch',
      );

      const afterReveal = await honeycombs.getHoneycomb(369);
      expect(afterReveal.isRevealed).to.equal(true);

      const firstEpoch = await honeycombs.getEpochData(1);
      const secondEpoch = await honeycombs.getEpochData(2);
      expect(firstEpoch.committed).to.equal(true);
      expect(firstEpoch.revealed).to.equal(true);
      expect(secondEpoch.committed).to.equal(true);
      expect(secondEpoch.revealed).to.equal(false);
    });

    it('Should mint and auto-reveal tokens on new mints', async () => {
      const { honeycombs } = await loadFixture(deployHoneycombs);
      const { user1 } = await loadFixture(impersonateAccounts);

      const tx = await honeycombs.connect(user1).mint(369, user1.address);
      await expect(tx).not.to.emit(honeycombs, 'NewEpoch');
      await mine(50);

      const revealBlock = (await tx.wait()).blockNumber + 50;

      await expect(honeycombs.connect(user1).mint(738, user1.address))
        .to.emit(honeycombs, 'NewEpoch')
        .withArgs(1, revealBlock);
      expect((await honeycombs.getHoneycomb(369)).isRevealed).to.equal(true);
      expect((await honeycombs.getHoneycomb(738)).isRevealed).to.equal(false);

      const firstEpoch = await honeycombs.getEpochData(1);
      const secondEpoch = await honeycombs.getEpochData(2);
      expect(firstEpoch.committed).to.equal(true);
      expect(firstEpoch.revealed).to.equal(true);
      expect(secondEpoch.committed).to.equal(true);
      expect(secondEpoch.revealed).to.equal(false);
    });

    it('Should extend a previous commitment', async () => {
      const { honeycombs } = await loadFixture(deployHoneycombs);
      const { user1 } = await loadFixture(impersonateAccounts);

      await expect(
        honeycombs.connect(user1).mint(369, user1.address),
      ).not.to.emit(honeycombs, 'NewEpoch');
      await mine(306);

      await expect(
        honeycombs.connect(user1).mint(1444, user1.address),
      ).not.to.emit(honeycombs, 'NewEpoch');
      expect((await honeycombs.getHoneycomb(369)).isRevealed).to.equal(false);
      expect((await honeycombs.getHoneycomb(1444)).isRevealed).to.equal(false);

      await mine(50);
      await expect(honeycombs.connect(user1).mint(1032, user1.address)).to.emit(
        honeycombs,
        'NewEpoch',
      );

      expect((await honeycombs.getHoneycomb(369)).isRevealed).to.equal(true);
      expect((await honeycombs.getHoneycomb(1444)).isRevealed).to.equal(true);
      expect((await honeycombs.getHoneycomb(1032)).isRevealed).to.equal(false);

      const firstEpoch = await honeycombs.getEpochData(1);
      const secondEpoch = await honeycombs.getEpochData(2);
      expect(firstEpoch.committed).to.equal(true);
      expect(firstEpoch.revealed).to.equal(true);
      expect(secondEpoch.committed).to.equal(true);
      expect(secondEpoch.revealed).to.equal(false);
    });

    it('Should allow manually creating new epochs between mints', async () => {
      const { honeycombs } = await loadFixture(deployHoneycombs);
      const { user1 } = await loadFixture(impersonateAccounts);

      await honeycombs.connect(user1).mint(369, user1.address);
      expect(await honeycombs.getEpoch()).to.equal(1);
      await mine(50);
      await (await honeycombs.resolveEpochIfNecessary()).wait();
      expect((await honeycombs.getHoneycomb(369)).isRevealed).to.equal(true);
      expect(await honeycombs.getEpoch()).to.equal(2);
      await mine(50);
      await (await honeycombs.resolveEpochIfNecessary()).wait();
      await (await honeycombs.resolveEpochIfNecessary()).wait();
      await (await honeycombs.resolveEpochIfNecessary()).wait();
      expect(await honeycombs.getEpoch()).to.equal(3);
      await mine(50);
      await honeycombs.connect(user1).mint(1444, user1.address);
      expect(await honeycombs.getEpoch()).to.equal(4);
      await mine(50);
      expect(await honeycombs.getEpoch()).to.equal(4);
      expect((await honeycombs.getHoneycomb(1444)).isRevealed).to.equal(false);
      await (await honeycombs.resolveEpochIfNecessary()).wait();
      expect((await honeycombs.getHoneycomb(1444)).isRevealed).to.equal(true);
      expect(await honeycombs.getEpoch()).to.equal(5);
      await mine(306);
      await honeycombs.connect(user1).mint(1032, user1.address);
      expect(await honeycombs.getEpoch()).to.equal(5);
      await mine(3);
      await (await honeycombs.resolveEpochIfNecessary()).wait();
      expect((await honeycombs.getHoneycomb(1032)).isRevealed).to.equal(false);
      expect(await honeycombs.getEpoch()).to.equal(5);
      await mine(50);
      await (await honeycombs.resolveEpochIfNecessary()).wait();
      expect((await honeycombs.getHoneycomb(1032)).isRevealed).to.equal(true);
      expect(await honeycombs.getEpoch()).to.equal(6);
      await mine(50);

      let epoch = await honeycombs.getEpochData(1);
      expect(epoch.committed).to.equal(true);
      expect(epoch.revealed).to.equal(true);
      epoch = await honeycombs.getEpochData(4);
      expect(epoch.committed).to.equal(true);
      expect(epoch.revealed).to.equal(true);
      epoch = await honeycombs.getEpochData(5);
      expect(epoch.committed).to.equal(true);
      expect(epoch.revealed).to.equal(true);
      epoch = await honeycombs.getEpochData(6);
      expect(epoch.committed).to.equal(true);
      expect(epoch.revealed).to.equal(false);
    });
  });

  describe.only('Simulate Onchain Activity', () => {
    it('Should blitz activity for no runtime errors', async () => {
      const { honeycombs } = await loadFixture(deployHoneycombs);
      const { user1, user2 } = await loadFixture(impersonateAccounts);

      const tokenIds: number[] = [];
      const mintsPerUser = 20;
      const randomBlocksMax = 100;

      // Mint random token ids and randomly mine between each mint
      for (let i = 0; i < mintsPerUser; i++) {
        let tokenId;

        // Get random token id that does not exist
        do {
          tokenId = Math.floor(Math.random() * 10000);
        } while (tokenIds.includes(tokenId));

        tokenIds.push(tokenId);
        await honeycombs.connect(user1).mint(tokenId, user1.address);
        await mine(Math.floor(Math.random() * randomBlocksMax));
      }

      // Randomly mint tokens to a different user
      for (let i = 0; i < mintsPerUser; i++) {
        let tokenId;
        do {
          tokenId = Math.floor(Math.random() * 10000);
        } while (tokenIds.includes(tokenId));

        tokenIds.push(tokenId);
        await honeycombs.connect(user2).mint(tokenId, user2.address);
      }

      // Randomly mine between 0 and 100 blocks
      await mine(Math.floor(Math.random() * randomBlocksMax));

      // Fetch and Render the honeycombs for all token ids
      for (const tokenId of tokenIds) {
        await fetchAndRender(honeycombs, tokenId, 'blitz_');
      }
    });
  });
});
