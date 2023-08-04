const hre = require('hardhat')

async function main() {
  const [deployer] = await ethers.getSigners()
  console.log('\nDeploying with the account:', await deployer.getAddress())

  const { name: network } = hre.network
  console.log(`\nRunning on network [${network}]`)

  const MemeXToken = await ethers.getContractFactory('MemeXToken')
  const memeXToken = await MemeXToken.deploy('0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266', 100000000, 1000000000)

  console.log('\nMemeXToken deployed to: ', memeXToken.address)

  const RoyaltyFeeVault = await ethers.getContractFactory('RoyaltyFeeVault')
  const royaltyFeeVault = await RoyaltyFeeVault.deploy()

  console.log('\nRoyaltyFeeVault deployed to: ', royaltyFeeVault.address)

  const MemeXNFT = await ethers.getContractFactory('MemeXNFT')
  const memeXNFT = await MemeXNFT.deploy(royaltyFeeVault.address, 500, 5000)

  console.log('\nMemeXNFT deployed to: ', memeXNFT.address)

  console.log('\nFinished!')
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })