// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {DataTypes} from "./libraries/DataTypes.sol";
import {Tomoji} from "./Tomoji.sol";
import {Events} from "./libraries/Events.sol";
import {Errors} from "./libraries/Errors.sol";

contract TomojiFactory is OwnableUpgradeable {
    DataTypes.CreateERC404Parameters public _parameters;
    DataTypes.SwapRouter[] public _swapRouterAddr;
    mapping(address => mapping(string => address)) public _erc404Contract;

    function initialize(
        address owner,
        DataTypes.SwapRouter[] memory swapRouterAddr
    ) public initializer {
        __Ownable_init(owner);
        for (uint256 i = 0; i < swapRouterAddr.length; ) {
            _swapRouterAddr.push(swapRouterAddr[i]);
            unchecked {
                i++;
            }
        }
    }

    function createERC404(
        DataTypes.CreateERC404Parameters calldata vars
    ) external returns (address erc404) {
        if (vars.reserved >= vars.nftTotalSupply) {
            revert Errors.ReservedTooMuch();
        }
        if (_erc404Contract[vars.creator][vars.name] != address(0x0)) {
            revert Errors.ContractAlreadyExist();
        }
        _parameters = vars;
        erc404 = address(
            new Tomoji{
                salt: keccak256(
                    abi.encode(vars.name, vars.symbol, vars.creator)
                )
            }()
        );
        _erc404Contract[vars.creator][vars.name] = erc404;
        delete _parameters;
        emit Events.ERC404Created(
            erc404,
            vars.creator,
            vars.nftTotalSupply,
            vars.reserved,
            vars.maxPerWallet,
            vars.units,
            vars.price,
            vars.name,
            vars.symbol,
            vars.baseURI,
            vars.contractURI
        );
    }

    function setContractURI(
        address creator,
        string calldata name,
        string calldata newContractUri
    ) public onlyOwner returns (bool) {
        if (_erc404Contract[creator][name] == address(0x0)) {
            revert Errors.ZeroAddress();
        }
        Tomoji(_erc404Contract[creator][name]).setContractURI(newContractUri);
        return true;
    }

    function setTokenURI(
        address creator,
        string calldata name,
        string calldata _tokenURI
    ) public onlyOwner returns (bool) {
        if (_erc404Contract[creator][name] == address(0x0)) {
            revert Errors.ZeroAddress();
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
            revert Errors.ZeroAddress();
        }
        Tomoji(_erc404Contract[creator][name]).setERC721TransferExempt(
            exemptAddrs,
            state
        );
        return true;
    }

    function setSwapRouter(
        DataTypes.SwapRouter[] memory swapRouterAddr
    ) public onlyOwner {
        delete _swapRouterAddr;
        for (uint256 i = 0; i < swapRouterAddr.length; ) {
            _swapRouterAddr.push(swapRouterAddr[i]);
            unchecked {
                i++;
            }
        }
    }

    function getSwapRouter()
        public
        view
        returns (DataTypes.SwapRouter[] memory)
    {
        return _swapRouterAddr;
    }
}
