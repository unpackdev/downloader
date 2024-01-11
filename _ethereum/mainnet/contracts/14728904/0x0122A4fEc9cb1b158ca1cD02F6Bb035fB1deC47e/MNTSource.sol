// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.9;

import "./IERC20.sol";
import "./Math.sol";

import "./ErrorCodes.sol";

/**
 * @title MNTSource Contract
 * @notice Distributes a token to a different contract at a fixed rate.
 * @dev This contract must be poked via the `drip()` function every so often.
 * @author Minterest
 */
contract MNTSource {
    /// @notice The block number when the MNTSource started (immutable)
    uint256 public dripStart;

    /// @notice Tokens per block that to drip to target (immutable)
    uint256 public dripRate;

    /// @notice Reference to token to drip (immutable)
    IERC20 public token;

    /// @notice Target to receive dripped tokens (immutable)
    address public target;

    /// @notice Amount that has already been dripped
    uint256 public dripped;

    /**
     * @notice Constructs a MNTSource
     * @param dripRate_ Number of tokens per block to drip
     * @param token_ The token to drip
     * @param target_ The recipient of dripped tokens
     */
    constructor(
        uint256 dripRate_,
        IERC20 token_,
        address target_
    ) {
        require(target_ != address(0), ErrorCodes.TARGET_ADDRESS_CANNOT_BE_ZERO);
        dripStart = block.number;
        dripRate = dripRate_;
        token = token_;
        target = target_;
        dripped = 0;
    }

    /**
     * @notice Drips the maximum amount of tokens to match the drip rate since inception
     * @dev Note: this will only drip up to the amount of tokens available.
     * @return The amount of tokens dripped in this call
     */
    function drip() external returns (uint256) {
        // First, read storage into memory
        IERC20 token_ = token;
        uint256 mntSourceBalance_ = token_.balanceOf(address(this));
        uint256 dripRate_ = dripRate;
        uint256 dripStart_ = dripStart;
        uint256 dripped_ = dripped;
        address target_ = target;
        uint256 blockNumber_ = block.number;

        // Next, calculate intermediate values
        uint256 dripTotal_ = dripRate_ * (blockNumber_ - dripStart_);
        uint256 deltaDrip_ = dripTotal_ - dripped_;
        uint256 toDrip_ = Math.min(mntSourceBalance_, deltaDrip_);
        uint256 drippedNext_ = dripped_ + toDrip_;

        // Finally, write new `dripped` value and transfer tokens to target
        dripped = drippedNext_;
        require(token_.transfer(target_, toDrip_));

        return toDrip_;
    }
}
