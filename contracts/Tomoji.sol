// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {ERC404} from "./ERC404.sol";
import {ITomojiFactory} from "./interfaces/ITomojiFactory.sol";
import {Errors} from "./libraries/Errors.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Tomoji is ERC404, Ownable {
    string public baseTokenURI;
    string public contractURI;
    uint256 public maxPerWallet;
    uint256 public mintPrice;

    mapping(address => uint) mintAccount;
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
        uint256 reserved;
        decimals = 18;
        (
            creator,
            nftSupply,
            reserved,
            maxPerWallet,
            units,
            mintPrice,
            name,
            symbol,
            baseTokenURI,
            contractURI
        ) = ITomojiFactory(msg.sender)._parameters();

        _setERC721TransferExempt(creator, true);
        _setERC721TransferExempt(address(this), true);
        if (reserved > 0) {
            _mintERC20(creator, reserved * units);
        }
        _mintERC20(
            address(this),
            (nftSupply - reserved) * units * 10 ** decimals
        );

        factory = msg.sender;
        _transferOwnership(creator);
    }

    function multiTransferFrom(
        address from_,
        address[] calldata to_,
        uint256 valueOrId_
    ) public virtual returns (bool) {
        for (uint256 i = 0; i < to_.length; i++) {
            transferFrom(from_, to_[i], valueOrId_);
        }

        return true;
    }

    function multiTransfer(
        address[] calldata to_,
        uint256 valueOrId_
    ) public virtual returns (bool) {
        for (uint256 i = 0; i < to_.length; i++) {
            transfer(to_[i], valueOrId_);
        }

        return true;
    }

    function mint(uint256 mintAmount_) public payable virtual returns (bool) {
        if (mintAmount_ == 0 || msg.value < mintPrice * mintAmount_) {
            revert Errors.InvaildParam();
        }
        if (mintAccount[msg.sender] + mintAmount_ >= maxPerWallet) {
            revert Errors.ReachMaxPerMint();
        }
        uint256 buyAmount = mintAmount_ * units;
        if (buyAmount > balanceOf[address(this)]) {
            revert Errors.NotEnough();
        }
        _transferERC20WithERC721(address(this), msg.sender, buyAmount);
        return true;
    }

    function stopLaunchpad() public virtual onlyOwner returns (bool) {
        if (balanceOf[address(this)] == 0) {
            revert Errors.AlreadyFinish();
        }
        if (balanceOf[address(this)] > 0) {
            _transferERC20WithERC721(
                address(this),
                creator,
                balanceOf[address(this)]
            );
        }
        balanceOf[address(this)] = 0;
        return true;
    }

    /**************Only Call By Factory Function **********/

    function setContractURI(
        string calldata newContractUri
    ) public onlyFactory returns (bool) {
        contractURI = newContractUri;
        return true;
    }

    function setTokenURI(string calldata _tokenURI) public onlyFactory {
        baseTokenURI = _tokenURI;
    }

    function setERC721TransferExempt(
        address[] calldata exemptAddrs,
        bool state
    ) public onlyFactory {
        for (uint256 i = 0; i < exemptAddrs.length; ) {
            if (exemptAddrs[i] == address(0)) {
                revert Errors.ZeroAddress();
            }
            _setERC721TransferExempt(exemptAddrs[i], state);
        }
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        return string.concat(baseTokenURI, Strings.toString(id));
    }
}
