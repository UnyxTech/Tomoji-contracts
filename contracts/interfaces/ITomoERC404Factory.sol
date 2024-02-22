// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ITomoERC404Factory {
    function _parameters()
        external
        view
        returns (
            string memory name,
            string memory symbol,
            string memory baseUri,
            address creator,
            uint8 decimals,
            uint256 maxSupply,
            uint256 nftUnit
        );
}
