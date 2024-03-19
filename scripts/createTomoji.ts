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

  // const tomoji = "0xfcf715696dadf8a101972e0e7d780c1d4f07e701"
  // const tomojiContract = Tomoji__factory.connect(tomoji)
  // const managerAddr = await tomojiContract.connect(deployer)._tomojiManager();

  const tomorrow = parseInt((new Date().getTime() / 1000 ).toFixed(0)) + 24 * 3600
  const proxyAddr = "0xE9D13b327463f0c185e1B824289f4Ee81CE5207f"

  const manager = "0x4759dF150377Ec4a4B6f3BD6a77Ec474931AF27b"
  const tomojiManager = TomojiManager__factory.connect(manager)
  const factory = await tomojiManager.connect(deployer)._factory();
  console.log("factory: ", factory)

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