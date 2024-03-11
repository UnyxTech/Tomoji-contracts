/* Imports: Internal */
import { DeployFunction } from 'hardhat-deploy/dist/types'

import { ZeroAddress } from 'ethers';
import { ethers, upgrades } from 'hardhat';

const deployFn: DeployFunction = async (hre) => {
  
  const { deployer, owner } = await hre.getNamedAccounts()
  const swapRouterArray = [
    //uniswap v2
    {
      swapType: 0,
      routerAddr: '0xD6e0Bc285be97C75861910f4d2cFD4AC61DD629d',
      uniswapV3NonfungiblePositionManager: ZeroAddress,
    },
    //uniswap v3
    {
      swapType: 1,
      routerAddr: '0x2626664c2603336E57B271c5C0b26F421741e481',
      uniswapV3NonfungiblePositionManager: '0x03a520b32C04BF3bEEf7BEb72E919cf822Ed34f1',
    },
    //satori
    {
      swapType: 2,
      routerAddr: '0xf4038D237C553Bf246f7d1A377830601D72f2AB8',
      uniswapV3NonfungiblePositionManager: ZeroAddress,
    },
  ];
  const TomojiFactory = await ethers.getContractFactory("TomojiFactory");
  const proxy = await upgrades.deployProxy(TomojiFactory, [deployer, swapRouterArray]);
  const proxyAddress = await proxy.getAddress()
  await proxy.waitForDeployment()
  
  console.log("proxy address: ", proxyAddress)
  console.log("admin address: ", await upgrades.erc1967.getAdminAddress(proxyAddress))
  console.log("implement address: ", await upgrades.erc1967.getImplementationAddress(proxyAddress))
}

// This is kept during an upgrade. So no upgrade tag.
deployFn.tags = ['TomojiFactory']

export default deployFn
