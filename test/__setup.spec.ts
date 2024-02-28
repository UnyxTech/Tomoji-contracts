
import { expect } from 'chai';
import { Signer, Wallet } from 'ethers';
import { ethers } from 'hardhat';
import {
  TomoERC404,
  TomoERC404Factory__factory,
  TomoERC404Factory,
  Events,
  Events__factory
} from '../typechain-types';
import {
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
export let tomoErc404Factory: TomoERC404Factory;
export let eventsLib: Events;

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

  tomoErc404Factory = await new TomoERC404Factory__factory(deployer).deploy(ownerAddress);

  expect(tomoErc404Factory).to.not.be.undefined;

  await expect(tomoErc404Factory.connect(user).setContractURI(userTwoAddress, "MoMo", "")).to.be.reverted

  eventsLib = await new Events__factory(deployer).deploy();
});
