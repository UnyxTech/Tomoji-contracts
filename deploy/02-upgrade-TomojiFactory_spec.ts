/* Imports: Internal */
import { DeployFunction } from 'hardhat-deploy/dist/types'

import { ethers, upgrades } from 'hardhat';

const deployFn: DeployFunction = async (hre) => {
  
  const { deployer } = await hre.getNamedAccounts()

  const TomojiV2Factory = await ethers.getContractFactory("TomojiFactory");
  
  const proxyAddr = "0x0721a604DA43090a302ED79F7b9aC2721D503FB6"
  const proxy = await upgrades.upgradeProxy(proxyAddr, TomojiV2Factory);
  await proxy.waitForDeployment()
  
  const proxyAddress = await proxy.getAddress()
  console.log("proxy address: ", proxyAddress)
  console.log("admin address: ", await upgrades.erc1967.getAdminAddress(proxyAddress))
  console.log("implement address: ", await upgrades.erc1967.getImplementationAddress(proxyAddress))
}

// This is kept during an upgrade. So no upgrade tag.
deployFn.tags = ['UpgradeTomojiFactory']

export default deployFn
