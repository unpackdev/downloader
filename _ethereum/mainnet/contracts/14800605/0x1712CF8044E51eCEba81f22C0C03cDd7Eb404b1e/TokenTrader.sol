// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./ECDSA.sol";
import "./ReentrancyGuard.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IERC721Mintable.sol";

contract TokenTrader is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH =
        keccak256("EIP712Domain(uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the whitelist signature
    bytes32 public constant WHITELIST_TYPEHASH =
        keccak256("Whitelist(address account,uint256 amount)");

    address public constant REVENUE_SHARE_ADDRESS = 0xa9F3e5d8f15A32335455016B52C30d5b651E220b;

    uint256 public constant REVENUE_SHARE = 15;

    IERC721Mintable public immutable collection;

    uint256 public immutable whitelistUntil;

    address public immutable signer;

    string public sigListIpfsHash;

    uint256 public price;

    mapping(address => bool) public didClaim;

    // EVENTS

    event TokenBought(address buyer, uint256 amount);

    // CONSTRUCTOR

    constructor(
        IERC721Mintable collection_,
        uint256 price_,
        uint256 whitelistDuration,
        address signer_
    ) {
        collection = collection_;
        price = price_;
        whitelistUntil = block.timestamp + whitelistDuration;
        signer = signer_;
    }

    // PUBLIC FUNCTIONS

    function buy(uint256 amount) external payable nonReentrant {
        require(block.timestamp >= whitelistUntil, "Only whitelisted can buy now");
        _buy(amount);
    }

    function buyWhitelist(
        uint256 amount,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable nonReentrant {
        _validateSignature(amount, v, r, s);

        require(!didClaim[msg.sender], "Already claimed whitelist");
        didClaim[msg.sender] = true;

        _buy(amount);
    }

    // RESTRICTED FUNCTIONS

    function setPrice(uint256 price_) external onlyOwner {
        price = price_;
    }

    function withdraw() external onlyOwner {
        uint256 revenueShareAmount = (payable(address(this)).balance * REVENUE_SHARE) / 100;
        payable(REVENUE_SHARE_ADDRESS).transfer(revenueShareAmount);
        payable(msg.sender).transfer(payable(address(this)).balance);
    }

    function sweep(
        IERC20 token,
        address to,
        uint256 amount
    ) external onlyOwner {
        if (amount == 0) {
            amount = token.balanceOf(address(this));
        }
        token.safeTransfer(to, amount);
    }

    function setSigListIpfsHash(string memory sigListIpfsHash_) external onlyOwner {
        sigListIpfsHash = sigListIpfsHash_;
    }

    // INTERNAL FUNCTIONS

    function _buy(uint256 amount) internal {
        require(msg.value == amount * price, "Value passed is too low");
        collection.mint(msg.sender, amount); // As ERC721A is used it will mint given amount of token
        emit TokenBought(msg.sender, amount);
    }

    function _validateSignature(
        uint256 amount,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view {
        bytes32 domainSeparator = keccak256(
            abi.encode(DOMAIN_TYPEHASH, _getChainId(), address(this))
        );
        bytes32 structHash = keccak256(abi.encode(WHITELIST_TYPEHASH, msg.sender, amount));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address realSigner = ECDSA.recover(digest, v, r, s);

        require(realSigner == signer, "Invalid signature");
    }

    function _getChainId() internal view returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }
}
