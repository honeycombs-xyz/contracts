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
  MAX_MINTS_PER_ADDRESS,
  VAULT,
  RESERVE_ADDRESS_1,
  RESERVE_ADDRESS_2,
} from '../helpers/constants';
import { fetchAndRender } from '../helpers/render';
import { decodeBase64URI } from '../helpers/decode-uri';
const { expect } = require('chai');
const hre = require('hardhat');
const ethers = hre.ethers;

describe('Honeycombs', () => {
  it('Should deploy honeycombs', async () => {
    const { honeycombs } = await loadFixture(deployHoneycombs);

    expect(await honeycombs.name()).to.equal('Honeycombs');
    expect(await honeycombs.symbol()).to.equal('HONEYCOMBS');
  });

  describe.only('Mint', () => {
    it('Should mint and render', async () => {
      const { honeycombs } = await loadFixture(deployHoneycombs);
      const { user1 } = await loadFixture(impersonateAccounts);

      expect(await honeycombs.totalSupply()).to.equal(0);

      expect(
        await honeycombs
          .connect(user1)
          .mint(1, VAULT, { value: ethers.utils.parseEther('0.1') }),
      )
        .to.emit(honeycombs, 'Transfer')
        .withArgs(ethers.constants.AddressZero, USER_1, 1)
        .to.emit(honeycombs, 'Transfer')
        .withArgs(USER_1, VAULT, 1);

      // total supply will be 3 because of the 2 reserved tokens
      expect(await honeycombs.totalSupply()).to.equal(3);
      await mine(50);
      await honeycombs.resolveEpochIfNecessary();
      await fetchAndRender(honeycombs, 1, 'post_reveal_');
      await fetchAndRender(honeycombs, 2, 'post_reveal_');
      await fetchAndRender(honeycombs, 3, 'post_reveal_');
    });

    it('Should allow multiple mints', async () => {
      const { honeycombs } = await loadFixture(deployHoneycombs);
      const { user1, user2 } = await loadFixture(impersonateAccounts);

      expect(
        await honeycombs
          .connect(user1)
          .mint(1, USER_1, { value: ethers.utils.parseEther('0.1') }),
      )
        .to.emit(honeycombs, 'Transfer')
        .withArgs(ethers.constants.AddressZero, USER_1, 1)
        .to.emit(honeycombs, 'Transfer')
        .withArgs(ethers.constants.AddressZero, RESERVE_ADDRESS_1, 2)
        .to.emit(honeycombs, 'Transfer')
        .withArgs(ethers.constants.AddressZero, RESERVE_ADDRESS_2, 3);
      expect(
        await honeycombs
          .connect(user1)
          .mint(2, USER_1, { value: ethers.utils.parseEther('0.2') }),
      )
        .to.emit(honeycombs, 'Transfer')
        .withArgs(ethers.constants.AddressZero, USER_1, 4)
        .to.emit(honeycombs, 'Transfer')
        .withArgs(ethers.constants.AddressZero, USER_1, 5);

      await mine(50);

      const tx = await honeycombs
        .connect(user2)
        .mint(1, USER_2, { value: ethers.utils.parseEther('0.1') });
      expect(tx)
        .to.emit(honeycombs, 'Transfer')
        .withArgs(ethers.constants.AddressZero, USER_2, 6);
      const receipt = await tx.wait();
      expect(receipt.events.length).to.equal(2); // new mint + new epoch

      expect(await honeycombs.totalSupply()).to.equal(6);
    });

    it('Should transfer the correct amount of eth to the reserve addresses', async () => {
      const { honeycombs } = await loadFixture(deployHoneycombs);
      const { user1 } = await loadFixture(impersonateAccounts);
      const honeycombsBalanceBefore = await ethers.provider.getBalance(
        honeycombs.address,
      );
      const reserve2BalanceBefore = await ethers.provider.getBalance(
        RESERVE_ADDRESS_2,
      );

      await honeycombs
        .connect(user1)
        .mint(2, USER_1, { value: ethers.utils.parseEther('0.2') });

      const honeycombsBalanceAfter = await ethers.provider.getBalance(
        honeycombs.address,
      );
      const reserve2BalanceAfter = await ethers.provider.getBalance(
        RESERVE_ADDRESS_2,
      );

      expect(
        honeycombsBalanceAfter.sub(honeycombsBalanceBefore).toString(),
      ).to.equal(ethers.utils.parseEther('0.16').toString());
      expect(
        reserve2BalanceAfter.sub(reserve2BalanceBefore).toString(),
      ).to.equal(ethers.utils.parseEther('0.04').toString());
    });

    it('Should set the token birth date correctly at mint', async () => {
      const { honeycombs } = await loadFixture(deployHoneycombs);
      const { user1 } = await loadFixture(impersonateAccounts);

      // Then we can mint one
      expect(
        await honeycombs
          .connect(user1)
          .mint(1, USER_1, { value: ethers.utils.parseEther('0.1') }),
      )
        .to.emit(honeycombs, 'Transfer')
        .withArgs(ethers.constants.AddressZero, USER_1, 1);
      expect((await honeycombs.getHoneycomb(1)).stored.day).to.equal(1);

      await time.increase(3600 * 24);

      expect(
        await honeycombs
          .connect(user1)
          .mint(1, USER_1, { value: ethers.utils.parseEther('0.1') }),
      )
        .to.emit(honeycombs, 'Transfer')
        .withArgs(ethers.constants.AddressZero, USER_1, 4); // auto reserve is 2
      expect((await honeycombs.getHoneycomb(4)).stored.day).to.equal(2);
    });

    it('Should not allow minting with an invalid number of tokens', async () => {
      const { honeycombs } = await loadFixture(deployHoneycombs);
      const { user1 } = await loadFixture(impersonateAccounts);

      await expect(
        honeycombs
          .connect(user1)
          .mint(0, USER_1, { value: ethers.utils.parseEther('0.1') }),
      ).to.be.revertedWithCustomError(honeycombs, 'NotAllowed');

      await expect(
        honeycombs
          .connect(user1)
          .mint(6, USER_1, { value: ethers.utils.parseEther('0.6') }),
      ).to.be.revertedWithCustomError(honeycombs, 'NotAllowed');
    });

    it('Should not allow minting with an inexact value in eth', async () => {
      const { honeycombs } = await loadFixture(deployHoneycombs);
      const { user1 } = await loadFixture(impersonateAccounts);
      await expect(
        honeycombs
          .connect(user1)
          .mint(1, USER_1, { value: ethers.utils.parseEther('0.09') }),
      ).to.be.revertedWithCustomError(honeycombs, 'NotExactEth');

      await expect(
        honeycombs
          .connect(user1)
          .mint(3, USER_1, { value: ethers.utils.parseEther('0.27') }),
      ).to.be.revertedWithCustomError(honeycombs, 'NotExactEth');
    });

    it('Should not allow minting more than the max per address', async () => {
      const { honeycombs } = await loadFixture(deployHoneycombs);
      const { user1 } = await loadFixture(impersonateAccounts);

      await expect(
        honeycombs
          .connect(user1)
          .mint(6, VAULT, { value: ethers.utils.parseEther('0.6') }),
      ).to.be.revertedWithCustomError(honeycombs, 'NotAllowed');

      // Mint the max per address
      for (let i = 0; i < MAX_MINTS_PER_ADDRESS; i++) {
        await honeycombs
          .connect(user1)
          .mint(1, USER_1, { value: ethers.utils.parseEther('0.1') });
      }

      // Attempt to mint one more
      await expect(
        honeycombs
          .connect(user1)
          .mint(1, USER_1, { value: ethers.utils.parseEther('0.1') }),
      ).to.be.revertedWithCustomError(honeycombs, 'MaxMintPerAddressReached');
    });
  });

  describe('Burning', () => {
    it('Should not allow non approved operators to burn tokens', async () => {
      const { honeycombs, user2 } = await loadFixture(mintedFixture);

      await expect(
        honeycombs.connect(user2).burn(1),
      ).to.be.revertedWithCustomError(honeycombs, 'NotAllowed');
    });

    it('Should allow holders to burn their tokens', async () => {
      const { honeycombs, user2 } = await loadFixture(mintedFixture);

      await expect(honeycombs.connect(user2).burn(8))
        .to.emit(honeycombs, 'Transfer')
        .withArgs(user2.address, ethers.constants.AddressZero, 8);
    });

    it('Should properly track total supply when users burn burn their tokens', async () => {
      const { honeycombs, user2 } = await loadFixture(mintedFixture);

      expect(await honeycombs.totalSupply()).to.equal(
        MAX_MINTS_PER_ADDRESS * 2 + 2, // 2 reserved tokens
      );
      await honeycombs.connect(user2).burn(8);
      expect(await honeycombs.totalSupply()).to.equal(
        MAX_MINTS_PER_ADDRESS * 2 + 2 - 1,
      );
    });
  });

  describe('Reveal Mechanics - Detailed', () => {
    it('Should mint unrevealed tokens', async () => {
      const { honeycombs } = await loadFixture(deployHoneycombs);
      const { user1 } = await loadFixture(impersonateAccounts);

      await expect(
        honeycombs
          .connect(user1)
          .mint(1, user1.address, { value: ethers.utils.parseEther('0.1') }),
      ).not.to.emit(honeycombs, 'NewEpoch');

      const beforeReveal = await honeycombs.getHoneycomb(1);
      expect(beforeReveal.isRevealed).to.equal(false);

      await mine(50);
      expect((await honeycombs.getHoneycomb(1)).isRevealed).to.equal(false);

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
        honeycombs
          .connect(user1)
          .mint(1, user1.address, { value: ethers.utils.parseEther('0.1') }),
      ).not.to.emit(honeycombs, 'NewEpoch');

      await mine(50);
      await expect(honeycombs.resolveEpochIfNecessary()).to.emit(
        honeycombs,
        'NewEpoch',
      );

      const afterReveal = await honeycombs.getHoneycomb(1);
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

      const tx = await honeycombs
        .connect(user1)
        .mint(1, user1.address, { value: ethers.utils.parseEther('0.1') });
      await expect(tx).not.to.emit(honeycombs, 'NewEpoch');
      await mine(50);

      const revealBlock = (await tx.wait()).blockNumber + 50;

      await expect(
        honeycombs
          .connect(user1)
          .mint(1, user1.address, { value: ethers.utils.parseEther('0.1') }),
      )
        .to.emit(honeycombs, 'NewEpoch')
        .withArgs(1, revealBlock);
      expect((await honeycombs.getHoneycomb(1)).isRevealed).to.equal(true);
      expect((await honeycombs.getHoneycomb(4)).isRevealed).to.equal(false); // auto reserve is 2

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
        honeycombs
          .connect(user1)
          .mint(1, user1.address, { value: ethers.utils.parseEther('0.1') }),
      ).not.to.emit(honeycombs, 'NewEpoch');
      await mine(306);

      await expect(
        honeycombs
          .connect(user1)
          .mint(1, user1.address, { value: ethers.utils.parseEther('0.1') }),
      ).not.to.emit(honeycombs, 'NewEpoch');
      expect((await honeycombs.getHoneycomb(1)).isRevealed).to.equal(false);
      expect((await honeycombs.getHoneycomb(4)).isRevealed).to.equal(false); // auto reserve is 2

      await mine(50);
      await expect(
        honeycombs
          .connect(user1)
          .mint(1, user1.address, { value: ethers.utils.parseEther('0.1') }),
      ).to.emit(honeycombs, 'NewEpoch');

      expect((await honeycombs.getHoneycomb(1)).isRevealed).to.equal(true);
      expect((await honeycombs.getHoneycomb(4)).isRevealed).to.equal(true);
      expect((await honeycombs.getHoneycomb(5)).isRevealed).to.equal(false);

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

      await honeycombs
        .connect(user1)
        .mint(1, user1.address, { value: ethers.utils.parseEther('0.1') });
      expect(await honeycombs.getEpoch()).to.equal(1);
      await mine(50);
      await (await honeycombs.resolveEpochIfNecessary()).wait();
      expect((await honeycombs.getHoneycomb(1)).isRevealed).to.equal(true);
      expect(await honeycombs.getEpoch()).to.equal(2);
      await mine(50);
      await (await honeycombs.resolveEpochIfNecessary()).wait();
      await (await honeycombs.resolveEpochIfNecessary()).wait();
      await (await honeycombs.resolveEpochIfNecessary()).wait();
      expect(await honeycombs.getEpoch()).to.equal(3);
      await mine(50);
      await honeycombs
        .connect(user1)
        .mint(1, user1.address, { value: ethers.utils.parseEther('0.1') });
      expect(await honeycombs.getEpoch()).to.equal(4);
      await mine(50);
      expect(await honeycombs.getEpoch()).to.equal(4);
      expect((await honeycombs.getHoneycomb(4)).isRevealed).to.equal(false);
      await (await honeycombs.resolveEpochIfNecessary()).wait();
      expect((await honeycombs.getHoneycomb(4)).isRevealed).to.equal(true);
      expect(await honeycombs.getEpoch()).to.equal(5);
      await mine(306);
      await honeycombs
        .connect(user1)
        .mint(1, user1.address, { value: ethers.utils.parseEther('0.1') });
      expect(await honeycombs.getEpoch()).to.equal(5);
      await mine(3);
      await (await honeycombs.resolveEpochIfNecessary()).wait();
      expect((await honeycombs.getHoneycomb(5)).isRevealed).to.equal(false);
      expect(await honeycombs.getEpoch()).to.equal(5);
      await mine(50);
      await (await honeycombs.resolveEpochIfNecessary()).wait();
      expect((await honeycombs.getHoneycomb(5)).isRevealed).to.equal(true);
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

  describe('Simulate Onchain Activity', () => {
    it('Should blitz activity for no runtime errors', async () => {
      const { honeycombs } = await loadFixture(deployHoneycombs);
      const { user1, user2, vault, whale } = await loadFixture(
        impersonateAccounts,
      );

      const maxMintsPerUser = 5;
      const randomBlocksMax = 100;

      // user1
      const user1Tokens = Math.floor(Math.random() * maxMintsPerUser) + 1;
      await honeycombs.connect(user1).mint(user1Tokens, user1.address, {
        value: ethers.utils.parseEther(0.1 * user1Tokens + ''),
      });
      await mine(Math.floor(Math.random() * randomBlocksMax));

      // user2
      const user2Tokens = Math.floor(Math.random() * maxMintsPerUser) + 1;
      await honeycombs.connect(user2).mint(user2Tokens, user2.address, {
        value: ethers.utils.parseEther(0.1 * user2Tokens + ''),
      });
      await mine(Math.floor(Math.random() * randomBlocksMax));

      // Fetch and Render the honeycombs for all token ids
      const numberOfTokens = await honeycombs.totalSupply();
      for (let tokenId = 1; tokenId <= numberOfTokens; tokenId++) {
        // +2 for the 2 reserved tokens
        await fetchAndRender(honeycombs, tokenId, 'blitz_');

        // Get associated metadata and write to file for debugging
        const metadata = decodeBase64URI(await honeycombs.tokenURI(tokenId));
        fs.writeFileSync(
          `test/dist/decoded-tokenuri-${tokenId}.json`,
          JSON.stringify(metadata),
        );
      }
    });
  });
});
