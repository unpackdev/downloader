// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent mint calls per limit by tx to a function.
 *
 * Inheriting from `MintCooldown` will make the {onCooldown} modifier
 * available, which can be applied to functions to make sure there are no more mint
 * (cooldown) calls to them.
 */
contract MintCooldown {
    mapping(address => mapping(uint256 => uint256)) private _counter;

    modifier onCooldown(uint256 limit, uint256 count) {
        // Verify limit (not mandatory, but will prevent some gas costs)
        require(count <= limit, "MintCooldown: MINT_LIMIT_OVERFLOW");
        // Preserve cache
        address sender = tx.origin;
        uint256 blockNumber = block.number;
        // Get current cooldown for origin sender and current block
        uint256 current = _counter[sender][blockNumber];
        // If limit overflow, abort the tx
        require(current + count <= limit, "MintCooldown: TX_MINT_COOLDOWN");
        // Update before execution (for reentrancy)
        _counter[sender][blockNumber] += count;
        _;
    }
}
