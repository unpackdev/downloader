// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

/// @title Allows anyone to claim a token if they exist in a merkle root.
interface IMerkleDistributor {
    /// @notice Returns the address of the token distributed by this contract.
    function token() external view returns (address);

    /// @notice Returns the merkle root of the merkle tree containing account balances available to claim.
    function merkleRoot() external view returns (bytes32);

    /// @notice Returns the unix timestamp that marks the end of the token distribution.
    function distributionEnd() external view returns (uint256);

    /// @notice Returns true if the index has been marked claimed.
    /// @param index A value from the generated input list.
    function isClaimed(uint256 index) external view returns (bool);

    /// @notice Claim the given amount of the token to the given address. Reverts if the inputs are invalid.
    /// @param index A value from the generated input list.
    /// @param account A value from the generated input list.
    /// @param amount A value from the generated input list.
    function claim(
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external;

    /// @notice Allows the owner to reclaim the tokens after the distribution has ended.
    /// @param recipient The address receiving the tokens.
    function withdraw(address recipient) external;

    /// @notice This event is triggered whenever a call to #claim succeeds.
    /// @param index A value from the generated input list.
    /// @param account A value from the generated input list.
    /// @param amount A value from the generated input list.
    event Claimed(uint256 index, address account, uint256 amount);

    /// @notice This event is triggered whenever a call to #withdraw succeeds.
    /// @param account The address that received the tokens.
    /// @param amount The amount of tokens the address received.
    event Withdrawn(address account, uint256 amount);

    /// @notice Error thrown when there's nothing to withdraw.
    error AlreadyWithdrawn();

    /// @notice Error thrown when the distribution period ended.
    /// @param current The current timestamp.
    /// @param end The time when the distribution ended.
    error DistributionEnded(uint256 current, uint256 end);

    /// @notice Error thrown when the distribution period did not end yet.
    /// @param current The current timestamp.
    /// @param end The time when the distribution ends.
    error DistributionOngoing(uint256 current, uint256 end);

    /// @notice Error thrown when the drop is already claimed.
    error DropClaimed();

    /// @notice Error thrown when the Merkle proof is invalid.
    error InvalidProof();

    /// @notice Error thrown when a transfer failed.
    /// @param token The address of token attempted to be transferred.
    /// @param from The sender of the token.
    /// @param to The recipient of the token.
    error TransferFailed(address token, address from, address to);
}
