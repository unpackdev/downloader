// SPDX-License-Identifier: AGPL-3.0-only
// ERC20 Extensions v1.1.1
pragma solidity ^0.8.0;

/// @title Vesting functionality for ERC20 tokens
/// @author Daniel Gretzke
/// @notice allows to set up multiple vesting schedules for token holders supporting a cliff + vesting schedule
/// @notice if an account is vested the smart contract ensures that the account has a minimum balance according to the vesting schedule, sending more tokens reverts the transaction
/// @notice every vesting schedule has a dedicated vesting admin, if this admin transfers tokens to an account, the vesting schedule is set up for the amount of sent tokens automatically
/// @dev setting the cliff amount to n% unlocks n% of tokens after the cliff timestamp, 100% - n% of tokens are unlocked gradually over the `duration`
/// @dev setting the cliff timestamp to the current timestamp starts the vesting period immediately
/// @dev setting duration to zero will unlock the full amount after the cliff timestamp
interface IVestedToken {
    event VestingScheduleAdded(uint256 indexed vestingId, uint256 cliff, uint256 cliffAmount, uint256 duration);
    event TokensVested(uint256 indexed vestingId, address indexed account, uint256 amount);

    function vestingPeriods(uint256 id)
        external
        view
        returns (
            uint256 cliffTimestamp,
            uint256 cliffAmount,
            uint256 duration
        );

    function vestedBalances(address account) external view returns (uint256 vestingId, uint256 amount);

    function vestingAdmins(address account) external view returns (uint256 id);

    /// @notice calculates the amount of locked tokens (minimum balance) for a given account
    function lockedTokens(address account) external view returns (uint256);
}
