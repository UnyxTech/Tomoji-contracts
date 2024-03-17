// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import {DataTypes} from "../libraries/DataTypes.sol";

interface ITomojiFactory {
    function _parameters()
        external
        view
        returns (
            address creator,
            uint256 nftTotalSupply,
            uint256 reserved,
            uint256 maxPerWallet,
            uint256 price,
            uint256 preSaleDeadLine,
            string calldata name,
            string calldata symbol,
            string calldata baseURI,
            string calldata contractURI
        );

    function erc404Contract(
        address creator,
        string calldata name
    ) external view returns (address);

    function _tomojiManager() external view returns (address);

    function protocolFeeAddress() external view returns (address);

    function protocolPercentage() external view returns (uint256);
}
