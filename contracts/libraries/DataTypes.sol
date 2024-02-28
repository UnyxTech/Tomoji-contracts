// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

/**
 * @title DataTypes
 * @author Tomo Protocol
 *
 * @notice A standard library of data types used throughout the XRGB.
 */
library DataTypes {
    struct CreateERC404Parameters {
        address creator;
        uint256 nftTotalSupply;
        uint256 reserved;
        uint256 maxPerWallet;
        uint256 units;
        uint256 price;
        string name;
        string symbol;
        string baseURI;
        string contractURI;
    }
}
