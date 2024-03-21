//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Interface for WETH9
interface IWETH9 {
    /// @notice Withdraw wrapped ether to get ether
    function withdraw(uint256) external;

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);
}
