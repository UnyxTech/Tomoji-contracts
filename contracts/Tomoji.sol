// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {ERC404} from "./ERC404.sol";
import {ITomojiFactory} from "./interfaces/ITomojiFactory.sol";
import {ITomojiManager} from "./interfaces/ITomojiManager.sol";
import {INonfungiblePositionManager} from "./interfaces/INonfungiblePositionManager.sol";
import {Strings} from "./libraries/Strings.sol";
import {DataTypes} from "./libraries/DataTypes.sol";
import {LibCaculatePair} from "./libraries/LibCaculatePair.sol";

contract Tomoji is ERC404 {
    error OnlyCallByFactoryOrManager();
    error InvaildParam();
    error ReachMaxPerMint();
    error SoldOut();
    error ExceedPresaleDeadline();
    error PresaleNotFinshed();
    error SendETHFailed();
    error ZeroAddress();
    error X404SwapV3FactoryMismatch();
    error TradingNotEnable();
    error SignatureInvalid();

    bytes32 private constant DOMAIN_NAME = keccak256("Tomoji");
    bytes32 public constant DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
    bytes32 public constant MINT_TYPEHASH =
        keccak256(
            abi.encodePacked(
                "Mint(address tomoji,address sender,uint256 amount)"
            )
        );

    address private _tomojiManager;
    uint256 private mintPrice;
    string public contractURI;
    uint256 private maxPerWallet;
    uint256 private preSaleDeadLine;
    uint256 public preSaleAmountLeft;
    address private creator;
    string private baseTokenURI;
    bool private enableTrading;
    bool private bSupportEOAMint;
    bytes32 private DOMAIN_SEPARATOR;

    mapping(address => uint) private mintAccount;
    address private immutable factory;

    modifier onlyFactoryOrManager() {
        if (msg.sender != factory && msg.sender != _tomojiManager) {
            revert OnlyCallByFactoryOrManager();
        }
        _;
    }

    function initialized(
        DataTypes.CreateTomojiParameters memory vars
    ) internal {
        creator = vars.creator;
        mintPrice = vars.price;
        contractURI = vars.contractURI;
        baseTokenURI = vars.baseURI;
        maxPerWallet = vars.maxPerWallet;
        preSaleDeadLine = vars.preSaleDeadLine;
        name = vars.name;
        symbol = vars.symbol;
        bSupportEOAMint = vars.bSupportEOAMint;

        _erc721TransferExempt[creator] = true;
        _erc721TransferExempt[_tomojiManager] = true;

        if (vars.reserved > 0) {
            _mintERC20(creator, vars.reserved * units);
        }
        _mintERC20(
            _tomojiManager,
            (vars.nftTotalSupply - vars.reserved) * units
        );
        preSaleAmountLeft = (vars.nftTotalSupply - vars.reserved) / 2;
    }

    constructor() payable {
        decimals = 18;
        units = 10 ** decimals;
        factory = msg.sender;
        _tomojiManager = ITomojiFactory(msg.sender)._tomojiManager();

        DataTypes.CreateTomojiParameters memory vars = ITomojiFactory(
            msg.sender
        ).parameters();
        initialized(vars);

        (
            address router,
            address v3NonfungiblePositionManagerAddress
        ) = ITomojiManager(_tomojiManager).getSwapRouter();
        _erc721TransferExempt[router] = true;
        _erc721TransferExempt[v3NonfungiblePositionManagerAddress] = true;
        _setV3SwapTransferExempt(v3NonfungiblePositionManagerAddress);
        allowance[_tomojiManager][v3NonfungiblePositionManagerAddress] = type(
            uint256
        ).max;

        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                DOMAIN_NAME,
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
    }

    function multiTransfer(
        address[] calldata to_,
        uint256 value
    ) public virtual returns (bool) {
        for (uint256 i = 0; i < to_.length; i++) {
            transfer(to_[i], value);
        }

        return true;
    }

    function mint(
        uint256 mintAmount_,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public payable virtual returns (bool) {
        if (bSupportEOAMint) {
            recover(buildMintSeparator(msg.sender, mintAmount_), v, r, s);
        }

        if (preSaleAmountLeft == 0) {
            revert SoldOut();
        }
        if (block.timestamp > preSaleDeadLine) {
            revert ExceedPresaleDeadline();
        }

        if (mintAmount_ > preSaleAmountLeft) {
            mintAmount_ = preSaleAmountLeft;
        }

        uint256 price = mintPrice * mintAmount_;
        if (mintAmount_ == 0 || msg.value < price) {
            revert InvaildParam();
        }
        if (msg.sender != creator) {
            if (mintAccount[msg.sender] + mintAmount_ > maxPerWallet) {
                revert ReachMaxPerMint();
            }
            mintAccount[msg.sender] += mintAmount_;
        }
        preSaleAmountLeft -= mintAmount_;

        uint256 buyAmount = mintAmount_ * units;
        _transferERC20WithERC721(_tomojiManager, msg.sender, buyAmount);

        //refund if pay more
        if (msg.value > price) {
            (bool success, ) = payable(msg.sender).call{
                value: msg.value - price
            }("");
            if (!success) {
                revert SendETHFailed();
            }
        }

        //add liquidity to uniswap pool
        if (preSaleAmountLeft == 0) {
            //after sold out, open trading
            enableTrading = true;
            //add liquidity using eth and left token
            ITomojiManager(_tomojiManager).addLiquidityForTomoji{
                value: address(this).balance
            }(address(this), balanceOf[_tomojiManager]);
        }

        return true;
    }

    function refundIfPresaleFailed(
        uint256 refundErc20Amount
    ) public virtual returns (bool) {
        if (preSaleAmountLeft > 0 && block.timestamp > preSaleDeadLine) {
            uint256 refundNum = refundErc20Amount / units;
            if (refundNum == 0) {
                revert InvaildParam();
            }
            uint256 refundValue = refundNum * mintPrice;
            if (
                _transferERC20WithERC721(
                    msg.sender,
                    address(0),
                    refundNum * units
                )
            ) {
                (bool success, ) = payable(msg.sender).call{value: refundValue}(
                    ""
                );
                if (!success) {
                    revert SendETHFailed();
                }
            }
        } else {
            revert PresaleNotFinshed();
        }
        return true;
    }

    /**
     * @dev Returns the address of the tomoji creator.
     * for modify nft infomation on opensea/element/... marketplace
     */
    function owner() public view virtual returns (address) {
        return creator;
    }

    /**************Only Call By Factory Function **********/

    function setTokenURI(
        string calldata _tokenURI
    ) public onlyFactoryOrManager {
        baseTokenURI = _tokenURI;
    }

    function setERC721TransferExempt(
        address[] calldata exemptAddrs,
        bool state
    ) public onlyFactoryOrManager {
        for (uint256 i = 0; i < exemptAddrs.length; ) {
            if (exemptAddrs[i] == address(0)) {
                revert ZeroAddress();
            }
            _setERC721TransferExempt(exemptAddrs[i], state);
        }
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        if (_getOwnerOf(id) == address(0)) {
            revert InvalidTokenId();
        }
        return string.concat(baseTokenURI, Strings.toString(id));
    }

    function _setV3SwapTransferExempt(
        address v3NonfungiblePositionManagerAddress
    ) internal {
        address weth_ = INonfungiblePositionManager(
            v3NonfungiblePositionManagerAddress
        ).WETH9();
        address swapFactory = INonfungiblePositionManager(
            v3NonfungiblePositionManagerAddress
        ).factory();

        uint24[3] memory feeTiers = [
            uint24(500),
            uint24(3_000),
            uint24(10_000)
        ];

        for (uint256 i = 0; i < feeTiers.length; ) {
            address v3PairAddr = LibCaculatePair._getUniswapV3Pair(
                swapFactory,
                address(this),
                weth_,
                feeTiers[i]
            );
            // Set the v3 pair as exempt.
            _erc721TransferExempt[v3PairAddr] = true;
            unchecked {
                ++i;
            }
        }
    }

    function _transferERC20(
        address from_,
        address to_,
        uint256 value_
    ) internal virtual override {
        //Stop transfer before presale success except _mintERC20 in constructor
        //Aslo except user can refund by interface refundIfPresaleFailed
        //Also except transfer from _tomojiManager in mint function
        if (
            !enableTrading &&
            to_ != address(0) &&
            from_ != address(0) &&
            from_ != _tomojiManager
        ) {
            revert TradingNotEnable();
        }
        super._transferERC20(from_, to_, value_);
    }

    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public view returns (bool) {
        address recoveredAddress = ecrecover(hash, v, r, s);
        address tomojiSignAddr = ITomojiManager(_tomojiManager)
            ._tomojiSignAddr();

        if (
            recoveredAddress == address(0) || recoveredAddress != tomojiSignAddr
        ) {
            revert SignatureInvalid();
        }
        return true;
    }

    function buildMintSeparator(
        address sender,
        uint256 amount
    ) internal view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR,
                    keccak256(
                        abi.encode(MINT_TYPEHASH, address(this), sender, amount)
                    )
                )
            );
    }
}
