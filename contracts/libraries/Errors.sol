// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

library Errors {
    error ArrayLengthError();
    error InvaildId();
    error OnlyCallByFactory();
    error NotExist();
    error ZeroAddress();

    error NotFound();
    error ContractAlreadyExist();

    error ReservedTooMuch();
    error InvaildParam();
    error ReachMaxPerMint();

    error EmptyMerkleRoot();
    error AlreadyFinish();
    error NotEnough();
    error SendETHFailed();
    error AlreadyClaimed();
    error MerkleProofVerifyFailed();
    error X404SwapV3FactoryMismatch();
}
