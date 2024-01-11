// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

/**
 * @dev Interface of ERC20 Blance checkpointing for off-chain voting functionality.
 */

interface IERC20Checkpointable {
    /// @notice A checkpoint for marking an account's balance changes from a given block
    struct Checkpoint {
        uint256 fromBlock;
        uint256 balance;
    }

    /// @notice An event thats emitted when an account's token balance changes
    event BalanceChanged(address indexed account, uint256 previousBalance, uint256 newBalance);

    function numCheckpoints(address) external returns (uint256);

    function getCheckpoint(address account, uint256 index) external view returns (Checkpoint memory);

    function getPriorBalance(address account, uint256 blockNumber) external view returns (uint256);
}
