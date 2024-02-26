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
        string name;
        string symbol;
        string baseUri;
        address creator;
        uint256 nftTotalSupply;
        uint256 units;
    }
}
