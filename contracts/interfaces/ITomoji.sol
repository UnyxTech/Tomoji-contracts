// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ITomoji {
    function setERC721TransferExempt(
        address[] calldata exemptAddrs,
        bool state
    ) external;

    function balanceOf(address owner_) external view returns (uint256);

    function owner() external view returns (address);

    function mintPrice() external view returns (uint256);
}
