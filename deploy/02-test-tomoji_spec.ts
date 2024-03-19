/* Imports: Internal */
import { DeployFunction } from 'hardhat-deploy/dist/types'

import { ethers, upgrades } from 'hardhat';
import { TomojiFactory__factory } from '../typechain-types';

const deployFn: DeployFunction = async (hre) => {
  
  //const { deployer } = await hre.getNamedAccounts()
  const accounts = await ethers.getSigners();
  const deployer = accounts[0];


  const tomorrow = parseInt((new Date().getTime() / 1000 ).toFixed(0)) + 24 * 3600
  const proxyAddr = "0xfc3FD94173A736207189913AbB06Da5ED23C138d"

  const tomojiFactory = TomojiFactory__factory.connect(proxyAddr)
  const tx = await tomojiFactory.connect(deployer).createERC404({
    creator: deployer.address, 
    nftTotalSupply: 10,
    reserved: 0,
    maxPerWallet: 3,
    price: 10000,
    preSaleDeadLine: tomorrow,
    name: "MoMonkey", 
    symbol: "MoMk", 
    baseURI: "ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/", 
    contractURI: "https://tomo-contract"
  })
  tx.wait();
  console.log("create tomoji successful")
}

// This is kept during an upgrade. So no upgrade tag.
deployFn.tags = ['TestTomoji']

export default deployFn