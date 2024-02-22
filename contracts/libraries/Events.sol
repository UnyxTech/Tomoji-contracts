// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library Events {
    event SendTomoEmojiToken(
        address indexed sponsor,
        string name,
        uint256 emojiClaimId,
        uint256 emojiTokenAmount
    );

    event ERC404Created(
        address indexed addr,
        address indexed creator,
        uint256 decimals,
        uint256 totalSupply,
        uint256 nftUnit,
        string name,
        string symbol
    );

    event BRC404Minted(
        address indexed to,
        uint256 indexed amount,
        string ticker,
        string txId
    );

    event BRC404Burned(
        address indexed burner,
        uint256 amount,
        uint256 fee,
        uint256 chainid,
        string ticker,
        string receiver
    );

    event FeeChanged(uint256 oldFee, uint256 newFee);
}
