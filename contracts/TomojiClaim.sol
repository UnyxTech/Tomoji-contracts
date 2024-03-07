// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {TransferHelper} from "./libraries/TransferHelper.sol";
import {IERC404} from "./interfaces/IERC404.sol";
import {ITomojiFactory} from "./interfaces/ITomojiFactory.sol";
import {Events} from "./libraries/Events.sol";
import {Errors} from "./libraries/Errors.sol";

contract TomojiClaim is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    struct TomojiTokenClaimStruct {
        address sponsor;
        address erc404Addr;
        uint256 total;
        uint256 claimed;
        uint256 left;
        bytes32 merkleRoot;
        EnumerableSet.AddressSet claimedUser;
    }
    uint256 public _nextTomojiClaimId;
    address public _tomojiFactory;
    mapping(uint256 => TomojiTokenClaimStruct) internal _tomojiTokenClaim;

    constructor(address factory, address owner) Ownable(owner) {
        _tomojiFactory = factory;
    }

    function sendTomojiToken(
        string calldata name,
        uint256 emojiTokenAmount,
        bytes32 merkleRoot
    ) external {
        if (emojiTokenAmount == 0 || merkleRoot == bytes32(0)) {
            revert Errors.InvaildParam();
        }
        address erc404Addr = ITomojiFactory(_tomojiFactory).erc404Contract(
            msg.sender,
            name
        );
        if (erc404Addr == address(0x0)) {
            revert Errors.NotExist();
        }
        bool isExempt = IERC404(erc404Addr).erc721TransferExempt(address(this));
        if (!isExempt) {
            IERC404(erc404Addr).setSelfERC721TransferExempt(true);
        }

        uint256 emojiClaimId = _nextTomojiClaimId++;
        TomojiTokenClaimStruct storage re = _tomojiTokenClaim[emojiClaimId];
        re.sponsor = msg.sender;
        re.erc404Addr = erc404Addr;
        re.total = emojiTokenAmount;
        re.left = emojiTokenAmount;
        re.merkleRoot = merkleRoot;

        TransferHelper.erc20TransferFrom(
            erc404Addr,
            msg.sender,
            address(this),
            emojiTokenAmount
        );

        emit Events.SendTomojiToken(
            msg.sender,
            name,
            emojiClaimId,
            emojiTokenAmount
        );
    }

    function updateFactoryAddr(address factory) external onlyOwner {
        if (factory == address(0x0)) {
            revert Errors.ZeroAddress();
        }
        _tomojiFactory = factory;
    }

    function setMerkleRootForTomojiToken(
        uint256[] calldata emojiClaimIds,
        bytes32[] calldata merkleRoots
    ) public onlyOwner {
        if (
            emojiClaimIds.length != merkleRoots.length ||
            emojiClaimIds.length == 0
        ) {
            revert Errors.ArrayLengthError();
        }
        for (uint256 i = 0; i < emojiClaimIds.length; i++) {
            uint256 id = emojiClaimIds[i];
            if (id >= _nextTomojiClaimId) {
                revert Errors.InvaildId();
            }
            _tomojiTokenClaim[id].merkleRoot = merkleRoots[i];
        }
    }

    function claimTomojiToken(
        uint256 emojiClaimId,
        uint256 claimAmount,
        bytes32[] calldata merkleProof
    ) external {
        if (_tomojiTokenClaim[emojiClaimId].merkleRoot == bytes32(0)) {
            revert Errors.EmptyMerkleRoot();
        }
        if (_tomojiTokenClaim[emojiClaimId].left == 0) {
            revert Errors.AlreadyFinish();
        }
        if (_tomojiTokenClaim[emojiClaimId].left < claimAmount) {
            revert Errors.NotEnough();
        }
        if (_tomojiTokenClaim[emojiClaimId].claimedUser.contains(msg.sender)) {
            revert Errors.AlreadyClaimed();
        }
        bytes32 leafNode = keccak256(
            abi.encodePacked(emojiClaimId, msg.sender, claimAmount)
        );
        if (
            !MerkleProof.verify(
                merkleProof,
                _tomojiTokenClaim[emojiClaimId].merkleRoot,
                leafNode
            )
        ) {
            revert Errors.MerkleProofVerifyFailed();
        }
        _tomojiTokenClaim[emojiClaimId].claimedUser.add(msg.sender);
        _tomojiTokenClaim[emojiClaimId].claimed += claimAmount;
        _tomojiTokenClaim[emojiClaimId].left -= claimAmount;

        TransferHelper.erc20Transfer(
            _tomojiTokenClaim[emojiClaimId].erc404Addr,
            msg.sender,
            claimAmount
        );
    }
}
