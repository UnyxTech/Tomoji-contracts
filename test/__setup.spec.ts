
import { expect } from 'chai';
import { Signer, Wallet } from 'ethers';
import { ethers, upgrades } from 'hardhat';
import {
  Tomoji,
  TomojiFactory__factory,
  TomojiFactory,
  TomojiManager__factory,
  TomojiManager
} from '../typechain-types';
import {
  computeContractAddress,
  revertToSnapshot,
  takeSnapshot
} from './helpers/utils';

export let accounts: Signer[];
export let deployer: Signer;
export let owner: Signer;
export let user: Signer;
export let userTwo: Signer;
export let deployerAddress: string;
export let ownerAddress: string;
export let userAddress: string;
export let userTwoAddress: string;
export let tomojiFactory: TomojiFactory;
export let tomojiManager: TomojiManager;

export let signWallet: Wallet;

export const BRC404Factory_NAME = 'Tomo-ticker';
export const ticker: string = 'Tomo';
export const symbol: string = "Tomo";
export const decimals = 18;

export function makeSuiteCleanRoom(name: string, tests: () => void) {
  describe(name, () => {
    beforeEach(async function () {
      await takeSnapshot();
    });
    tests();
    afterEach(async function () {
      await revertToSnapshot();
    });
  });
}

before(async function () {
  accounts = await ethers.getSigners();
  deployer = accounts[0];
  owner = accounts[3];
  user = accounts[1];
  userTwo = accounts[2];

  deployerAddress = await deployer.getAddress();
  userAddress = await user.getAddress();
  userTwoAddress = await userTwo.getAddress();
  ownerAddress = await owner.getAddress();

  const nonce = await deployer.getNonce();
  const TomojiFactoryProxyAddress = computeContractAddress(deployerAddress, nonce + 2);

  const swapRouter = 
  //uniswap v3
  {
    routerAddr: '0x2626664c2603336E57B271c5C0b26F421741e481',
    uniswapV3NonfungiblePositionManager: '0x03a520b32C04BF3bEEf7BEb72E919cf822Ed34f1',
  }
  tomojiManager = await new TomojiManager__factory(deployer).deploy(swapRouter, TomojiFactoryProxyAddress);

  const TomojiFactory = await ethers.getContractFactory("TomojiFactory");
  const proxy = await upgrades.deployProxy(TomojiFactory, [ownerAddress, await tomojiManager.getAddress()]);
  const proxyAddress = await proxy.getAddress()
  console.log("proxy address: ", proxyAddress)
  console.log("admin address: ", await upgrades.erc1967.getAdminAddress(proxyAddress))
  console.log("implement address: ", await upgrades.erc1967.getImplementationAddress(proxyAddress))

  tomojiFactory = TomojiFactory__factory.connect(proxyAddress)

  await expect(tomojiFactory.connect(user).setTokenURI(userTwoAddress, "MoMo", "")).to.be.reverted
});
