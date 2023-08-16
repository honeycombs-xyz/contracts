import fs from 'fs';
import { Contract } from 'ethers';

export const fetchAndRender = async (
  contract: Contract,
  id: number,
  prepend: string = '',
) => {
  const svg = await contract.svg(id);
  fs.writeFileSync(`test/dist/${prepend}${id}.svg`, svg);
  return svg;
};
