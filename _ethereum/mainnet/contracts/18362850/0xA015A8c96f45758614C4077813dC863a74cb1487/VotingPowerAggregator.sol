// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "EnumerableSet.sol";

import "ImmutableOwner.sol";

import "Errors.sol";
import "ScaledMath.sol";

import "IVotingPowerAggregator.sol";
import "IVault.sol";

contract VotingPowerAggregator is IVotingPowerAggregator, ImmutableOwner {
    using ScaledMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet internal _vaultAddresses;
    mapping(address => DataTypes.VaultWeightConfiguration) internal _vaults;

    uint256 public scheduleStartsAt;
    uint256 public scheduleEndsAt;

    constructor(
        address _owner,
        DataTypes.VaultWeightSchedule memory initialSchedule
    ) ImmutableOwner(_owner) {
        _setSchedule(initialSchedule);
    }

    function createVaultsSnapshot()
        external
        view
        returns (DataTypes.VaultSnapshot[] memory snapshots)
    {
        uint256 len = _vaultAddresses.length();
        snapshots = new DataTypes.VaultSnapshot[](len);
        for (uint256 i = 0; i < len; i++) {
            snapshots[i] = _makeVaultSnapshot(_vaultAddresses.at(i));
        }
    }

    function _makeVaultSnapshot(
        address vaultAddress
    ) internal view returns (DataTypes.VaultSnapshot memory) {
        return
            DataTypes.VaultSnapshot({
                vaultAddress: vaultAddress,
                weight: getVaultWeight(vaultAddress),
                totalVotingPower: IVault(vaultAddress).getTotalRawVotingPower()
            });
    }

    function getVotingPower(
        address account,
        uint256 timestamp
    ) external view returns (DataTypes.VaultVotingPower[] memory) {
        return getVotingPower(account, timestamp, _vaultAddresses.values());
    }

    function getVotingPower(
        address account,
        uint256 timestamp,
        address[] memory vaults
    ) public view returns (DataTypes.VaultVotingPower[] memory) {
        DataTypes.VaultVotingPower[]
            memory userVotingPower = new DataTypes.VaultVotingPower[](
                vaults.length
            );
        for (uint256 i; i < vaults.length; i++) {
            IVault vault = IVault(vaults[i]);
            uint256 userRawVotingPower = vault.getRawVotingPower(
                account,
                timestamp
            );
            userVotingPower[i] = DataTypes.VaultVotingPower({
                vaultAddress: address(vault),
                votingPower: userRawVotingPower
            });
        }

        return userVotingPower;
    }

    function calculateWeightedPowerPct(
        DataTypes.VaultVotingPower[] calldata vaultVotingPowers
    ) external view returns (uint256) {
        uint256 votingPowerPct;

        for (uint256 i; i < vaultVotingPowers.length; i++) {
            DataTypes.VaultVotingPower memory vaultVP = vaultVotingPowers[i];
            uint256 vaultWeight = getVaultWeight(vaultVP.vaultAddress);
            if (vaultWeight > 0 && vaultVP.votingPower > 0) {
                uint256 tvp = IVault(vaultVP.vaultAddress)
                    .getTotalRawVotingPower();
                votingPowerPct += vaultVP.votingPower.divDown(tvp).mulDown(
                    vaultWeight
                );
            }
        }

        return votingPowerPct;
    }

    function listVaults()
        external
        view
        returns (DataTypes.VaultWeight[] memory)
    {
        uint256 length = _vaultAddresses.length();
        DataTypes.VaultWeight[] memory vaults = new DataTypes.VaultWeight[](
            length
        );
        for (uint256 i; i < length; i++) {
            DataTypes.VaultWeightConfiguration memory conf = _vaults[
                _vaultAddresses.at(i)
            ];
            vaults[i].vaultAddress = conf.vaultAddress;
            vaults[i].initialWeight = conf.initialWeight;
            vaults[i].targetWeight = conf.targetWeight;

            uint256 vaultWeight = getVaultWeight(conf.vaultAddress);
            vaults[i].currentWeight = vaultWeight;
        }

        return vaults;
    }

    function blockTimestamp() internal view virtual returns (uint256) {
        return block.timestamp;
    }

    function getVaultWeight(address vault) public view returns (uint256) {
        DataTypes.VaultWeightConfiguration memory vaultWeight = _vaults[vault];

        if (blockTimestamp() > scheduleEndsAt) {
            return vaultWeight.targetWeight;
        }

        if (blockTimestamp() < scheduleStartsAt) {
            return vaultWeight.initialWeight;
        }

        uint256 scheduleElapsedPct = (blockTimestamp() - scheduleStartsAt)
            .divDown(scheduleEndsAt - scheduleStartsAt);

        uint256 currentWeight;
        if (vaultWeight.targetWeight > vaultWeight.initialWeight) {
            uint256 absWeightChange = vaultWeight.targetWeight -
                vaultWeight.initialWeight;
            currentWeight =
                vaultWeight.initialWeight +
                absWeightChange.mulDown(scheduleElapsedPct);
        } else {
            uint256 absWeightChange = vaultWeight.initialWeight -
                vaultWeight.targetWeight;
            currentWeight =
                vaultWeight.initialWeight -
                absWeightChange.mulDown(scheduleElapsedPct);
        }
        return currentWeight;
    }

    function setSchedule(
        DataTypes.VaultWeightSchedule calldata schedule
    ) external onlyOwner {
        _setSchedule(schedule);
    }

    function _setSchedule(
        DataTypes.VaultWeightSchedule memory schedule
    ) internal {
        require(
            schedule.endsAt > schedule.startsAt,
            "schedule must end after it begins"
        );

        scheduleStartsAt = schedule.startsAt;
        scheduleEndsAt = schedule.endsAt;

        _removeAllVaults();

        uint256 totalInitialWeight;
        uint256 totalTargetWeight;

        for (uint256 i; i < schedule.vaults.length; i++) {
            DataTypes.VaultWeightConfiguration memory vault = schedule.vaults[
                i
            ];
            _addVault(vault);
            totalInitialWeight += vault.initialWeight;
            totalTargetWeight += vault.targetWeight;
        }

        if (totalInitialWeight != ScaledMath.ONE)
            revert Errors.InvalidTotalWeight(totalInitialWeight);

        if (totalTargetWeight != ScaledMath.ONE)
            revert Errors.InvalidTotalWeight(totalTargetWeight);
    }

    function _addVault(
        DataTypes.VaultWeightConfiguration memory vault
    ) internal {
        if (!_vaultAddresses.add(vault.vaultAddress))
            revert Errors.DuplicatedVault(vault.vaultAddress);
        _vaults[vault.vaultAddress] = vault;
    }

    function _removeAllVaults() internal {
        uint256 length = _vaultAddresses.length();
        for (uint256 i; i < length; i++) {
            address vaultAddress = _vaultAddresses.at(0);
            _vaultAddresses.remove(vaultAddress);
            delete _vaults[vaultAddress];
        }
    }
}
