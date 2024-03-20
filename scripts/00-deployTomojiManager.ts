import hre from 'hardhat';
import { ethers, upgrades } from 'hardhat';
import { hexlify, keccak256, toBeHex} from 'ethers';
import { encode } from '@ethersproject/rlp'
import { TomojiManager__factory } from '../typechain-types';

async function delay(ms: number) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function main() {

  const accounts = await ethers.getSigners();
  const deployer = accounts[0];

  let deployerNonce = await ethers.provider.getTransactionCount(deployer.address);
  console.log("deployerNonce: ", deployerNonce)
  const proxyTomojiFactoryNonce = hexlify(toBeHex((deployerNonce + 2).toString()));
  const proxyTomojiAddress = '0x' + keccak256(encode([deployer.address, proxyTomojiFactoryNonce])).substring(26);
  console.log("proxyTomojiAddress: ", proxyTomojiAddress)

  const swapRouter = {
    routerAddr: '0x3bFA4769FB09eefC5a80d6E87c3B9C650f7Ae48E',
    uniswapV3NonfungiblePositionManager: '0x1238536071E1c677A632429e3655c799b22cDA52',
  }

  const tomojiManager = await new TomojiManager__factory(deployer).deploy(swapRouter, proxyTomojiAddress);
  const tomojiManagerAddr = await tomojiManager.getAddress()
  console.log("tomojiManager address: ", tomojiManagerAddr)
  await delay(10000);

  const TomojiFactory = await ethers.getContractFactory("TomojiFactory");
  const proxy = await upgrades.deployProxy(TomojiFactory, [deployer.address, tomojiManagerAddr]);
  const proxyAddress = await proxy.getAddress()
  await proxy.waitForDeployment()
  
  console.log("proxy address: ", proxyAddress)
  console.log("admin address: ", await upgrades.erc1967.getAdminAddress(proxyAddress))
  console.log("implement address: ", await upgrades.erc1967.getImplementationAddress(proxyAddress))

  const tomojiManagerContract = TomojiManager__factory.connect(tomojiManagerAddr)
  console.log("before factory: ", await tomojiManagerContract.connect(deployer)._factory())
  const tx = await tomojiManagerContract.connect(deployer).setFactory(proxyAddress);
  tx.wait()
  console.log("after factory: ", await tomojiManagerContract.connect(deployer)._factory())
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });