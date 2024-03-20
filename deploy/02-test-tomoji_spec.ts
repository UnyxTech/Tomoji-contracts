/* Imports: Internal */
import { DeployFunction } from 'hardhat-deploy/dist/types'

import { ethers, upgrades } from 'hardhat';
import { TomojiFactory__factory, Tomoji__factory } from '../typechain-types';

const deployFn: DeployFunction = async (hre) => {
  
  //const { deployer } = await hre.getNamedAccounts()
  const accounts = await ethers.getSigners();
  const deployer = accounts[0];
  const owner = accounts[1];


  // const tomorrow = parseInt((new Date().getTime() / 1000 ).toFixed(0)) + 24 * 3600
  // const proxyAddr = "0x60DB51600A32a162428cF5ba53690F756E1ba98E"

  // const tomojiFactory = TomojiFactory__factory.connect(proxyAddr)
  // console.log("start create tomoji...")
  // const tx = await tomojiFactory.connect(deployer).createERC404({
  //   creator: deployer.address, 
  //   nftTotalSupply: 10,
  //   reserved: 0,
  //   maxPerWallet: 3,
  //   price: 10000,
  //   preSaleDeadLine: tomorrow,
  //   name: "MoMonkey", 
  //   symbol: "MoMk", 
  //   baseURI: "ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/", 
  //   contractURI: "https://tomo-contract"
  // })
  // tx.wait();
  // console.log("create tomoji successful")

  const tomojiAddr = "0xDbAbdEB9FDE3F65fB2E3A96B75f3939f5dcaA378"
  const tomojiContract = Tomoji__factory.connect(tomojiAddr)
  const tx = await tomojiContract.connect(deployer).mint(2, {value: 20000});
  tx.wait();
  console.log("mint successful")
}

// This is kept during an upgrade. So no upgrade tag.
deployFn.tags = ['TestTomoji']

export default deployFn