import hre from 'hardhat';
import { ethers, upgrades } from 'hardhat';
import { hexlify, keccak256, toBeHex} from 'ethers';
import { encode } from '@ethersproject/rlp'
import { TomojiFactory__factory, TomojiManager__factory, Tomoji__factory } from '../typechain-types';

async function delay(ms: number) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function main() {

  const [deployer] = await hre.ethers.getSigners();

  const tomorrow = parseInt((new Date().getTime() / 1000 ).toFixed(0)) + 24 * 3600
  const proxyAddr = "0x1b8de2c4c79b765Fabb2fd7A41fE176d02CE6869"
  // const tomojiFactory = TomojiFactory__factory.connect(proxyAddr)
  // const tomojiManagerAddr = await tomojiFactory.connect(deployer)._erc404Contract(deployer.address, "MoMonkey");
  // console.log("tomoji addr: ", tomojiManagerAddr)

  const manager = "0x975842E175Ed429391eF22CA5559Bd954AA9046b"
  const tomojiManager = TomojiManager__factory.connect(manager)
  const factory = await tomojiManager.connect(deployer)._factory();
  console.log("proxyAddress: ", factory)

  const tomojiFactory = TomojiFactory__factory.connect(proxyAddr)
  const tomojiManagerAddr = await tomojiFactory.connect(deployer)._tomojiManager();
  console.log("tomojiManagerAddr: ", tomojiManagerAddr)
  const tx = await tomojiFactory.connect(deployer).createERC404({
    creator: deployer.address, 
    nftTotalSupply: 10,
    reserved: 0,
    maxPerWallet: 3,
    price: 10000,
    preSaleDeadLine: tomorrow,
    sqrtPriceX96: 11,
    sqrtPriceB96: 11,
    name: "MoMonkey", 
    symbol: "MoMk", 
    baseURI: "ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/", 
    contractURI: "https://tomo-contract"
  })
  tx.wait();
  console.log("create tomoji successful")
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });