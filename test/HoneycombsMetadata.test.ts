import fs from 'fs';
import { loadFixture, mine } from '@nomicfoundation/hardhat-network-helpers';
import { deployHoneycombs } from './fixtures/deploy';
import { impersonateAccounts } from './fixtures/impersonate';
import { mintedFixture } from './fixtures/mint';
import { MAX_MINTS_PER_ADDRESS, VAULT } from '../helpers/constants';
import { fetchAndRender } from '../helpers/render';
import { decodeBase64URI } from '../helpers/decode-uri';
import { ethers } from 'hardhat';
const { expect } = require('chai');

describe('Metadata', () => {
  it('Should show correct metadata', async () => {
    const { honeycombs } = await loadFixture(mintedFixture);

    const uri = await honeycombs.tokenURI(MAX_MINTS_PER_ADDRESS);
    fs.writeFileSync(`test/dist/tokenuri-${MAX_MINTS_PER_ADDRESS}`, uri);

    const uri2 = await honeycombs.tokenURI(MAX_MINTS_PER_ADDRESS + 1);
    fs.writeFileSync(`test/dist/tokenuri-${MAX_MINTS_PER_ADDRESS + 1}`, uri2);
  });

  it('Should render unrevealed tokens', async () => {
    const { honeycombs } = await loadFixture(deployHoneycombs);
    const { user1 } = await loadFixture(impersonateAccounts);

    await honeycombs
      .connect(user1)
      .mint(1, VAULT, { value: ethers.utils.parseEther('0.1') });
    await fetchAndRender(honeycombs, 1, 'pre_reveal_');
  });

  it('Should render metadata for unrevealed tokens', async () => {
    const { honeycombs } = await loadFixture(deployHoneycombs);
    const { user1 } = await loadFixture(impersonateAccounts);

    await honeycombs
      .connect(user1)
      .mint(1, VAULT, { value: ethers.utils.parseEther('0.1') });

    const metadataURI = await honeycombs.tokenURI(1);
    expect(decodeBase64URI(metadataURI).attributes).to.deep.equal([
      { trait_type: 'Revealed', value: 'No' },
      { trait_type: 'Day', value: '1' },
    ]);
  });

  it('Should render metadata for revealed tokens', async () => {
    const { honeycombs } = await loadFixture(deployHoneycombs);
    const { user1 } = await loadFixture(impersonateAccounts);

    await honeycombs
      .connect(user1)
      .mint(1, VAULT, { value: ethers.utils.parseEther('0.1') });
    await mine(50);
    await honeycombs.resolveEpochIfNecessary();

    const afterReveal = decodeBase64URI(await honeycombs.tokenURI(1));
    fs.writeFileSync(
      `test/dist/decoded-tokenuri-1`,
      JSON.stringify(afterReveal),
    );
    expect(afterReveal.attributes).to.not.have.deep.members([
      { trait_type: 'Revealed', value: 'No' },
    ]);

    expect(
      afterReveal.attributes.map(
        (a: { trait_type: string; value: string }) => a.trait_type,
      ),
    )
      .to.have.members([
        'Canvas Color',
        'Base Hexagon',
        'Base Hexagon Fill Color',
        'Stroke Width',
        'Shape',
        'Rows',
        'Rotation',
        'Chrome',
        'Duration',
        'Direction',
        'Day',
      ])
      .but.not.include('Revealed');
  });
});
