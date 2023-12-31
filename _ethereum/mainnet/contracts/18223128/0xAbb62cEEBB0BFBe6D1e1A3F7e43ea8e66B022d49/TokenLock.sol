// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

import "Ownable.sol";
import "IERC20.sol";

/**
 * Token Lock contract holds tokens swapped by the Vesting Executor for vested tokens. 

 */

contract TokenLock is Ownable {
    /* ========== Constructor ========== */
    // Owner will be set to VestingExecutor contract
    constructor(address initialOwner) {
        transferOwnership(initialOwner);
    }

    /* ========== Transfer ERC20 Tokens ========== */

    /**
     * @notice Transfers a specific amount of ERC20 tokens to an address.
     * @dev The token transfer is executed using the input token's transfer function. It checks there are enough tokens on
     * the contract's balance before performing the transfer.
     * @param token The address of the ERC20 token contract that we want to make the transfer with.
     * @param to The recipient's address of the tokens.
     * @param amount The amount of tokens to be transferred.
     */

    function transferLockedTokens(
        IERC20 token,
        address to,
        uint256 amount
    ) external onlyOwner {
        uint256 erc20balance = token.balanceOf(address(this));
        require(amount <= erc20balance, "Balance too low to transfer token");
        token.transfer(to, amount);
    }
}
