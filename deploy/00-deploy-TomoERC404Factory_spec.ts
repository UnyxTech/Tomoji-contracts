/* Imports: Internal */
import { DeployFunction } from 'hardhat-deploy/dist/types'
import {
  deployAndVerifyAndThen
} from '../scripts/deploy-utils';

const deployFn: DeployFunction = async (hre) => {
  
  const { deployer, owner } = await hre.getNamedAccounts()
  await deployAndVerifyAndThen({
      hre,
      name: "TomojiFactory",
      contract: 'TomojiFactory',
      args: [deployer],
  })
}

// This is kept during an upgrade. So no upgrade tag.
deployFn.tags = ['TomojiFactory']

export default deployFn
