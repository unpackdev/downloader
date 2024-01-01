// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "DataTypes.sol";

interface IVotingPowerAggregator {
    function createVaultsSnapshot()
        external
        view
        returns (DataTypes.VaultSnapshot[] memory snapshots);

    function getVotingPower(
        address account,
        uint256 timestamp
    ) external view returns (DataTypes.VaultVotingPower[] memory);

    function getVotingPower(
        address account,
        uint256 timestamp,
        address[] memory vaults
    ) external view returns (DataTypes.VaultVotingPower[] memory);

    function calculateWeightedPowerPct(
        DataTypes.VaultVotingPower[] calldata vaultVotingPowers
    ) external view returns (uint256);

    function listVaults()
        external
        view
        returns (DataTypes.VaultWeight[] memory);

    function getVaultWeight(address vault) external view returns (uint256);

    function setSchedule(
        DataTypes.VaultWeightSchedule calldata schedule
    ) external;
}
