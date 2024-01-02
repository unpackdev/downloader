// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "EnumerableMap.sol";

import "DataTypes.sol";
import "ScaledMath.sol";

library VaultsSnapshot {
    using EnumerableMap for EnumerableMap.AddressToUintMap;
    using ScaledMath for uint256;

    function getBallotPercentage(
        DataTypes.VaultSnapshot[] memory snapshots,
        EnumerableMap.AddressToUintMap storage vaultPowers
    ) internal view returns (uint256 votingPowerPct) {
        for (uint256 i; i < snapshots.length; i++) {
            DataTypes.VaultSnapshot memory snapshot = snapshots[i];
            (, uint256 ballotPower) = vaultPowers.tryGet(snapshot.vaultAddress);
            votingPowerPct += ballotPower
                .divDown(snapshot.totalVotingPower)
                .mulDown(snapshot.weight);
        }
    }

    /// @dev this simply appends, so the storage must be clean
    function persist(
        DataTypes.VaultSnapshot[] memory snapshots,
        DataTypes.VaultSnapshot[] storage cleanStorage
    ) internal {
        require(cleanStorage.length == 0, "storage must be clean");
        for (uint256 i; i < snapshots.length; i++) {
            cleanStorage.push(snapshots[i]);
        }
    }
}
