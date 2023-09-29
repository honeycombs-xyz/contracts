export const deploy = async (ethers: any, deployer: any) => {
  // const Utilities = await ethers.getContractFactory('Utilities')
  // const utils = await Utilities.deploy()
  // await utils.deployed()
  // console.log(`     Deployed Utilities at ${utils.address}`)

  const Colors = await ethers.getContractFactory('Colors', deployer);
  const colors = await Colors.deploy();
  await colors.deployed();
  console.log(`     Deployed Colors at ${colors.address}`);

  const GridArt = await ethers.getContractFactory('GridArt', deployer);
  const gridArt = await GridArt.deploy();
  await gridArt.deployed();
  console.log(`     Deployed GridArt at ${gridArt.address}`);

  const GradientsArt = await ethers.getContractFactory('GradientsArt', {
    libraries: {
      // Utilities: utils.address,
      Colors: colors.address,
    },
    signer: deployer
  });
  const gradientsArt = await GradientsArt.deploy();
  await gradientsArt.deployed();
  console.log(`     Deployed GradientsArt at ${gradientsArt.address}`);

  const HoneycombsArt = await ethers.getContractFactory('HoneycombsArt', {
    libraries: {
      // Utilities: utils.address,
      GridArt: gridArt.address,
      GradientsArt: gradientsArt.address,
    },
    signer: deployer
  });
  const honeycombArt = await HoneycombsArt.deploy();
  await honeycombArt.deployed();
  
  console.log(`     Deployed HoneycombsArt at ${honeycombArt.address}`);

  const HoneycombsMetadata = await ethers.getContractFactory(
    'HoneycombsMetadata',
    {
      libraries: {
        // Utilities: utils.address,
        HoneycombsArt: honeycombArt.address,
      },
      signer: deployer
    });
  const honeycombsMetadata = await HoneycombsMetadata.deploy();
  await honeycombsMetadata.deployed();
  console.log(
    `     Deployed HoneycombsMetadata at ${honeycombsMetadata.address}`,
  );

  const Honeycombs = await ethers.getContractFactory('Honeycombs', {
    libraries: {
      // Utilities: utils.address,
      HoneycombsArt: honeycombArt.address,
      HoneycombsMetadata: honeycombsMetadata.address,
    },
      signer: deployer
  });
  const honeycombs = await Honeycombs.deploy();
  await honeycombs.deployed();
  console.log(`     Deployed Honeycombs at ${honeycombs.address}`);

  return {
    honeycombArt,
    honeycombsMetadata,
    honeycombs,
  };
};
