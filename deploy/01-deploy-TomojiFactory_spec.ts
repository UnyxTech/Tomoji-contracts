/* Imports: Internal */
import { DeployFunction } from 'hardhat-deploy/dist/types'

import { ZeroAddress } from 'ethers';
import { ethers, upgrades } from 'hardhat';
import { getContractFromArtifact } from '../scripts/deploy-utils';

const deployFn: DeployFunction = async (hre) => {
  
  const { deployer } = await hre.getNamedAccounts()

  const TomojiManager = await getContractFromArtifact(
    hre,
    "TomojiManager"
  )
  const tomojiManagerAddr = await TomojiManager.getAddress()

  const TomojiFactory = await ethers.getContractFactory("TomojiFactory");
  const proxy = await upgrades.deployProxy(TomojiFactory, [deployer, tomojiManagerAddr]);
  const proxyAddress = await proxy.getAddress()
  await proxy.waitForDeployment()
  
  console.log("proxy address: ", proxyAddress)
  console.log("admin address: ", await upgrades.erc1967.getAdminAddress(proxyAddress))
  console.log("implement address: ", await upgrades.erc1967.getImplementationAddress(proxyAddress))
}

// This is kept during an upgrade. So no upgrade tag.
deployFn.tags = ['TomojiFactory']

export default deployFn
