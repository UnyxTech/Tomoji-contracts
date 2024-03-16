// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {ERC404} from "./ERC404.sol";
import {DataTypes} from "./libraries/DataTypes.sol";
import {INonfungiblePositionManager} from "./interfaces/INonfungiblePositionManager.sol";
import {ITomojiFactory} from "./interfaces/ITomojiFactory.sol";
import {LibCaculatePair} from "./libraries/LibCaculatePair.sol";
import {Strings} from "./libraries/Strings.sol";
import {Math} from "./libraries/Math.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Tomoji is ERC404, Ownable {
    error OnlyCallByFactory();
    error InvaildParam();
    error ReachMaxPerMint();
    error SoldOut();
    error ExceedPresaleDeadline();
    error PresaleNotFinshed();
    error SendETHFailed();
    error ZeroAddress();
    error X404SwapV3FactoryMismatch();
    error CreatePairFailed();

    string private baseTokenURI;
    string public contractURI;
    uint256 private maxPerWallet;
    uint256 private mintPrice;
    uint256 private preSaleDeadLine;
    address private v3NonfungiblePositionManagerAddress;
    uint256 private preSaleAmountLeft;
    uint256 private tokenId;

    mapping(address => uint) private mintAccount;
    address public immutable creator;
    address public immutable factory;

    modifier onlyFactory() {
        if (msg.sender != factory) {
            revert OnlyCallByFactory();
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

        DataTypes.SwapRouter memory swapRouterStruct = ITomojiFactory(
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
        if (mintAccount[msg.sender] + mintAmount_ > maxPerWallet) {
            revert ReachMaxPerMint();
        }

        mintAccount[msg.sender] += mintAmount_;
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
            _addLiquidity();
        }

        return true;
    }

    //collect liqiudity reward
    function collect() public returns (uint256 amount0, uint256 amount1) {
        (amount0, amount1) = INonfungiblePositionManager(
            v3NonfungiblePositionManagerAddress
        ).collect(
                INonfungiblePositionManager.CollectParams({
                    tokenId: tokenId,
                    recipient: address(this),
                    amount0Max: type(uint128).max,
                    amount1Max: type(uint128).max
                })
            );
        address feeAddr = ITomojiFactory(factory).protocolFeeAddress();
        uint256 feePercentage = ITomojiFactory(factory).protocolPercentage();
        uint256 tokenReward = balanceOf[address(this)];
        uint256 ethReward = address(this).balance;
        if (tokenReward > 0) {
            uint256 feeProtocol = (tokenReward * feePercentage) / 10000;
            _transferERC20WithERC721(address(this), feeAddr, feeProtocol);
            _transferERC20WithERC721(
                address(this),
                creator,
                tokenReward - feeProtocol
            );
        }
        if (ethReward > 0) {
            uint256 feeProtocol = (ethReward * feePercentage) / 10000;
            (bool success, ) = payable(feeAddr).call{value: feeProtocol}("");
            (bool success1, ) = payable(creator).call{
                value: ethReward - feeProtocol
            }("");
            if (!success || !success1) {
                revert SendETHFailed();
            }
        }
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

    function setTokenURI(string calldata _tokenURI) public onlyFactory {
        baseTokenURI = _tokenURI;
    }

    function setERC721TransferExempt(
        address[] calldata exemptAddrs,
        bool state
    ) public onlyFactory {
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

    /**************Internal Function **********/
    function _setRouterTransferExempt(
        DataTypes.SwapRouter memory swapRouterStruct
    ) internal {
        address thisAddress = address(this);
        address routerAddr = swapRouterStruct.routerAddr;
        if (routerAddr == address(0)) {
            revert ZeroAddress();
        }
        _setERC721TransferExempt(routerAddr, true);

        address weth_ = INonfungiblePositionManager(routerAddr).WETH9();
        address swapFactory = INonfungiblePositionManager(routerAddr).factory();
        address v3NonfungiblePositionManager = swapRouterStruct
            .uniswapV3NonfungiblePositionManager;
        if (v3NonfungiblePositionManager == address(0)) {
            revert ZeroAddress();
        }
        if (
            INonfungiblePositionManager(v3NonfungiblePositionManager)
                .factory() !=
            swapFactory ||
            INonfungiblePositionManager(v3NonfungiblePositionManager).WETH9() !=
            weth_
        ) {
            revert X404SwapV3FactoryMismatch();
        }
        _setERC721TransferExempt(v3NonfungiblePositionManager, true);
        _setV3SwapTransferExempt(swapFactory, thisAddress, weth_);
        _createUniswapV3Pool(v3NonfungiblePositionManager, thisAddress, weth_);
    }

    function _setV3SwapTransferExempt(
        address swapFactory,
        address token0,
        address token1
    ) internal {
        uint24[3] memory feeTiers = [
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

    function _createUniswapV3Pool(
        address v3NonfungiblePositionManager,
        address tokenA,
        address tokenB
    ) internal {
        (address token0, address token1, bool zeroForOne) = tokenA < tokenB
            ? (tokenA, tokenB, true)
            : (tokenB, tokenA, false);

        uint160 sqrtPriceX96;
        if (zeroForOne) {
            sqrtPriceX96 = uint160(Math.sqrt(mintPrice) * (2 ** 96));
        } else {
            sqrtPriceX96 = uint160(Math.sqrt(10 ** 36 / mintPrice) * (2 ** 96));
        }
        v3NonfungiblePositionManagerAddress = v3NonfungiblePositionManager;
        address pool = INonfungiblePositionManager(v3NonfungiblePositionManager)
            .createAndInitializePoolIfNecessary(
                token0,
                token1,
                uint24(10_000),
                sqrtPriceX96
            );
        if (pool == address(0)) {
            revert CreatePairFailed();
        }
        //approve type(uint256).max to v3NonfungiblePositionManagerAddress
        allowance[tokenA][v3NonfungiblePositionManagerAddress] = type(uint256)
            .max;
    }

    function _addLiquidity() internal {
        address thisAddress = address(this);
        address _weth = INonfungiblePositionManager(
            v3NonfungiblePositionManagerAddress
        ).WETH9();
        (address token0, address token1, bool zeroForOne) = thisAddress < _weth
            ? (thisAddress, _weth, true)
            : (_weth, thisAddress, false);

        (uint256 tokenId_, , , ) = INonfungiblePositionManager(
            v3NonfungiblePositionManagerAddress
        ).mint{value: address(this).balance}(
            INonfungiblePositionManager.MintParams({
                token0: token0,
                token1: token1,
                fee: uint24(10_000),
                tickLower: int24(-887272),
                tickUpper: int24(887272),
                amount0Desired: zeroForOne
                    ? balanceOf[thisAddress]
                    : address(this).balance,
                amount1Desired: zeroForOne
                    ? address(this).balance
                    : balanceOf[thisAddress],
                amount0Min: 0,
                amount1Min: 0,
                recipient: address(this),
                deadline: block.timestamp
            })
        );
        tokenId = tokenId_;
        if (balanceOf[thisAddress] > 0) {
            _transferERC20WithERC721(
                thisAddress,
                creator,
                balanceOf[thisAddress]
            );
        }
        INonfungiblePositionManager(v3NonfungiblePositionManagerAddress)
            .refundETH();
        if (address(this).balance > 0) {
            (bool success, ) = payable(creator).call{
                value: address(this).balance
            }("");
            if (!success) {
                revert SendETHFailed();
            }
        }
    }
}
