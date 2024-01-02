// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "VotingPowerHistory.sol";

interface IVault {
    function getRawVotingPower(address account) external view returns (uint256);

    function getCurrentRecord(
        address account
    ) external view returns (VotingPowerHistory.Record memory);

    function getRawVotingPower(
        address account,
        uint256 timestamp
    ) external view returns (uint256);

    function getTotalRawVotingPower() external view returns (uint256);

    function getVaultType() external view returns (string memory);
}
