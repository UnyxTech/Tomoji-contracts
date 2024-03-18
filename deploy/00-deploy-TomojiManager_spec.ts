/* Imports: Internal */
import { DeployFunction } from 'hardhat-deploy/dist/types'
import { hexlify, keccak256} from 'ethers';
import { ethers } from 'hardhat';
import { encode } from '@ethersproject/rlp'
import { deployAndVerifyAndThen } from '../scripts/deploy-utils';

const deployFn: DeployFunction = async (hre) => {
  
  const { deployer, owner } = await hre.getNamedAccounts()

  let deployerNonce = await ethers.provider.getTransactionCount(deployer);
  const proxyTomojiFactoryNonce = hexlify((deployerNonce + 2).toString());
  const proxyTomojiAddress = '0x' + keccak256(encode([deployer, proxyTomojiFactoryNonce])).substring(26);
  
  let swapRouter;

  const chainId = hre.network.config.chainId;
  //base mainnet
  if(chainId == 8453){ //base main-net
    //uniswap v3
    swapRouter = {
      routerAddr: '0x2626664c2603336E57B271c5C0b26F421741e481',
      uniswapV3NonfungiblePositionManager: '0x03a520b32C04BF3bEEf7BEb72E919cf822Ed34f1',
    }
  }else if(chainId == 84532){ // base sepolia
    swapRouter = {
      routerAddr: '0x94cC0AaC535CCDB3C01d6787D6413C739ae12bc4',
      uniswapV3NonfungiblePositionManager: '0x27F971cb582BF9E50F397e4d29a5C7A34f11faA2',
    }
  }else if(chainId == 11155111){ //sepolia
    swapRouter = {
      routerAddr: '0x3bFA4769FB09eefC5a80d6E87c3B9C650f7Ae48E',
      uniswapV3NonfungiblePositionManager: '0x1238536071E1c677A632429e3655c799b22cDA52',
    }
  }

  await deployAndVerifyAndThen({
    hre,
    name: "TomojiManager",
    contract: 'TomojiManager',
    args: [swapRouter, proxyTomojiAddress],
  })
}

// This is kept during an upgrade. So no upgrade tag.
deployFn.tags = ['DeployTomojiManager']

export default deployFn
