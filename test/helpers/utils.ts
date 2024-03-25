
import { hexlify, keccak256, Contract, toBeHex, toUtf8Bytes, TransactionReceipt, TransactionResponse } from 'ethers';
import { encode } from '@ethersproject/rlp'
import { expect } from 'chai';
import { HARDHAT_CHAINID } from './constants';
import { splitSignature } from '@ethersproject/bytes'
import hre from 'hardhat';
import { signWallet } from '../__setup.spec';

export function getChainId(): number {
  return hre.network.config.chainId || HARDHAT_CHAINID;
}

export function computeContractAddress(deployerAddress: string, nonce: number): string {
  const hexNonce = hexlify(toBeHex(nonce.toString()));
  return '0x' + keccak256(encode([deployerAddress, hexNonce])).substring(26);
}

export async function waitForTx(
  tx: Promise<TransactionResponse> | TransactionResponse,
  skipCheck = false
): Promise<TransactionReceipt> {
  if (!skipCheck) await expect(tx).to.not.be.reverted;
  return (await (await tx).wait())!;
}

let snapshotId: string = '0x1';
export async function takeSnapshot() {
  snapshotId = await hre.ethers.provider.send('evm_snapshot', []);
}

export async function revertToSnapshot() {
  await hre.ethers.provider.send('evm_revert', [snapshotId]);
}

export async function buildMintSeparator(
  tomo: string,
  name: string,
  tomojiAddress: string,
  userAddress: string,
  amount: number
): Promise<{ v: number; r: string; s: string }> {
  const msgParams = buildMintParams(tomo, name, tomojiAddress, userAddress, amount);
  return await getSig(msgParams);
}

const buildMintParams = (
  tomo: string,
  name: string,
  tomojiAddress: string,
  userAddress: string,
  amount: number
) => ({
  types: {
    Mint: [
      { name: 'tomoji', type: 'address' },
      { name: 'sender', type: 'address' },
      { name: 'amount', type: 'uint256' },
    ],
  },
  domain: {
    name: name,
    version: '1',
    chainId: getChainId(),
    verifyingContract: tomo,
  },
  value: {
    tomoji: tomojiAddress,
    sender: userAddress,
    amount: amount,
  },
});

async function getSig(msgParams: {
  domain: any;
  types: any;
  value: any;
}): Promise<{ v: number; r: string; s: string }> {
  const sig = await signWallet.signTypedData(msgParams.domain, msgParams.types, msgParams.value);
  return splitSignature(sig);
}