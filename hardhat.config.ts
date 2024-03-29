import * as dotenv from 'dotenv';

import '@nomicfoundation/hardhat-chai-matchers';
import '@nomiclabs/hardhat-etherscan';
import '@nomiclabs/hardhat-ethers';
import '@typechain/hardhat';
import 'hardhat-contract-sizer';
import 'hardhat-gas-reporter';
import 'solidity-coverage';

import './tasks/accounts';
import './tasks/deploy';
import './tasks/mine';
import './tasks/mint';
import './tasks/render';
import './tasks/withdraw';
import './tasks/resolveEpoch';

dotenv.config();

const HARDHAT_NETWORK_CONFIG = {
  chainId: 1337,
  forking: {
    url: process.env.MAINNET_URL || '',
    blockNumber: 16501065,
  },
  allowUnlimitedContractSize: true,

};

const config = {
  solidity: '0.8.17',
  settings: {
    optimizer: {
      enabled: true,
      runs: 1000,
    },
  },
  networks: {
    sepolia: {
      url: process.env.SEPOLIA_URL || '',
      accounts:
        // use mnemonic if defined, otherwise use private key
        process.env.MNEMONIC !== undefined
          ? {
              mnemonic: process.env.MNEMONIC,
              path: "m/44'/60'/0'/0",
              initialIndex: 0,
              count: 1,
            }
          : process.env.PRIVATE_KEY !== undefined
          ? [process.env.PRIVATE_KEY]
          : [],
    },
    mainnet: {
      url: process.env.MAINNET_URL || '',
      accounts:
        // use mnemonic if defined
        process.env.MNEMONIC !== undefined
          ? {
              mnemonic: process.env.MNEMONIC,
              path: "m/44'/60'/0'/0",
              initialIndex: 0,
              count: 2,
            }
          : [],
    },
    localhost: {
      ...HARDHAT_NETWORK_CONFIG
    },
    hardhat: HARDHAT_NETWORK_CONFIG,
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    coinmarketcap: process.env.COINMARKETCAP_API_KEY,
    currency: 'USD',
    gasPrice: 20,
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  },
  mocha: {
    timeout: 120_000_000,
  },
};

export default config;
