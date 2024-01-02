// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "GovernanceOnly.sol";
import "DataTypes.sol";
import "ScaledMath.sol";
import "VaultsSnapshot.sol";
import "IVotingPowerAggregator.sol";
import "IGovernanceManager.sol";

import "Address.sol";
import "EnumerableMap.sol";

contract EmergencyRecovery is GovernanceOnly {
    using Address for address;
    using ScaledMath for uint256;
    using EnumerableMap for EnumerableMap.AddressToUintMap;
    using VaultsSnapshot for DataTypes.VaultSnapshot[];

    address public immutable safeAddress;
    address public immutable proxyAdmin;
    uint64 public sunsetAt;
    uint256 public vetoThreshold;
    uint64 public timelockDuration;

    string private UPGRADE_TO_SIG = "upgrade(address,address)";

    mapping(uint32 => DataTypes.EmergencyRecoveryProposal) private proposals;

    mapping(uint32 => mapping(address => EnumerableMap.AddressToUintMap))
        private vetos;
    mapping(uint32 => DataTypes.VaultSnapshot[]) internal _vaultSnapshots;

    uint32 private currentProposalCount;

    constructor(
        address _governance,
        address _proxyAdmin,
        address _safeAddress,
        uint64 _sunsetAt,
        uint256 _vetoThreshold,
        uint64 _timelockDuration
    ) GovernanceOnly(_governance) {
        safeAddress = _safeAddress;
        sunsetAt = _sunsetAt;
        vetoThreshold = _vetoThreshold;
        timelockDuration = _timelockDuration;
        proxyAdmin = _proxyAdmin;
    }

    modifier onlyFromSafe() {
        if (msg.sender != safeAddress)
            revert Errors.NotAuthorized(msg.sender, safeAddress);
        _;
    }

    modifier notSunset() {
        require(
            sunsetAt > uint64(block.timestamp),
            "emergency recovery is sunset"
        );
        _;
    }

    event UpgradeProposed(uint32 proposalId, bytes payload);

    function startGovernanceUpgrade(
        address newUnderlying
    ) external onlyFromSafe notSunset returns (uint32) {
        bytes memory payload = abi.encodeWithSignature(
            UPGRADE_TO_SIG,
            governance,
            newUnderlying
        );

        uint32 propId = currentProposalCount;
        proposals[propId].createdAt = uint64(block.timestamp);
        proposals[propId].completesAt =
            uint64(block.timestamp) +
            timelockDuration;
        proposals[propId].status = DataTypes.Status.Queued;
        proposals[propId].payload = payload;
        _votingPowerAggregator().createVaultsSnapshot().persist(
            _vaultSnapshots[propId]
        );
        currentProposalCount++;

        emit UpgradeProposed(propId, payload);
        return propId;
    }

    event UpgradeExecuted(uint32 proposalId, address governance, bytes payload);
    event UpgradeVetoed(uint32 proposalId);

    function completeGovernanceUpgrade(uint32 proposalId) external {
        DataTypes.EmergencyRecoveryProposal storage prop = proposals[
            proposalId
        ];
        require(prop.completesAt > 0, "proposal does not exist");
        require(
            prop.completesAt < uint64(block.timestamp),
            "proposal is still timelocked"
        );
        require(
            prop.status == DataTypes.Status.Queued,
            "proposal must be queued"
        );

        DataTypes.VaultSnapshot[] memory snapshot = _vaultSnapshots[proposalId];
        // the following line should never revert unless there is a bug elsewhere in the code
        // but the operation is critical, so we add it for safety
        require(snapshot.length > 0, "no snapshot found");
        uint256 vetoedPct = snapshot.getBallotPercentage(prop.vetos);
        bool isVetoed = vetoedPct > vetoThreshold;
        if (isVetoed) {
            prop.status = DataTypes.Status.Rejected;
            emit UpgradeVetoed(proposalId);
            return;
        }

        proxyAdmin.functionCall(prop.payload);
        prop.status = DataTypes.Status.Executed;

        emit UpgradeExecuted(proposalId, governance, prop.payload);
    }

    event VetoCast(
        uint24 proposalId,
        DataTypes.VaultVotingPower[] castVetoPower
    );

    function veto(uint24 proposalId) external {
        DataTypes.EmergencyRecoveryProposal storage prop = proposals[
            proposalId
        ];
        require(prop.completesAt > 0, "proposal does not exist");
        require(
            prop.completesAt > uint64(block.timestamp),
            "proposal is out of timelock"
        );

        // Zero out the effect of previous vetos to avoid double-counting;
        EnumerableMap.AddressToUintMap storage currentVetoPower = vetos[
            proposalId
        ][msg.sender];
        for (uint256 i = 0; i < prop.vetos.length(); i++) {
            (address vault, uint256 vaultVetoPower) = prop.vetos.at(i);
            (, uint256 votingPower) = currentVetoPower.tryGet(vault);
            prop.vetos.set(vault, vaultVetoPower - votingPower);
        }

        DataTypes.VaultVotingPower[]
            memory newVetoPower = _votingPowerAggregator().getVotingPower(
                msg.sender,
                prop.createdAt
            );
        for (uint256 i = 0; i < newVetoPower.length; i++) {
            DataTypes.VaultVotingPower memory vault = newVetoPower[i];
            (, uint256 currentVetoTotal) = prop.vetos.tryGet(
                vault.vaultAddress
            );
            uint256 newVetoTotal = currentVetoTotal + vault.votingPower;
            prop.vetos.set(vault.vaultAddress, newVetoTotal);
            vetos[proposalId][msg.sender].set(vault.vaultAddress, newVetoTotal);
        }
        emit VetoCast(
            proposalId,
            _toVotingPowers(vetos[proposalId][msg.sender])
        );
    }

    function _toVotingPowers(
        EnumerableMap.AddressToUintMap storage map
    ) internal view returns (DataTypes.VaultVotingPower[] memory) {
        DataTypes.VaultVotingPower[]
            memory vvps = new DataTypes.VaultVotingPower[](map.length());
        for (uint256 i = 0; i < map.length(); i++) {
            (address key, uint256 value) = map.at(i);
            vvps[i] = DataTypes.VaultVotingPower({
                vaultAddress: key,
                votingPower: value
            });
        }

        return vvps;
    }

    function setSunsetAt(uint64 _sunsetAt) external governanceOnly {
        sunsetAt = _sunsetAt;
    }

    function setVetoThreshold(uint256 _vetoThreshold) external governanceOnly {
        vetoThreshold = _vetoThreshold;
    }

    function setTimelockDuration(
        uint64 _timelockDuration
    ) external governanceOnly {
        timelockDuration = _timelockDuration;
    }

    function getVetoPercentage(
        uint32 proposalId
    ) external view returns (uint256) {
        DataTypes.EmergencyRecoveryProposal storage prop = proposals[
            proposalId
        ];
        DataTypes.VaultSnapshot[] memory snapshot = _vaultSnapshots[proposalId];
        return snapshot.getBallotPercentage(prop.vetos);
    }

    function _votingPowerAggregator()
        internal
        returns (IVotingPowerAggregator)
    {
        return IGovernanceManager(governance).votingPowerAggregator();
    }
}
