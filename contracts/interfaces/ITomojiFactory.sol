// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ITomojiFactory {
    function _parameters()
        external
        view
        returns (
            address creator,
            uint256 nftTotalSupply,
            uint256 reserved,
            uint256 maxPerWallet,
            uint256 nftUnit,
            uint256 price,
            string calldata name,
            string calldata symbol,
            string calldata baseURI,
            string calldata contractURI
        );

    function erc404Contract(
        address creator,
        string calldata name
    ) external view returns (address);
}
