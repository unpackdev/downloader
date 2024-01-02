// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import "./ITreasuryStorage.sol";
import "./IPausable.sol";

interface ITreasury is ITreasuryStorage, IPausable {
    event MaxSpendingLimitChanged(address indexed spender, address indexed token, SpendingLimits newSpendingLimits);

    /**
     * @dev contract initializer
     * @param registry The address of Registry contract
     */
    function initialize(address registry) external;

    receive() external payable;

    /**
     * @notice Transfers an amount of ERC20 or native token from the contract treasury to
     *  a receiver address, subject to certain restrictions imposed by the spender.
     * @dev The function checks the spender's transfer restrictions per transaction and per timeframe.
     * @param amount The amount of tokens to transfer.
     * @param token The address of the token to transfer. Use the address NATIVE_TOKEN_ADDRESS for native token.
     * @param receiver The address of the receiver
     */
    function transferFromTreasury(uint256 amount, address token, address receiver) external;

    /**
     * @notice Sets the maximum spending limit and other restrictions for a given spender and token.
     * @dev This function can only be called by an address with the BIG_TIMELOCK_ADMIN role.
     * @param spender The address of the spender for whom to set the new spending limit.
     * @param token The address of the token for which to set the new spending limit.
     * @param newSpendingLimits The new spending limits and restrictions to set for the spender and token.
     */
    function setMaxSpendingLimit(address spender, address token, SpendingLimits calldata newSpendingLimits) external;

    /**
     * @notice Decreases Spending limits for a spender for a specific token.
     * @dev This function can only be called by an address with the BIG_TIMELOCK_ADMIN or EMERGENCY_ADMIN role.
     * @param spender The address of the spender for whom to decrease the maximum transfer amounts and total amount.
     * @param token The address of the token for which to decrease the maximum transfer amounts and total amount.
     * @param newSpendingLimits The new spending limits and restrictions to set for the spender and token.
     */
    function decreaseLimits(address spender, address token, SpendingLimits calldata newSpendingLimits) external;

    /**
     * @notice Checks whether a spender can transfer tokens based on the minimum time between transfers imposed by the spending restrictions.
     * @param spender The address of the spender to check for.
     * @param token The address of the token for which to check the time restrictions.
     * @return A boolean indicating whether the spender can transfer tokens based on the minimum time between transfers.
     */
    function canTransferByTime(address spender, address token) external returns (bool);
}
