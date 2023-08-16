export const deploy = async (ethers: any) => {
  // const Utilities = await ethers.getContractFactory('Utilities')
  // const utils = await Utilities.deploy()
  // await utils.deployed()
  // console.log(`     Deployed Utilities at ${utils.address}`)

  const Colors = await ethers.getContractFactory('Colors');
  const colors = await Colors.deploy();
  await colors.deployed();
  console.log(`     Deployed Colors at ${colors.address}`);

  const HoneycombsArt = await ethers.getContractFactory('HoneycombsArt', {
    libraries: {
      // Utilities: utils.address,
      Colors: colors.address,
    },
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
    },
  );
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
