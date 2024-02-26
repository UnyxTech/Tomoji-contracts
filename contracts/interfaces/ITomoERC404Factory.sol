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
            uint256 nftTotalSupply,
            uint256 nftUnit
        );

    function erc404Contract(
        address creator,
        string calldata name
    ) external view returns (address);
}
