// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
import "./IERC20Upgradeable.sol";

/**
 * This interface enables for the Chronos interface to be usable in
 * upgradeable contracts such as the Holding and Wagering contracts,
 * despite the fact that Chronos is not an upgradeable token
 */
interface IChronosUpgradeable is IERC20Upgradeable {
    /// @notice Update current reward status
    function updateReward(address from, address to) external;

    /// @notice Withdraw/Claim chronos avaialable to the sender
    function withdrawChronos() external;

    /// @notice Grant chronos to a user
    /// @param _address the address to grant chronos to
    /// @param _amount the amount of chronos to grant
    function grantChronos(address _address, uint256 _amount) external;

    /// @notice Burn unclaimed chronos tokens
    /// @param user the address to burn unclaimed tokens from
    /// @param amount the amount of unclaimed tokens to burn
    function burnUnclaimed(address user, uint256 amount) external;

    /// @notice Burn chronos tokens
    /// @param user address to burn tokens from
    /// @param amount the amount of tokens to burn
    function burn(address user, uint256 amount) external;

    /// @notice get the total amount of unclaimed chronos available to a user
    /// @param user address of the user to check for
    function getTotalUnclaimed(address user)
        external
        view
        returns (uint256 unclaimed);
}
