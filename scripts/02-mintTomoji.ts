import hre from 'hardhat';
import { ethers, upgrades } from 'hardhat';
import { hexlify, keccak256, toBeHex} from 'ethers';
import { encode } from '@ethersproject/rlp'
import { TomojiFactory__factory, TomojiManager__factory, Tomoji__factory } from '../typechain-types';
import { buildMintSeparator, encodePriceSqrt } from './deploy-utils';

async function delay(ms: number) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function main() {

  const accounts = await ethers.getSigners();
  const deployer = accounts[0];
  const owner = accounts[1];

  const tomojiManagerAddr = "0x36b25BDE76f496BDc4d44A118B2ce022a018C643"

  const tomojiAddr = "0x7F1C1e7ecf8aE06482991d9e797e596B68f1aaEC"
  const tomojiContract = Tomoji__factory.connect(tomojiAddr)

  const TOMOJI_NAME = 'Tomoji'
  const sig = await buildMintSeparator(tomojiAddr, TOMOJI_NAME, deployer.address, owner.address, 1);

  const mintTx = await tomojiContract.connect(owner).mint(1, sig.v, sig.r, sig.s, {value: ethers.parseEther("0.0001")});
  await mintTx.wait()
  await delay(2000)

  const balance = await tomojiContract.connect(deployer).balanceOf(tomojiManagerAddr);
  console.log("balance: ", balance)
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });