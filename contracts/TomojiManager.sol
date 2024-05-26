// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {DataTypes} from "./libraries/DataTypes.sol";
import {INonfungiblePositionManager} from "./interfaces/INonfungiblePositionManager.sol";
import {Math} from "./libraries/Math.sol";
import {ITomojiManager} from "./interfaces/ITomojiManager.sol";
import {ITomoji} from "./interfaces/ITomoji.sol";
import {IWETH9} from "./interfaces/IWETH9.sol";
import {ITomojiFactory} from "./interfaces/ITomojiFactory.sol";
import {TransferHelper} from "./libraries/TransferHelper.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract TomojiManager is ITomojiManager, Ownable {
    error OnlyCallByFactory();
    error SendETHFailed();
    error ZeroAddress();
    error X404SwapV3FactoryMismatch();
    error CreatePairFailed();
    error JustCanBeCallByDaoAddress();
    error OnlyCallByOwner();
    error OnlyCallByTomoji();
    error ReservedTooMuch();
    error InvaildParam();

    event RemoveLiquidityForEmergece(
        uint256 tokenId,
        uint256 liquidity,
        uint256 amount0,
        uint256 amount1
    );

    event CollectLiquidityReward(
        address tomojiAddr,
        uint256 tokenId,
        uint256 amount0,
        uint256 amount1
    );

    event AddLiquidityAfterSoldOut(
        address tomojiAddr,
        uint256 tokenId,
        uint128 liquidity,
        uint256 amount0,
        uint256 amount1
    );

    bool public _canCreateTomoji;
    uint256 public _maxPurchasePercentageForCreator; //defaule 1000 as 10%
    uint256 public _maxPreSaleTime; //defaule 7 days
    uint256 public _maxNftSupply; //defaule 100_000
    uint256 public _protocolPercentage; //default 10% of liquidity reward
    address public _protocolFeeAddress;

    DataTypes.SwapRouter private _swapRouter;
    address public _factory;

    modifier onlyFactory() {
        if (msg.sender != _factory) {
            revert OnlyCallByFactory();
        }
        _;
    }

    receive() external payable {}

    constructor(
        DataTypes.SwapRouter memory swapRouter,
        address factory
    ) Ownable(msg.sender) {
        address routerAddr = swapRouter.routerAddr;
        address v3NonfungiblePositionManager = swapRouter
            .uniswapV3NonfungiblePositionManager;
        if (
            routerAddr == address(0) ||
            v3NonfungiblePositionManager == address(0)
        ) {
            revert ZeroAddress();
        }
        address weth_ = INonfungiblePositionManager(routerAddr).WETH9();
        address swapFactory = INonfungiblePositionManager(routerAddr).factory();
        if (
            INonfungiblePositionManager(v3NonfungiblePositionManager)
                .factory() !=
            swapFactory ||
            INonfungiblePositionManager(v3NonfungiblePositionManager).WETH9() !=
            weth_
        ) {
            revert X404SwapV3FactoryMismatch();
        }

        _swapRouter = swapRouter;
        _factory = factory;

        _maxPreSaleTime = 7 * 24 * 60 * 60;
        _maxPurchasePercentageForCreator = 1000;
        _maxNftSupply = 100000;
        _protocolPercentage = 5000;
        _protocolFeeAddress = msg.sender;
        _canCreateTomoji = true;
    }

    function prePairTomojiEnv(
        address tomojiAddr,
        uint160 sqrtPriceX96,
        uint160 sqrtPriceB96
    ) public override onlyFactory returns (address) {
        address v3NonfungiblePositionManager = _swapRouter
            .uniswapV3NonfungiblePositionManager;
        address weth_ = INonfungiblePositionManager(
            v3NonfungiblePositionManager
        ).WETH9();
        address pool = _createUniswapV3Pool(
            v3NonfungiblePositionManager,
            tomojiAddr,
            weth_,
            sqrtPriceX96,
            sqrtPriceB96
        );
        return pool;
    }

    function addLiquidityForTomoji(
        address tomojiAddr,
        uint256 tokenAmount
    ) public payable override returns (bool) {
        if (msg.sender != tomojiAddr) {
            revert OnlyCallByTomoji();
        }

        address v3NonfungiblePositionManagerAddress = _swapRouter
            .uniswapV3NonfungiblePositionManager;

        _mintLiquidity(
            tomojiAddr,
            v3NonfungiblePositionManagerAddress,
            tokenAmount
        );
        uint256 leftToken = ITomoji(tomojiAddr).balanceOf(address(this));
        address creator = ITomoji(tomojiAddr).owner();
        if (leftToken > 0) {
            TransferHelper.erc20Transfer(tomojiAddr, creator, leftToken);
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
        return true;
    }

    //collect liqiudity reward
    function collect(
        address tomojiAddr,
        uint256 tokenId
    ) public returns (uint256 amount0, uint256 amount1) {
        address v3NonfungiblePositionManagerAddress = _swapRouter
            .uniswapV3NonfungiblePositionManager;
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

        uint256 tokenReward = ITomoji(tomojiAddr).balanceOf(address(this));
        address _weth = INonfungiblePositionManager(
            v3NonfungiblePositionManagerAddress
        ).WETH9();
        uint256 ethReward = IWETH9(_weth).balanceOf(address(this));

        address creator = ITomoji(tomojiAddr).owner();
        if (tokenReward > 0) {
            uint256 feeProtocol = (tokenReward * _protocolPercentage) / 10000;
            TransferHelper.erc20Transfer(
                tomojiAddr,
                _protocolFeeAddress,
                feeProtocol
            );
            TransferHelper.erc20Transfer(
                tomojiAddr,
                creator,
                tokenReward - feeProtocol
            );
        }
        if (ethReward > 0) {
            IWETH9(_weth).withdraw(ethReward);
            uint256 feeProtocol = (ethReward * _protocolPercentage) / 10000;
            (bool success, ) = payable(_protocolFeeAddress).call{
                value: feeProtocol
            }("");
            (bool success1, ) = payable(creator).call{
                value: ethReward - feeProtocol
            }("");
            if (!success || !success1) {
                revert SendETHFailed();
            }
        }
        emit CollectLiquidityReward(tomojiAddr, tokenId, amount0, amount1);
    }

    function setMaxReservePercentage(
        uint256 newPurchasePercentage
    ) public onlyOwner {
        if (newPurchasePercentage > 5000) {
            revert ReservedTooMuch();
        }
        _maxPurchasePercentageForCreator = newPurchasePercentage;
    }

    function setMaxPreSaleTime(uint256 newMaxPreSaleTime) public onlyOwner {
        _maxPreSaleTime = newMaxPreSaleTime;
    }

    function setProtocolFeeAddress(address newAddress) public onlyOwner {
        if (newAddress == address(0)) {
            revert ZeroAddress();
        }
        _protocolFeeAddress = newAddress;
    }

    function setProtocolFeePercentage(uint256 newPercentage) public onlyOwner {
        if (newPercentage > 10000) {
            revert InvaildParam();
        }
        _protocolPercentage = newPercentage;
    }

    function setCreateTomoji(bool canCreate) public onlyOwner {
        if (_canCreateTomoji == canCreate) {
            revert InvaildParam();
        }
        _canCreateTomoji = canCreate;
    }

    function setFactory(address factory) public onlyOwner {
        if (factory == address(0)) {
            revert ZeroAddress();
        }
        _factory = factory;
    }

    function getCreatTomojiParam()
        public
        view
        returns (bool, uint256, uint256, uint256)
    {
        return (
            _canCreateTomoji,
            _maxNftSupply,
            _maxPurchasePercentageForCreator,
            _maxPreSaleTime
        );
    }

    function getSwapRouter() public view returns (address, address) {
        return (
            _swapRouter.routerAddr,
            _swapRouter.uniswapV3NonfungiblePositionManager
        );
    }

    function _createUniswapV3Pool(
        address v3NonfungiblePositionManager,
        address tokenA,
        address tokenB,
        uint160 sqrtPriceX96,
        uint160 sqrtPriceB96
    ) internal returns (address) {
        (address token0, address token1, bool zeroForOne) = tokenA < tokenB
            ? (tokenA, tokenB, true)
            : (tokenB, tokenA, false);

        address pool = INonfungiblePositionManager(v3NonfungiblePositionManager)
            .createAndInitializePoolIfNecessary(
                token0,
                token1,
                uint24(10_000),
                zeroForOne ? sqrtPriceX96 : sqrtPriceB96
            );
        if (pool == address(0)) {
            revert CreatePairFailed();
        }
        return pool;
    }

    function _mintLiquidity(
        address tomojiAddr,
        address v3NonfungiblePositionManagerAddress,
        uint256 tokenAmount
    ) internal {
        address _weth = INonfungiblePositionManager(
            v3NonfungiblePositionManagerAddress
        ).WETH9();

        (address token0, address token1, bool zeroForOne) = tomojiAddr < _weth
            ? (tomojiAddr, _weth, true)
            : (_weth, tomojiAddr, false);
        uint256 ethValue = address(this).balance;
        {
            (
                uint256 tokenId,
                uint128 liquidity,
                uint256 amount0,
                uint256 amount1
            ) = INonfungiblePositionManager(v3NonfungiblePositionManagerAddress)
                    .mint{value: ethValue}(
                    INonfungiblePositionManager.MintParams({
                        token0: token0,
                        token1: token1,
                        fee: uint24(10_000),
                        tickLower: int24(-887200),
                        tickUpper: int24(887200),
                        amount0Desired: zeroForOne ? tokenAmount : ethValue,
                        amount1Desired: zeroForOne ? ethValue : tokenAmount,
                        amount0Min: 0,
                        amount1Min: 0,
                        recipient: address(this),
                        deadline: block.timestamp
                    })
                );

            emit AddLiquidityAfterSoldOut(
                tomojiAddr,
                tokenId,
                liquidity,
                amount0,
                amount1
            );
        }
    }
}
