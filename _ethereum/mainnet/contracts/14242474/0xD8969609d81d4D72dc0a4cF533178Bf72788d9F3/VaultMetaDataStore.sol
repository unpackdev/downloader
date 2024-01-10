// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

import "./Governable.sol";
import "./Gatekeeperable.sol";
import "./VaultDataStorage.sol";

///  @dev NOTE: do not add any new state variables to this contract. If needed, see {VaultDataStorage.sol} instead.
abstract contract VaultMetaDataStore is GovernableUpgradeable, Gatekeeperable, VaultDataStorage {
  event EmergencyShutdown(bool _active);
  event HealthCheckUpdated(address indexed _healthCheck);
  event FeeCollectionUpdated(address indexed _feeCollection);
  event ManagementFeeUpdated(uint256 _managementFee);
  event StrategyDataStoreUpdated(address indexed _strategyDataStore);
  event DepositLimitUpdated(uint256 _limit);
  event LockedProfitDegradationUpdated(uint256 _degradation);
  event AccessManagerUpdated(address indexed _accessManager);
  event VaultRewardsContractUpdated(address indexed _vaultRewards);

  /// @notice The maximum basis points. 1 basis point is 0.01% and 100% is 10000 basis points
  uint256 internal constant MAX_BASIS_POINTS = 10_000;

  // solhint-disable-next-line no-empty-blocks
  constructor() {}

  // solhint-disable-next-line func-name-mixedcase
  function __VaultMetaDataStore_init(
    address _governance,
    address _gatekeeper,
    address _feeCollection,
    address _strategyDataStore,
    address _accessManager,
    address _vaultRewards
  ) internal {
    __Governable_init(_governance);
    __Gatekeeperable_init(_gatekeeper);
    __VaultDataStorage_init();
    __VaultMetaDataStore_init_unchained(_feeCollection, _strategyDataStore, _accessManager, _vaultRewards);
  }

  // solhint-disable-next-line func-name-mixedcase
  function __VaultMetaDataStore_init_unchained(
    address _feeCollection,
    address _strategyDataStore,
    address _accessManager,
    address _vaultRewards
  ) internal {
    _updateFeeCollection(_feeCollection);
    _updateStrategyDataStore(_strategyDataStore);
    _updateAccessManager(_accessManager);
    _updateVaultRewardsContract(_vaultRewards);
  }

  /// @notice set the address to send the collected fees to. Only can be called by the governance.
  /// @param _feeCollection the new address to send the fees to.
  function setFeeCollection(address _feeCollection) external {
    _onlyGovernance();
    _updateFeeCollection(_feeCollection);
  }

  /// @notice set the management fee in basis points. 1 basis point is 0.01% and 100% is 10000 basis points.
  function setManagementFee(uint256 _managementFee) external {
    _onlyGovernance();
    _updateManagementFee(_managementFee);
  }

  function setGatekeeper(address _gatekeeper) external {
    _onlyGovernance();
    _updateGatekeeper(_gatekeeper);
  }

  function setHealthCheck(address _healthCheck) external {
    _onlyGovernanceOrGatekeeper(governance);
    _updateHealthCheck(_healthCheck);
  }

  /// @notice Activates or deactivates Vault mode where all Strategies go into full withdrawal.
  /// During Emergency Shutdown:
  /// 1. No Users may deposit into the Vault (but may withdraw as usual.)
  /// 2. Governance may not add new Strategies.
  /// 3. Each Strategy must pay back their debt as quickly as reasonable to minimally affect their position.
  /// 4. Only Governance may undo Emergency Shutdown.
  ///
  /// See contract level note for further details.
  ///
  /// This may only be called by governance or the guardian.
  /// @param _active If true, the Vault goes into Emergency Shutdown. If false, the Vault goes back into Normal Operation.
  function setVaultEmergencyShutdown(bool _active) external {
    if (_active) {
      _onlyGovernanceOrGatekeeper(governance);
    } else {
      _onlyGovernance();
    }
    if (emergencyShutdown != _active) {
      emergencyShutdown = _active;
      emit EmergencyShutdown(_active);
    }
  }

  /// @notice Changes the locked profit degradation.
  /// @param _degradation The rate of degradation in percent per second scaled to 1e18.
  function setLockedProfileDegradation(uint256 _degradation) external {
    _onlyGovernance();
    require(_degradation <= DEGRADATION_COEFFICIENT, "!value");
    if (lockedProfitDegradation != _degradation) {
      lockedProfitDegradation = _degradation;
      emit LockedProfitDegradationUpdated(_degradation);
    }
  }

  function setVaultCreator(address _creator) external {
    _onlyGovernanceOrGatekeeper(governance);
    creator = _creator;
  }

  function setDepositLimit(uint256 _limit) external {
    _onlyGovernanceOrGatekeeper(governance);
    _updateDepositLimit(_limit);
  }

  function setAccessManager(address _accessManager) external {
    _onlyGovernanceOrGatekeeper(governance);
    _updateAccessManager(_accessManager);
  }

  function _updateFeeCollection(address _feeCollection) internal {
    require(_feeCollection != address(0), "!input");
    if (feeCollection != _feeCollection) {
      feeCollection = _feeCollection;
      emit FeeCollectionUpdated(_feeCollection);
    }
  }

  function _updateManagementFee(uint256 _managementFee) internal {
    require(_managementFee < MAX_BASIS_POINTS, "!input");
    if (managementFee != _managementFee) {
      managementFee = _managementFee;
      emit ManagementFeeUpdated(_managementFee);
    }
  }

  function _updateHealthCheck(address _healthCheck) internal {
    if (healthCheck != _healthCheck) {
      healthCheck = _healthCheck;
      emit HealthCheckUpdated(_healthCheck);
    }
  }

  function _updateStrategyDataStore(address _strategyDataStore) internal {
    require(_strategyDataStore != address(0), "!input");
    if (strategyDataStore != _strategyDataStore) {
      strategyDataStore = _strategyDataStore;
      emit StrategyDataStoreUpdated(_strategyDataStore);
    }
  }

  function _updateDepositLimit(uint256 _depositLimit) internal {
    if (depositLimit != _depositLimit) {
      depositLimit = _depositLimit;
      emit DepositLimitUpdated(_depositLimit);
    }
  }

  function _updateAccessManager(address _accessManager) internal {
    if (accessManager != _accessManager) {
      accessManager = _accessManager;
      emit AccessManagerUpdated(_accessManager);
    }
  }

  function _updateVaultRewardsContract(address _vaultRewards) internal {
    if (vaultRewards != _vaultRewards) {
      vaultRewards = _vaultRewards;
      emit VaultRewardsContractUpdated(_vaultRewards);
    }
  }
}
