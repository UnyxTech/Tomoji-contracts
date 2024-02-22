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

    error EmptyMerkleRoot();
    error AlreadyFinish();
    error NotEnough();
    error AlreadyClaimed();
    error MerkleProofVerifyFailed();
}
