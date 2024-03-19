/* Imports: Internal */
import { DeployFunction } from 'hardhat-deploy/dist/types'

import { ethers, upgrades } from 'hardhat';

const deployFn: DeployFunction = async (hre) => {
  
  const { deployer } = await hre.getNamedAccounts()

  const tomojiManagerAddr = "0xAFbf4D25b5F4d65eE1D09aE0FB9748296f8C5946"

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
