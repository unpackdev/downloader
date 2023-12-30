// SPDX-License-Identifier: No License (None)
pragma solidity ^0.6.9;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract EscrowLock {
    address public companyWallet = 0xc326DF3Bec90f94887d2756E03B51a222F2b0de4;
    address public token = 0x014A5BcD4BA9b327738d550762fd592014b77180;  // JNTR token contract address
    uint256 public constant UNLOCK_TIME = 1916956800; // Tokens are locked until 30 September 2030, 00:00:00 UTC

    function transfer(address to, uint256 amount) external returns (bool) {
        require(msg.sender == companyWallet, "ERR_NOT_COMPANY");
        require(UNLOCK_TIME <= block.timestamp, "ERR_TOKENS_LOCKED");
        IERC20(token).transfer(to, amount);
    }
}