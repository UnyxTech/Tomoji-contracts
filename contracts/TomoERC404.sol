// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {ERC404} from "./ERC404.sol";
import {ITomoERC404Factory} from "./interfaces/ITomoERC404Factory.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Errors} from "./libraries/Errors.sol";

contract TomoERC404 is ERC404 {
    string public baseTokenURI;
    address public immutable creator;
    address public immutable factory;

    modifier onlyFactory() {
        if (msg.sender != factory) {
            revert Errors.OnlyCallByFactory();
        }
        _;
    }

    constructor() {
        uint256 nftSupply;
        (
            name,
            symbol,
            baseTokenURI,
            creator,
            decimals,
            nftSupply,
            units
        ) = ITomoERC404Factory(msg.sender)._parameters();

        totalSupply = nftSupply * units;
        balanceOf[creator] = totalSupply;

        factory = msg.sender;
    }

    function multiTransferFrom(
        address from_,
        address[] memory to_,
        uint256 valueOrId_
    ) public virtual returns (bool) {
        for (uint256 i = 0; i < to_.length; i++) {
            transferFrom(from_, to_[i], valueOrId_);
        }

        return true;
    }

    function multiTransfer(
        address[] memory to_,
        uint256 valueOrId_
    ) public virtual returns (bool) {
        for (uint256 i = 0; i < to_.length; i++) {
            transfer(to_[i], valueOrId_);
        }

        return true;
    }

    /**************Only Call By Factory Function **********/

    function setTokenURI(string memory _tokenURI) public onlyFactory {
        baseTokenURI = _tokenURI;
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        return string.concat(baseTokenURI, Strings.toString(id));
    }

    function setWhitelist(address target_, bool state_) external onlyFactory {
        _setERC721TransferExempt(target_, state_);
    }
}
