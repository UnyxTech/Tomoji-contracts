// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {ERC404} from "./ERC404.sol";
import {ITomojiFactory} from "./interfaces/ITomojiFactory.sol";
import {ITomojiManager} from "./interfaces/ITomojiManager.sol";
import {Strings} from "./libraries/Strings.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Tomoji is ERC404, Ownable {
    error OnlyCallByFactoryOrManager();
    error InvaildParam();
    error ReachMaxPerMint();
    error SoldOut();
    error ExceedPresaleDeadline();
    error PresaleNotFinshed();
    error SendETHFailed();
    error ZeroAddress();

    string private baseTokenURI;
    string public contractURI;
    uint256 private maxPerWallet;
    uint256 private mintPrice;
    uint256 private preSaleDeadLine;
    uint256 private preSaleAmountLeft;

    address public _tomojiManager;

    mapping(address => uint) private mintAccount;
    address public immutable creator;
    address public immutable factory;

    modifier onlyFactoryOrManager() {
        if (msg.sender != factory && msg.sender != _tomojiManager) {
            revert OnlyCallByFactoryOrManager();
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
            mintPrice,
            preSaleDeadLine,
            name,
            symbol,
            baseTokenURI,
            contractURI
        ) = ITomojiFactory(msg.sender)._parameters();
        units = 10 ** decimals;

        _setERC721TransferExempt(creator, true);
        _setERC721TransferExempt(address(this), true);
        _tomojiManager = ITomojiFactory(msg.sender)._tomojiManager();
        (
            address router,
            address v3NonfungiblePositionManagerAddress
        ) = ITomojiManager(_tomojiManager).getSwapRouter();
        _setERC721TransferExempt(router, true);
        _setERC721TransferExempt(v3NonfungiblePositionManagerAddress, true);
        allowance[address(this)][v3NonfungiblePositionManagerAddress] = type(
            uint256
        ).max;
        allowance[address(this)][_tomojiManager] = type(uint256).max;

        if (reserved > 0) {
            _mintERC20(creator, reserved * units);
        }
        _mintERC20(address(this), (nftSupply - reserved) * units);
        preSaleAmountLeft = (nftSupply - reserved) / 2;

        factory = msg.sender;
        _transferOwnership(creator);
    }

    function multiTransfer(
        address[] calldata to_,
        uint256 value
    ) public virtual returns (bool) {
        for (uint256 i = 0; i < to_.length; i++) {
            transfer(to_[i], value);
        }

        return true;
    }

    function mint(uint256 mintAmount_) public payable virtual returns (bool) {
        if (preSaleAmountLeft == 0) {
            revert SoldOut();
        }
        if (block.timestamp > preSaleDeadLine) {
            revert ExceedPresaleDeadline();
        }

        if (mintAmount_ > preSaleAmountLeft) {
            mintAmount_ = preSaleAmountLeft;
        }

        uint256 price = mintPrice * mintAmount_;
        if (mintAmount_ == 0 || msg.value < price) {
            revert InvaildParam();
        }
        if (msg.sender != creator) {
            if (mintAccount[msg.sender] + mintAmount_ > maxPerWallet) {
                revert ReachMaxPerMint();
            }
            mintAccount[msg.sender] += mintAmount_;
        }
        preSaleAmountLeft -= mintAmount_;

        uint256 buyAmount = mintAmount_ * units;
        _transferERC20WithERC721(address(this), msg.sender, buyAmount);

        //refund if pay more
        if (msg.value > price) {
            (bool success, ) = payable(msg.sender).call{
                value: msg.value - price
            }("");
            if (!success) {
                revert SendETHFailed();
            }
        }

        //add liquidity to uniswap pool
        if (preSaleAmountLeft == 0) {
            //add liquidity using eth and left token
            ITomojiManager(_tomojiManager).addLiquidityForTomoji{
                value: address(this).balance
            }(address(this), balanceOf[address(this)]);
        }

        return true;
    }

    function refundIfPresaleFailed(
        uint256 refundErc20Amount
    ) public virtual returns (bool) {
        if (preSaleAmountLeft > 0 && block.timestamp > preSaleDeadLine) {
            uint256 refundNum = refundErc20Amount / units;
            if (refundNum == 0) {
                revert InvaildParam();
            }
            uint256 refundValue = refundNum * mintPrice;
            if (
                _transferERC20WithERC721(
                    msg.sender,
                    address(0),
                    refundNum * units
                )
            ) {
                (bool success, ) = payable(msg.sender).call{value: refundValue}(
                    ""
                );
                if (!success) {
                    revert SendETHFailed();
                }
            }
        } else {
            revert PresaleNotFinshed();
        }
        return true;
    }

    /**************Only Call By Factory Function **********/

    function setTokenURI(
        string calldata _tokenURI
    ) public onlyFactoryOrManager {
        baseTokenURI = _tokenURI;
    }

    function setERC721TransferExempt(
        address[] calldata exemptAddrs,
        bool state
    ) public onlyFactoryOrManager {
        for (uint256 i = 0; i < exemptAddrs.length; ) {
            if (exemptAddrs[i] == address(0)) {
                revert ZeroAddress();
            }
            _setERC721TransferExempt(exemptAddrs[i], state);
        }
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        if (_getOwnerOf(id) == address(0)) {
            revert InvalidTokenId();
        }
        return string.concat(baseTokenURI, Strings.toString(id));
    }
}
