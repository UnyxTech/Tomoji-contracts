// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import {DataTypes} from "../libraries/DataTypes.sol";

interface ITomojiManager {
    function getSwapRouter() external view returns (address, address);

    function prePairTomojiEnv(
        address tomojiAddr,
        uint256 price
    ) external returns (bool);

    function addLiquidityForTomoji(
        address tomojiAddr,
        uint256 tokenAmount
    ) external payable returns (bool);
}
