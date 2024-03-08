// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library Events {
    event SendTomojiToken(
        address indexed sponsor,
        string name,
        uint256 emojiClaimId,
        uint256 emojiTokenAmount
    );

    event ERC404Created(
        address indexed addr,
        address indexed creator,
        uint256 totalSupply,
        uint256 reserved,
        uint256 maxPerWallet,
        uint256 price,
        string name,
        string symbol,
        string baseURI,
        string contractURI
    );
}
