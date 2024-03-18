
import { hexlify, keccak256, Contract, toBeHex, toUtf8Bytes, TransactionReceipt, TransactionResponse } from 'ethers';
import { encode } from '@ethersproject/rlp'
import { expect } from 'chai';
import { HARDHAT_CHAINID } from './constants';
import hre from 'hardhat';

export function getChainId(): number {
  return hre.network.config.chainId || HARDHAT_CHAINID;
}

export function computeContractAddress(deployerAddress: string, nonce: number): string {
  const hexNonce = hexlify(toBeHex(nonce.toString()));
  console.log("hexNonce: ", hexNonce)
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