// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import {DataTypes} from "../libraries/DataTypes.sol";

interface ITomojiFactory {
    function parameters()
        external
        view
        returns (DataTypes.CreateTomojiParameters memory);

    function _erc404Contract(
        address creator,
        string calldata name
    ) external view returns (address);

    function _tomojiManager() external view returns (address);

    function _protocolFeeAddress() external view returns (address);

    function _protocolPercentage() external view returns (uint256);

    function _daoContractAddr() external view returns (address);
}
