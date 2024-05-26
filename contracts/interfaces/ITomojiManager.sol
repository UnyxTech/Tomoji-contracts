// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import {DataTypes} from "../libraries/DataTypes.sol";

interface ITomojiManager {
    function getSwapRouter() external view returns (address, address);

    function prePairTomojiEnv(
        address tomojiAddr,
        uint160 sqrtPriceX96,
        uint160 sqrtPriceB96
    ) external returns (address);

    function addLiquidityForTomoji(
        address tomojiAddr,
        uint256 tokenAmount
    ) external payable returns (bool);

    function getCreatTomojiParam()
        external
        view
        returns (bool, uint256, uint256, uint256);
}
