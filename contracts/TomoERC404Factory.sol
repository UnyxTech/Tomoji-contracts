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
        string memory name,
        string memory symbol,
        string memory baseUri,
        address creator,
        uint256 nftTotalSupply,
        uint256 units
    ) external returns (address erc404) {
        if (_erc404Contract[creator][name] != address(0x0)) {
            revert Errors.ContractAlreadyExist();
        }
        _parameters = DataTypes.CreateERC404Parameters({
            name: name,
            symbol: symbol,
            baseUri: baseUri,
            creator: creator,
            nftTotalSupply: nftTotalSupply,
            units: units
        });
        erc404 = address(
            new TomoERC404{salt: keccak256(abi.encode(name, symbol, creator))}()
        );
        _erc404Contract[creator][name] = erc404;
        delete _parameters;
        emit Events.ERC404Created(
            erc404,
            creator,
            nftTotalSupply,
            units,
            name,
            symbol
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
