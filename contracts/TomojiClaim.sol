// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {TransferHelper} from "./libraries/TransferHelper.sol";
import {IERC404} from "./interfaces/IERC404.sol";
import {ITomojiFactory} from "./interfaces/ITomojiFactory.sol";

contract TomojiClaim is Ownable {
    error ArrayLengthError();
    error InvaildId();
    error NotExist();
    error InvaildParam();
    error MerkleProofVerifyFailed();
    error EmptyMerkleRoot();
    error AlreadyFinish();
    error NotEnough();
    error AlreadyClaimed();
    error ZeroAddress();

    event SendTomojiToken(
        address indexed sponsor,
        string name,
        uint256 emojiClaimId,
        uint256 emojiTokenAmount
    );

    struct TomojiTokenClaimStruct {
        address sponsor;
        address erc404Addr;
        uint256 total;
        uint256 claimed;
        uint256 left;
        bytes32 merkleRoot;
        mapping(address => bool) claimedUser;
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
            revert InvaildParam();
        }
        address erc404Addr = ITomojiFactory(_tomojiFactory)._erc404Contract(
            msg.sender,
            name
        );
        if (erc404Addr == address(0x0)) {
            revert NotExist();
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

        emit SendTomojiToken(msg.sender, name, emojiClaimId, emojiTokenAmount);
    }

    function updateFactoryAddr(address factory) external onlyOwner {
        if (factory == address(0x0)) {
            revert ZeroAddress();
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
            revert ArrayLengthError();
        }
        for (uint256 i = 0; i < emojiClaimIds.length; i++) {
            uint256 id = emojiClaimIds[i];
            if (id >= _nextTomojiClaimId) {
                revert InvaildId();
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
            revert EmptyMerkleRoot();
        }
        if (_tomojiTokenClaim[emojiClaimId].left == 0) {
            revert AlreadyFinish();
        }
        if (_tomojiTokenClaim[emojiClaimId].left < claimAmount) {
            revert NotEnough();
        }
        if (_tomojiTokenClaim[emojiClaimId].claimedUser[msg.sender]) {
            revert AlreadyClaimed();
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
            revert MerkleProofVerifyFailed();
        }
        _tomojiTokenClaim[emojiClaimId].claimedUser[msg.sender] = true;
        _tomojiTokenClaim[emojiClaimId].claimed += claimAmount;
        _tomojiTokenClaim[emojiClaimId].left -= claimAmount;

        TransferHelper.erc20Transfer(
            _tomojiTokenClaim[emojiClaimId].erc404Addr,
            msg.sender,
            claimAmount
        );
    }
}
