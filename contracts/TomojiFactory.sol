// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
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

    event ERC404Created(
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
    DataTypes.CreateERC404Parameters public _parameters;
    address public _tomojiManager;
    uint256 public _maxReservePercentage; //defaule 1000 as 10%
    uint256 public _maxPreSaleTime; //defaule 7 days
    address public _protocolFeeAddress;
    uint256 public _protocolPercentage;
    address public _daoContractAddr;
    bool public _bSupportReserved;

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
        _maxReservePercentage = 1000;
        _maxPreSaleTime = 7 * 24 * 60 * 60;
        _protocolFeeAddress = owner;
        _bSupportReserved = false;
        _daoContractAddr = owner;
    }

    function createERC404(
        DataTypes.CreateERC404Parameters calldata vars
    ) external returns (address erc404) {
        {
            if (msg.sender != vars.creator) {
                revert InvaildParam();
            }
            if (
                _bSupportReserved &&
                vars.reserved >
                (vars.nftTotalSupply * _maxReservePercentage) / 10000
            ) {
                revert ReservedTooMuch();
            }
            if (vars.preSaleDeadLine > block.timestamp + _maxPreSaleTime) {
                revert PreSaleDeadLineTooFar();
            }
            if (_erc404Contract[vars.creator][vars.name] != address(0x0)) {
                revert ContractAlreadyExist();
            }

            _parameters = vars;
            if (!_bSupportReserved) {
                _parameters.reserved = 0;
            }
            erc404 = address(
                new Tomoji{
                    salt: keccak256(
                        abi.encode(vars.name, vars.symbol, vars.creator)
                    )
                }()
            );
            _erc404Contract[vars.creator][vars.name] = erc404;
            delete _parameters;
        }
        emit ERC404Created(
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

    function createUniswapV3PairForTomoji(
        address creator,
        string calldata name
    ) public returns (bool) {
        address erc404 = _erc404Contract[creator][name];
        if (erc404 == address(0x0)) {
            revert ContractNotExist();
        }
        uint256 price = ITomoji(erc404).mintPrice();

        bool ret = ITomojiManager(_tomojiManager).prePairTomojiEnv(
            erc404,
            price
        );
        if (!ret) {
            revert PrepairTomojiEnvFailed();
        }
        return true;
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

    function setMaxReservePercentage(
        uint256 newReservePercentage
    ) public onlyOwner {
        if (newReservePercentage > 5000) {
            revert ReservedTooMuch();
        }
        _maxReservePercentage = newReservePercentage;
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

    function setSupportReserved(bool bSupportReserved) public onlyOwner {
        _bSupportReserved = bSupportReserved;
    }

    function setDaoContractAddr(address newAddr) public onlyOwner {
        if (newAddr == address(0)) {
            revert ZeroAddress();
        }
        _daoContractAddr = newAddr;
    }

    function setTomojiManager(address newAddr) public onlyOwner {
        if (newAddr == address(0)) {
            revert ZeroAddress();
        }
        _tomojiManager = newAddr;
    }
}
