import hre from 'hardhat';
import { ethers, upgrades } from 'hardhat';
import { hexlify, keccak256, toBeHex} from 'ethers';
import { encode } from '@ethersproject/rlp'
import { TomojiFactory__factory, TomojiManager__factory, Tomoji__factory } from '../typechain-types';
import { encodePriceSqrt } from './deploy-utils';

async function delay(ms: number) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function main() {

  const accounts = await ethers.getSigners();
  const deployer = accounts[0];

  const mintPrice = ethers.parseEther("0.0001");
  const sqrtPriceX96 = encodePriceSqrt(ethers.parseEther("0.0001"), ethers.parseEther("1"));
  const sqrtPriceB96 = encodePriceSqrt(ethers.parseEther("1"), ethers.parseEther("0.0001"));
  const tomorrow = parseInt((new Date().getTime() / 1000 ).toFixed(0)) + 24 * 3600
  const proxyAddr = "0xe48b71f78d5589b0ba737dc4f4bbb77bba88d5a0"

  const manager = "0x36b25BDE76f496BDc4d44A118B2ce022a018C643"
  const tomojiManager = TomojiManager__factory.connect(manager)
  const factory = await tomojiManager.connect(deployer)._factory();
  console.log("proxyAddress: ", factory)

  const tomojiFactory = TomojiFactory__factory.connect(proxyAddr)
  const tomojiManagerAddr = await tomojiFactory.connect(deployer)._tomojiManager();
  console.log("tomojiManagerAddr: ", tomojiManagerAddr)

  const tx = await tomojiFactory.connect(deployer).createTomoji({
    creator: deployer.address, 
    nftTotalSupply: 10,
    reserved: 0,
    maxPerWallet: 3,
    price: mintPrice,
    preSaleDeadLine: tomorrow,
    sqrtPriceX96: sqrtPriceX96.toBigInt(),
    sqrtPriceB96: sqrtPriceB96.toBigInt(),
    bSupportEOAMint: true,
    name: "MoMonkey", 
    symbol: "MoMk", 
    baseURI: "ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/", 
    contractURI: "https://tomo-contract"
  })
  await tx.wait();
  console.log("create tomoji successful")

  await delay(5000);
  const tomojiAddr = await tomojiFactory.connect(deployer)._erc404Contract(deployer.address, "MoMonkey");
  console.log("tomoji addr: ", tomojiAddr)
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });