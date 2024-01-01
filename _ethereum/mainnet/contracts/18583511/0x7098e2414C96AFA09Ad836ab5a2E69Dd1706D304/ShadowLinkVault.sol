// ShadowLink Corporation Vault

// Website: https://thepunklist.com
// Twitter: https://twitter.com/cypherpunk_eth
// Telegram: https://t.me/thepunklist

// SPDX-License-Identifier:MIT
pragma solidity ^0.8.18;

import "./Interfaces.sol";

// @title ShadowLinkVault - Used to prove your membership. Soulbound Vault.
contract ShadowLinkVault {
    bool private _reentrancyGuard;

    IERC20 public immutable TOKEN;
    // @dev - number of tokens we accept in the vault
    uint public immutable TOKEN_AMOUNT;

    // @dev - This is the ceiling of deposits.
    uint16 public immutable LIMIT = 220;
    uint16 public remaining = 220;

    // User -> token -> deposit balance
    mapping (address => uint256) public tokenBalancesByUser;

    event TokensDeposited(address indexed sender, uint256 amount, uint256 block);

    // @param tokenAmount_ the amount in wei of the tokens we need for deposit
    constructor( IERC20 token_, uint256 tokenAmount_) {
        TOKEN = token_;
        TOKEN_AMOUNT = tokenAmount_;
    }

    // Prevents reentrancy attacks via tokens with callback mechanisms.
    modifier nonReentrant() {
        require(!_reentrancyGuard, 'no reentrancy');
        _reentrancyGuard = true;
        _;
        _reentrancyGuard = false;
    }

    function hasDeposit(address depositor) public view returns (bool isDepositor) {
        isDepositor = tokenBalancesByUser[depositor] == TOKEN_AMOUNT;
    }

    // @notice - you need to deposit the exact amount of tokens or this will fail.
    function deposit(
        uint256 amount
    ) external nonReentrant {
        // require amount
        require(amount == TOKEN_AMOUNT, "INCORRECT TOKEN AMOUNT");
        require(remaining > 0, "VAULT IS CLOSED");
        require(tokenBalancesByUser[msg.sender] == 0, "User has already deposited tokens");
        // decrement the spotsRemaining
        remaining -= 1;
        // transfer in
        TOKEN.transferFrom(msg.sender, address(this), amount);
        // Credit the caller.
        tokenBalancesByUser[msg.sender] += amount;
        emit TokensDeposited(msg.sender, amount, block.number);
    }

}
