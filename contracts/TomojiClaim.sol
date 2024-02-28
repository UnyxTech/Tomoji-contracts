// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {TransferHelper} from "./libraries/TransferHelper.sol";
import {IERC404} from "./interfaces/IERC404.sol";
import {ITomoERC404Factory} from "./interfaces/ITomoERC404Factory.sol";
import {Events} from "./libraries/Events.sol";
import {Errors} from "./libraries/Errors.sol";

contract TomojiClaim is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    struct TomoEmojiTokenClaimStruct {
        address sponsor;
        address erc404Addr;
        uint256 total;
        uint256 claimed;
        uint256 left;
        bytes32 merkleRoot;
        EnumerableSet.AddressSet claimedUser;
    }
    uint256 public _nextEmojiClaimId;
    address public _tomoERC404Factory;
    mapping(uint256 => TomoEmojiTokenClaimStruct) internal _tomoEmojiTokenClaim;

    constructor(address factory, address owner) Ownable(owner) {
        _tomoERC404Factory = factory;
    }

    function sendTomoEmojiToken(
        string calldata name,
        uint256 emojiTokenAmount
    ) external {
        address erc404Addr = ITomoERC404Factory(_tomoERC404Factory)
            .erc404Contract(msg.sender, name);
        if (erc404Addr == address(0x0)) {
            revert Errors.NotExist();
        }
        bool isExempt = IERC404(erc404Addr).erc721TransferExempt(address(this));
        if (!isExempt) {
            IERC404(erc404Addr).setSelfERC721TransferExempt(true);
        }

        uint256 emojiClaimId = _nextEmojiClaimId++;
        TomoEmojiTokenClaimStruct storage re = _tomoEmojiTokenClaim[
            emojiClaimId
        ];
        re.sponsor = msg.sender;
        re.erc404Addr = erc404Addr;
        re.total = emojiTokenAmount;
        re.left = emojiTokenAmount;

        TransferHelper.safeTransferFrom(
            erc404Addr,
            msg.sender,
            address(this),
            emojiTokenAmount
        );

        emit Events.SendTomoEmojiToken(
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
        _tomoERC404Factory = factory;
    }

    function setMerkleRootForTomoEmojiToken(
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
            if (id >= _nextEmojiClaimId) {
                revert Errors.InvaildId();
            }
            _tomoEmojiTokenClaim[id].merkleRoot = merkleRoots[i];
        }
    }

    function claimTomoEmojiToken(
        uint256 emojiClaimId,
        uint256 claimAmount,
        bytes32[] calldata merkleProof
    ) external {
        if (_tomoEmojiTokenClaim[emojiClaimId].merkleRoot == bytes32(0)) {
            revert Errors.EmptyMerkleRoot();
        }
        if (_tomoEmojiTokenClaim[emojiClaimId].left == 0) {
            revert Errors.AlreadyFinish();
        }
        if (_tomoEmojiTokenClaim[emojiClaimId].left < claimAmount) {
            revert Errors.NotEnough();
        }
        if (
            _tomoEmojiTokenClaim[emojiClaimId].claimedUser.contains(msg.sender)
        ) {
            revert Errors.AlreadyClaimed();
        }
        bytes32 leafNode = keccak256(
            abi.encodePacked(emojiClaimId, msg.sender, claimAmount)
        );
        if (
            !MerkleProof.verify(
                merkleProof,
                _tomoEmojiTokenClaim[emojiClaimId].merkleRoot,
                leafNode
            )
        ) {
            revert Errors.MerkleProofVerifyFailed();
        }
        _tomoEmojiTokenClaim[emojiClaimId].claimedUser.add(msg.sender);
        _tomoEmojiTokenClaim[emojiClaimId].claimed += claimAmount;
        _tomoEmojiTokenClaim[emojiClaimId].left -= claimAmount;

        TransferHelper.safeTransfer(
            _tomoEmojiTokenClaim[emojiClaimId].erc404Addr,
            msg.sender,
            claimAmount
        );

        if (_tomoEmojiTokenClaim[emojiClaimId].left == 0) {
            for (
                uint i = 0;
                i < _tomoEmojiTokenClaim[emojiClaimId].claimedUser.length();
                i++
            ) {
                address claimUser = _tomoEmojiTokenClaim[emojiClaimId]
                    .claimedUser
                    .at(i);
                _tomoEmojiTokenClaim[emojiClaimId].claimedUser.remove(
                    claimUser
                );
            }
            delete _tomoEmojiTokenClaim[emojiClaimId];
        }
    }
}
