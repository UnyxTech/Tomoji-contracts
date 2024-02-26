// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {DataTypes} from "./libraries/DataTypes.sol";
import {TomoERC404} from "./TomoERC404.sol";
import {Events} from "./libraries/Events.sol";
import {Errors} from "./libraries/Errors.sol";

contract TomoERC404Factory is ReentrancyGuard, Ownable {
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
            new TomoERC404{
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
            vars.symbol
        );
    }

    function setTokenURI(
        string calldata name,
        string calldata _tokenURI
    ) public {
        if (_erc404Contract[msg.sender][name] == address(0x0)) {
            revert Errors.ZeroAddress();
        }
        TomoERC404(_erc404Contract[msg.sender][name]).setTokenURI(_tokenURI);
    }

    function erc404Contract(
        address creator,
        string calldata name
    ) external view returns (address) {
        return _erc404Contract[creator][name];
    }
}
