// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

interface IPausable {
    // Emitted once the pause is triggered by an `account`
    event Paused(address indexed account);
    // Emitted once the pause is lifted by an `account`
    event Unpaused(address indexed account);

    /// @notice Returns true if the contract is paused, and false otherwise
    function paused() external view returns (bool);

    /// @notice Pauses the contract. Reverts if caller is not owner or already paused
    function pause() external;

    /// @notice Unpauses the contract. Reverts if the caller is not owner or already not paused
    function unpause() external;
}
