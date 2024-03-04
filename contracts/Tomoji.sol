// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {ERC404} from "./ERC404.sol";
import {DataTypes} from "./libraries/DataTypes.sol";
import {IPeripheryImmutableState} from "./interfaces/IPeripheryImmutableState.sol";
import {IUniswapV2Router} from "./interfaces/IUniswapV2Router.sol";
import {ITomojiFactory} from "./interfaces/ITomojiFactory.sol";
import {Errors} from "./libraries/Errors.sol";
import {LibCaculatePair} from "./libraries/LibCaculatePair.sol";
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
        uint256 nftUnit;
        (
            creator,
            nftSupply,
            reserved,
            maxPerWallet,
            nftUnit,
            mintPrice,
            name,
            symbol,
            baseTokenURI,
            contractURI
        ) = ITomojiFactory(msg.sender)._parameters();
        units = nftUnit * 10 ** decimals;

        DataTypes.SwapRouter[] memory swapRouterStruct = ITomojiFactory(
            msg.sender
        ).getSwapRouter();

        //add swap pair router address into whitelist
        _setRouterTransferExempt(swapRouterStruct);
        _setERC721TransferExempt(creator, true);
        _setERC721TransferExempt(address(this), true);
        if (reserved > 0) {
            _mintERC20(creator, reserved * units);
        }
        _mintERC20(address(this), (nftSupply - reserved) * units);

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
        uint256 price = mintPrice * mintAmount_;
        if (mintAmount_ == 0 || msg.value < price) {
            revert Errors.InvaildParam();
        }
        if (mintAccount[msg.sender] + mintAmount_ >= maxPerWallet) {
            revert Errors.ReachMaxPerMint();
        }
        uint256 buyAmount = mintAmount_ * units;
        if (buyAmount > balanceOf[address(this)]) {
            revert Errors.NotEnough();
        }

        if (msg.value > price) {
            (bool success, ) = msg.sender.call{value: msg.value - price}("");
            if (!success) {
                revert Errors.SendETHFailed();
            }
        }
        (bool success1, ) = creator.call{value: price}("");
        if (!success1) {
            revert Errors.SendETHFailed();
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

    /**************Internal Function **********/
    function _setRouterTransferExempt(
        DataTypes.SwapRouter[] memory swapRouterStruct
    ) internal {
        address thisAddress = address(this);
        for (uint i = 0; i < swapRouterStruct.length; ) {
            address routerAddr = swapRouterStruct[i].routerAddr;
            if (routerAddr == address(0)) {
                revert Errors.ZeroAddress();
            }
            _setERC721TransferExempt(routerAddr, true);

            if (swapRouterStruct[i].bV2orV3) {
                address weth_ = IUniswapV2Router(routerAddr).WETH();
                address swapFactory = IUniswapV2Router(routerAddr).factory();
                address pair = LibCaculatePair._getUniswapV2Pair(
                    swapFactory,
                    thisAddress,
                    weth_
                );
                _setERC721TransferExempt(pair, true);
            } else {
                address weth_ = IPeripheryImmutableState(routerAddr).WETH9();
                address swapFactory = IPeripheryImmutableState(routerAddr)
                    .factory();
                address v3NonfungiblePositionManager = swapRouterStruct[i]
                    .uniswapV3NonfungiblePositionManager;
                if (v3NonfungiblePositionManager == address(0)) {
                    revert Errors.ZeroAddress();
                }
                if (
                    IPeripheryImmutableState(v3NonfungiblePositionManager)
                        .factory() !=
                    swapFactory ||
                    IPeripheryImmutableState(v3NonfungiblePositionManager)
                        .WETH9() !=
                    weth_
                ) {
                    revert Errors.X404SwapV3FactoryMismatch();
                }
                _setERC721TransferExempt(v3NonfungiblePositionManager, true);
                _setV3SwapTransferExempt(swapFactory, thisAddress, weth_);
            }
            unchecked {
                ++i;
            }
        }
    }

    function _setV3SwapTransferExempt(
        address swapFactory,
        address token0,
        address token1
    ) internal {
        uint24[4] memory feeTiers = [
            uint24(100),
            uint24(500),
            uint24(3_000),
            uint24(10_000)
        ];

        for (uint256 i = 0; i < feeTiers.length; ) {
            address v3PairAddr = LibCaculatePair._getUniswapV3Pair(
                swapFactory,
                token0,
                token1,
                feeTiers[i]
            );
            // Set the v3 pair as exempt.
            _setERC721TransferExempt(v3PairAddr, true);
            unchecked {
                ++i;
            }
        }
    }
}
