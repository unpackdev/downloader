// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./Ownable.sol"; // TODO: use roles instead
import "./Allowlist.sol";
import "./Sale.sol";

/**
 * @title AllowlistedSale
 * @dev Sale in which only allowlisted users can contribute.
 */
contract AllowlistedSale is Ownable, Sale, Allowlist {
    /// @notice Deposits exceeds allowed limit
    /// @param deposit requested amount to transfer
    /// @param limit deposit limit for user
    error DepositLimitExceeded(uint256 deposit, uint256 limit);

    constructor(
        uint256 _duration,
        address _beneficiary,
        address _rewardToken
    ) Sale(_duration, _beneficiary, _rewardToken) {} // solhint-disable-line no-empty-blocks

    /**
     * @notice Restrict sale to allowlisted addresses
     * @dev Extends #deposit() from "./base/Sale.sol". Adds allowlist functionality.
     * @param proof Merkle proof for Allowlist
     */
    function deposit2(bytes32[] calldata proof) public payable {
        uint256 allowedAmount = getAllowedAmount(msg.sender, proof);

        if (deposits[msg.sender] + msg.value > allowedAmount) {
            revert DepositLimitExceeded(msg.value, allowedAmount - deposits[msg.sender]);
        }
        _deposit();
    }

    function deposit() public payable override {
        revert Unauthorized();
    }
}
