// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {DataTypes} from "./libraries/DataTypes.sol";
import {Tomoji} from "./Tomoji.sol";
import {Events} from "./libraries/Events.sol";
import {Errors} from "./libraries/Errors.sol";

contract TomojiFactory is ReentrancyGuard, Ownable {
    DataTypes.CreateERC404Parameters public _parameters;
    mapping(address => mapping(string => address)) public _erc404Contract;

    constructor(address owner) Ownable(owner) {}

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

    function erc404Contract(
        address creator,
        string calldata name
    ) external view returns (address) {
        return _erc404Contract[creator][name];
    }
}
