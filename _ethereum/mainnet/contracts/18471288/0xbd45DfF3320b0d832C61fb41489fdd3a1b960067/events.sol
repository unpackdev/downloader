// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract Events {
    /// @notice Emitted when a Lido ETH withdrawal is queued
    event LogQueueEthWithdrawal(
        uint256 indexed stEthAmount,
        uint256 indexed requestId,
        uint256 indexed protocolId
    );

    /// @notice Emitted when debt is repaid
    event LogWethPayback(uint256 indexed amount, uint256 indexed protocolId);

    /// @notice Emitted when a Lido ETH withdrawal is claimed
    event LogClaimEthWithdrawal(
        uint256 indexed stEthAmount,
        uint256 indexed requestId,
        uint256 indexed protocolId
    );
}
