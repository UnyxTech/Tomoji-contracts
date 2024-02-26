// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {ERC404} from "./ERC404.sol";
import {ITomoERC404Factory} from "./interfaces/ITomoERC404Factory.sol";
import {Errors} from "./libraries/Errors.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract TomoERC404 is ERC404, Ownable {
    string public baseTokenURI;
    string public contractURI;
    address public immutable creator;
    address public immutable factory;

    modifier onlyFactory() {
        if (msg.sender != factory) {
            revert Errors.OnlyCallByFactory();
        }
        _;
    }

    constructor() Ownable(msg.sender) {
        uint256 nftSupply;
        decimals = 18;
        (
            name,
            symbol,
            baseTokenURI,
            creator,
            nftSupply,
            units
        ) = ITomoERC404Factory(msg.sender)._parameters();

        totalSupply = nftSupply * units;
        balanceOf[creator] = totalSupply;

        factory = msg.sender;
        _transferOwnership(creator);
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

    function setContractURI(
        string calldata newContractUri
    ) public onlyFactory returns (bool) {
        contractURI = newContractUri;
        return true;
    }

    function setTokenURI(string memory _tokenURI) public onlyFactory {
        baseTokenURI = _tokenURI;
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        return string.concat(baseTokenURI, Strings.toString(id));
    }
}
