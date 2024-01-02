// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

interface IPriorityPool {
    function paused() external view returns (bool);

    function depositsSinceLastUpdate() external view returns (uint256);

    function pauseForUpdate() external;

    function updateDistribution(
        bytes32 _merkleRoot,
        bytes32 _ipfsHash,
        uint256 _amountDistributed,
        uint256 _sharesAmountDistributed
    ) external;
}
