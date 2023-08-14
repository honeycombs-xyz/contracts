import fs from 'fs'
import { Contract } from 'ethers'

export const fetchAndRender = async (
  id: number,
  contract: Contract,
  prepend: string = '',
) => {
  const honeycomb = await contract.getHoneycomb(id)

  fs.writeFileSync(
    `test/dist/${prepend}${id}.svg`,
    await contract.svg(id)
  )
}