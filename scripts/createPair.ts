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
  const proxyAddr = "0x89f1a1C6f019f70dc14F5E72C0c43f4Ce5193C51"

  const tomojiFactory = TomojiFactory__factory.connect(proxyAddr)
  const tx = await tomojiFactory.connect(deployer).createUniswapV3PairForTomoji(deployer.address, "MoMonkey")
  tx.wait();
  console.log("create pair successful")
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });