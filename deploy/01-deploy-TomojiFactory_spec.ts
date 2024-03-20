/* Imports: Internal */
import { DeployFunction } from 'hardhat-deploy/dist/types'

import { ethers, upgrades } from 'hardhat';

const deployFn: DeployFunction = async (hre) => {
  
  const { deployer } = await hre.getNamedAccounts()

  const tomojiManagerAddr = "0x3AA27B782f8868fD02DBba58107318322a45e1Bd"

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
