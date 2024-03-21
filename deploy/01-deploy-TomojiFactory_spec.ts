/* Imports: Internal */
import { DeployFunction } from 'hardhat-deploy/dist/types'

import { ethers, upgrades } from 'hardhat';

const deployFn: DeployFunction = async (hre) => {
  
  const { deployer } = await hre.getNamedAccounts()

  const tomojiManagerAddr = "0x119ab99C23D0C9c4B2D30069Bc297b8dfD9Bb370"

  const TomojiFactory = await ethers.getContractFactory("TomojiFactory");
  const proxy = await upgrades.deployProxy(TomojiFactory, [deployer, tomojiManagerAddr]);
  const proxyAddress = await proxy.getAddress()
  await proxy.waitForDeployment()
  
  console.log("proxy address: ", proxyAddress)
  console.log("admin address: ", await upgrades.erc1967.getAdminAddress(proxyAddress))
  console.log("implement address: ", await upgrades.erc1967.getImplementationAddress(proxyAddress))
}

// This is kept during an upgrade. So no upgrade tag.
deployFn.tags = ['DeployTomojiFactory']

export default deployFn
