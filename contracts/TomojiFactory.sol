// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {PriceCalculator} from "./libraries/PriceCalculator.sol";
import {DataTypes} from "./libraries/DataTypes.sol";
import {Tomoji} from "./Tomoji.sol";
import {ITomoji} from "./interfaces/ITomoji.sol";
import {ITomojiManager} from "./interfaces/ITomojiManager.sol";

contract TomojiFactory is OwnableUpgradeable {
    error InvaildParam();
    error ReservedTooMuch();
    error PrepairTomojiEnvFailed();
    error PreSaleDeadLineTooFar();
    error ContractAlreadyExist();
    error ContractNotExist();
    error ZeroAddress();
    error NftSupplyExceedMaxSupply();
    error CantCreateTomoji();
    error MaxPerWalletTooMuch();
    error MsgValueNotEnough();
    error SendETHFailed();

    event TomojiCreated(
        address indexed addr,
        address indexed creator,
        uint256 totalSupply,
        uint256 reserved,
        uint256 maxPerWallet,
        uint256 price,
        uint256 preSaleDeadLine,
        string name,
        string symbol,
        string baseURI,
        string contractURI
    );

    mapping(address => mapping(string => address)) public _erc404Contract;
    DataTypes.CreateTomojiParameters private _parameters;
    address public _tomojiManager;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address owner,
        address tomojiManager
    ) public initializer {
        if (owner == address(0) || tomojiManager == address(0)) {
            revert ZeroAddress();
        }
        __Ownable_init(owner);

        _tomojiManager = tomojiManager;
    }

    function createTomoji(
        DataTypes.CreateTomojiParameters calldata vars
    ) external payable returns (address erc404) {
        _checkParam(vars);

        _parameters = vars;
        uint256 price;
        if (vars.reserved > 0) {
            price = vars.reserved * vars.price;
            if (msg.value < price) {
                revert MsgValueNotEnough();
            }
        }
        if (msg.value > price) {
            (bool success, ) = payable(msg.sender).call{
                value: msg.value - price
            }("");
            if (!success) {
                revert SendETHFailed();
            }
        }
        erc404 = address(
            new Tomoji{
                salt: keccak256(
                    abi.encode(vars.name, vars.symbol, vars.creator)
                ),
                value: price
            }()
        );
        _erc404Contract[vars.creator][vars.name] = erc404;
        ITomojiManager(_tomojiManager).prePairTomojiEnv(
            erc404,
            vars.sqrtPriceX96,
            vars.sqrtPriceB96
        );
        delete _parameters;

        _emitCreateTomojiEvent(erc404, vars);
    }

    function setTokenURI(
        address creator,
        string calldata name,
        string calldata _tokenURI
    ) public onlyOwner returns (bool) {
        if (_erc404Contract[creator][name] == address(0x0)) {
            revert ZeroAddress();
        }
        Tomoji(_erc404Contract[creator][name]).setTokenURI(_tokenURI);
        return true;
    }

    function setERC721TransferExempt(
        address creator,
        string calldata name,
        address[] calldata exemptAddrs,
        bool state
    ) public onlyOwner returns (bool) {
        if (_erc404Contract[creator][name] == address(0x0)) {
            revert ZeroAddress();
        }
        Tomoji(_erc404Contract[creator][name]).setERC721TransferExempt(
            exemptAddrs,
            state
        );
        return true;
    }

    function setTomojiManager(address newAddr) public onlyOwner {
        if (newAddr == address(0)) {
            revert ZeroAddress();
        }
        _tomojiManager = newAddr;
    }

    function parameters()
        external
        view
        returns (DataTypes.CreateTomojiParameters memory)
    {
        return _parameters;
    }

    function _checkParam(
        DataTypes.CreateTomojiParameters calldata vars
    ) internal view {
        (
            bool _canCreateTomoji,
            uint256 _maxNftSupply,
            uint256 _maxPurchasePercentageForCreator,
            uint256 _maxPreSaleTime
        ) = ITomojiManager(_tomojiManager).getCreatTomojiParam();

        if (!_canCreateTomoji) {
            revert CantCreateTomoji();
        }
        if (msg.sender != vars.creator) {
            revert InvaildParam();
        }
        if (vars.nftTotalSupply > _maxNftSupply) {
            revert NftSupplyExceedMaxSupply();
        }
        if (
            vars.reserved >
            (vars.nftTotalSupply * _maxPurchasePercentageForCreator) / 10000
        ) {
            revert ReservedTooMuch();
        }
        if (vars.maxPerWallet > (vars.nftTotalSupply * 200) / 10000) {
            revert MaxPerWalletTooMuch();
        }
        if (vars.preSaleDeadLine > block.timestamp + _maxPreSaleTime) {
            revert PreSaleDeadLineTooFar();
        }
        if (_erc404Contract[vars.creator][vars.name] != address(0x0)) {
            revert ContractAlreadyExist();
        }

        uint256 mintPrice = PriceCalculator.getPrice(vars.sqrtPriceX96);
        uint256 x = vars.price > mintPrice
            ? vars.price - mintPrice
            : mintPrice - vars.price;
        if (x > 5) {
            revert InvaildParam();
        }

        uint256 mintPriceEth = PriceCalculator.getPrice(vars.sqrtPriceB96);
        uint256 priceEth = 10 ** 36 / vars.price;
        uint256 y = priceEth > mintPriceEth
            ? priceEth - mintPriceEth
            : mintPriceEth - priceEth;
        if (y > 5) {
            revert InvaildParam();
        }
    }

    function _emitCreateTomojiEvent(
        address erc404,
        DataTypes.CreateTomojiParameters calldata vars
    ) internal {
        emit TomojiCreated(
            erc404,
            vars.creator,
            vars.nftTotalSupply,
            vars.reserved,
            vars.maxPerWallet,
            vars.price,
            vars.preSaleDeadLine,
            vars.name,
            vars.symbol,
            vars.baseURI,
            vars.contractURI
        );
    }
}
