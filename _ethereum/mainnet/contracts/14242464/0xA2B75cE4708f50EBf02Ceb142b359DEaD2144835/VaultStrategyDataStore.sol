// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

import "./Context.sol";
import "./ERC165Checker.sol";
import "./IStrategy.sol";
import "./IVaultStrategyDataStore.sol";
import "./IVault.sol";
import "./Governable.sol";

/// @notice This contract will allow governance and managers to configure strategies and withdraw queues for a vault.
///  This contract should be deployed first, and then the address of this contract should be used to deploy a vault.
///  Once the vaults & strategies are deployed, call `addStrategy` function to assign a strategy to a vault.
contract VaultStrategyDataStore is IVaultStrategyDataStore, Context, Governable {
  using ERC165Checker for address;

  /// @notice parameters associated with a strategy
  struct StrategyParams {
    uint256 performanceFee;
    uint256 activation;
    uint256 debtRatio;
    uint256 minDebtPerHarvest;
    uint256 maxDebtPerHarvest;
    address vault;
  }

  struct VaultStrategyConfig {
    // save the vault address in the mapping too to allow us to check if the vaultStrategy is actually created
    // it can also be used to validate if msg.sender if the vault itself
    address vault;
    address manager;
    uint256 totalDebtRatio;
    uint256 maxTotalDebtRatio;
    address[] withdrawQueue;
    address[] strategies;
  }

  event VaultManagerUpdated(address indexed _vault, address indexed _manager);

  event StrategyAdded(
    address indexed _vault,
    address indexed _strategyAddress,
    uint256 _debtRatio,
    uint256 _minDebtPerHarvest,
    uint256 _maxDebtPerHarvest,
    uint256 _performanceFee
  );

  event WithdrawQueueUpdated(address indexed _vault, address[] _queue);
  event StrategyDebtRatioUpdated(address indexed _vault, address indexed _strategy, uint256 _debtRatio);
  event StrategyMinDebtPerHarvestUpdated(address indexed _vault, address indexed _strategy, uint256 _minDebtPerHarvest);
  event StrategyMaxDebtPerHarvestUpdated(address indexed _vault, address indexed _strategy, uint256 _maxDebtPerHarvest);
  event StrategyPerformanceFeeUpdated(address indexed _vault, address indexed _strategy, uint256 _performanceFee);
  event StrategyMigrated(address indexed _vault, address indexed _old, address indexed _new);
  event StrategyRevoked(address indexed _vault, address indexed _strategy);
  event StrategyRemovedFromQueue(address indexed _vault, address indexed _strategy);
  event StrategyAddedToQueue(address indexed _vault, address indexed _strategy);
  event MaxTotalRatioUpdated(address indexed _vault, uint256 _maxTotalDebtRatio);

  /// @notice The maximum basis points. 1 basis point is 0.01% and 100% is 10000 basis points
  uint256 public constant MAX_BASIS_POINTS = 10_000;
  uint256 public constant DEFAULT_MAX_TOTAL_DEBT_RATIO = 9500;
  /// @notice maximum number of strategies allowed for the withdraw queue
  uint256 public constant MAX_STRATEGIES_PER_VAULT = 20;

  /// @notice vaults and their strategy-related configs
  mapping(address => VaultStrategyConfig) internal configs;

  /// @notice vaults and their strategies.
  /// @dev Can't put into the {VaultStrategyConfig} struct because nested mappings can't be constructed
  mapping(address => mapping(address => StrategyParams)) internal strategies;

  // solhint-disable-next-line
  constructor(address _governance) Governable(_governance) {}

  /// @notice returns the performance fee for a strategy in basis points.
  /// @param _vault the address of the vault
  /// @param _strategy the address of the strategy
  /// @return performance fee in basis points (100 = 1%)
  function strategyPerformanceFee(address _vault, address _strategy) external view returns (uint256) {
    require(_vault != address(0) && _strategy != address(0), "invalid address");
    if (_strategyExists(_vault, _strategy)) {
      return strategies[_vault][_strategy].performanceFee;
    } else {
      return 0;
    }
  }

  /// @notice returns the time when a strategy is added to a vault
  /// @param _vault the address of the vault
  /// @param _strategy the address of the strategy
  /// @return the time when the strategy is added to the vault. 0 means the strategy is not added to the vault.
  function strategyActivation(address _vault, address _strategy) external view returns (uint256) {
    require(_vault != address(0) && _strategy != address(0), "invalid address");
    if (_strategyExists(_vault, _strategy)) {
      return strategies[_vault][_strategy].activation;
    } else {
      return 0;
    }
  }

  /// @notice returns the debt ratio for a strategy in basis points.
  /// @param _vault the address of the vault
  /// @param _strategy the address of the strategy
  /// @return debt ratio in basis points (100 = 1%). Total debt ratio of all strategies for a vault can not exceed the MaxTotalDebtRatio of the vault.
  function strategyDebtRatio(address _vault, address _strategy) external view returns (uint256) {
    require(_vault != address(0) && _strategy != address(0), "invalid address");
    if (_strategyExists(_vault, _strategy)) {
      return strategies[_vault][_strategy].debtRatio;
    } else {
      return 0;
    }
  }

  /// @notice returns the minimum value that the strategy can borrow from the vault per harvest.
  /// @param _vault the address of the vault
  /// @param _strategy the address of the strategy
  /// @return minimum value the strategy should borrow from the vault per harvest
  function strategyMinDebtPerHarvest(address _vault, address _strategy) external view returns (uint256) {
    require(_vault != address(0) && _strategy != address(0), "invalid address");
    if (_strategyExists(_vault, _strategy)) {
      return strategies[_vault][_strategy].minDebtPerHarvest;
    } else {
      return 0;
    }
  }

  /// @notice returns the maximum value that the strategy can borrow from the vault per harvest.
  /// @param _vault the address of the vault
  /// @param _strategy the address of the strategy
  /// @return maximum value the strategy should borrow from the vault per harvest
  function strategyMaxDebtPerHarvest(address _vault, address _strategy) external view returns (uint256) {
    require(_vault != address(0) && _strategy != address(0), "invalid address");
    if (_strategyExists(_vault, _strategy)) {
      return strategies[_vault][_strategy].maxDebtPerHarvest;
    } else {
      return type(uint256).max;
    }
  }

  /// @notice returns the total debt ratio of all the strategies for the vault in basis points
  /// @param _vault the address of the vault
  /// @return the total debt ratio of all the strategies. Should never exceed the value of MaxTotalDebtRatio
  function vaultTotalDebtRatio(address _vault) external view returns (uint256) {
    require(_vault != address(0), "invalid vault");
    if (_vaultExists(_vault)) {
      return configs[_vault].totalDebtRatio;
    } else {
      return 0;
    }
  }

  /// @notice returns the address of strategies that will be withdrawn from if the vault needs to withdraw
  /// @param _vault the address of the vault
  /// @return the address of strategies for withdraw. First strategies in the queue will be withdrawn first.
  function withdrawQueue(address _vault) external view returns (address[] memory) {
    require(_vault != address(0), "invalid vault");
    if (_vaultExists(_vault)) {
      return configs[_vault].withdrawQueue;
    } else {
      return new address[](0);
    }
  }

  /// @notice returns the manager address of the vault. Could be address(0) if it's not set
  /// @param _vault the address of the vault
  /// @return the manager address of the vault
  function vaultManager(address _vault) external view returns (address) {
    require(_vault != address(0), "invalid vault");
    if (_vaultExists(_vault)) {
      return configs[_vault].manager;
    } else {
      return address(0);
    }
  }

  /// @notice returns the maxTotalDebtRatio of the vault in basis points. It limits the maximum amount of funds that all strategies of the value can borrow.
  /// @param _vault the address of the vault
  /// @return the maxTotalDebtRatio config of the vault
  function vaultMaxTotalDebtRatio(address _vault) external view returns (uint256) {
    require(_vault != address(0), "invalid vault");
    if (_vaultExists(_vault)) {
      return configs[_vault].maxTotalDebtRatio;
    } else {
      return DEFAULT_MAX_TOTAL_DEBT_RATIO;
    }
  }

  /// @notice returns the list of strategies used by the vault. Use `strategyDebtRatio` to query fund allocation for a strategy.
  /// @param _vault the address of the vault
  /// @return the strategies of the vault
  function vaultStrategies(address _vault) external view returns (address[] memory) {
    require(_vault != address(0), "invalid vault");
    if (_vaultExists(_vault)) {
      return configs[_vault].strategies;
    } else {
      return new address[](0);
    }
  }

  /// @notice set the manager of the vault. Can only be called by the governance.
  /// @param _vault the address of the vault
  /// @param _manager the address of the manager for the vault
  function setVaultManager(address _vault, address _manager) external onlyGovernance {
    require(_vault != address(0), "invalid vault");
    _initConfigsIfNeeded(_vault);
    if (configs[_vault].manager != _manager) {
      configs[_vault].manager = _manager;
      emit VaultManagerUpdated(_vault, _manager);
    }
  }

  /// @notice set the maxTotalDebtRatio of the value.
  /// @param _vault the address of the vault
  /// @param _maxTotalDebtRatio the maximum total debt ratio value in basis points. Can not exceed 10000 (100%).
  function setMaxTotalDebtRatio(address _vault, uint256 _maxTotalDebtRatio) external {
    require(_vault != address(0), "invalid vault");
    _onlyGovernanceOrVaultManager(_vault);
    require(_maxTotalDebtRatio <= MAX_BASIS_POINTS, "invalid value");
    _initConfigsIfNeeded(_vault);
    if (configs[_vault].maxTotalDebtRatio != _maxTotalDebtRatio) {
      configs[_vault].maxTotalDebtRatio = _maxTotalDebtRatio;
      emit MaxTotalRatioUpdated(_vault, _maxTotalDebtRatio);
    }
  }

  /// @notice add the given strategy to the vault
  /// @param _vault the address of the vault to add strategy to
  /// @param _strategy the address of the strategy contract
  /// @param _debtRatio the percentage of the asset in the vault that will be allocated to the strategy, in basis points (1 BP is 0.01%).
  /// @param _minDebtPerHarvest lower limit on the increase of debt since last harvest
  /// @param _maxDebtPerHarvest upper limit on the increase of debt since last harvest
  /// @param _performanceFee the fee that the strategist will receive based on the strategy's performance. In basis points.
  function addStrategy(
    address _vault,
    address _strategy,
    uint256 _debtRatio,
    uint256 _minDebtPerHarvest,
    uint256 _maxDebtPerHarvest,
    uint256 _performanceFee
  ) external {
    _onlyGovernanceOrVaultManager(_vault);
    require(_strategy != address(0), "strategy address is not valid");
    require(_strategy.supportsInterface(type(IStrategy).interfaceId), "!strategy");
    _initConfigsIfNeeded(_vault);
    require(configs[_vault].withdrawQueue.length < MAX_STRATEGIES_PER_VAULT, "too many strategies");
    require(strategies[_vault][_strategy].activation == 0, "strategy already added");
    if (IStrategy(_strategy).vault() != address(0)) {
      require(IStrategy(_strategy).vault() == _vault, "wrong vault");
    }
    require(_minDebtPerHarvest <= _maxDebtPerHarvest, "invalid minDebtPerHarvest value");
    require(
      configs[_vault].totalDebtRatio + _debtRatio <= configs[_vault].maxTotalDebtRatio,
      "total debtRatio over limit"
    );
    require(_performanceFee <= MAX_BASIS_POINTS / 2, "invalid performance fee");

    /* solhint-disable not-rely-on-time */
    strategies[_vault][_strategy] = StrategyParams({
      performanceFee: _performanceFee,
      activation: block.timestamp,
      debtRatio: _debtRatio,
      minDebtPerHarvest: _minDebtPerHarvest,
      maxDebtPerHarvest: _maxDebtPerHarvest,
      vault: _vault
    });
    /* solhint-enable */

    require(IVault(_vault).addStrategy(_strategy), "vault error");
    if (IStrategy(_strategy).vault() == address(0)) {
      IStrategy(_strategy).setVault(_vault);
    }

    emit StrategyAdded(_vault, _strategy, _debtRatio, _minDebtPerHarvest, _maxDebtPerHarvest, _performanceFee);
    configs[_vault].totalDebtRatio += _debtRatio;
    configs[_vault].withdrawQueue.push(_strategy);
    configs[_vault].strategies.push(_strategy);
  }

  /// @notice update the performance fee of the given strategy
  /// @param _vault the address of the vault
  /// @param _strategy the address of the strategy contract
  /// @param _performanceFee the new performance fee in basis points
  function updateStrategyPerformanceFee(
    address _vault,
    address _strategy,
    uint256 _performanceFee
  ) external onlyGovernance {
    _validateVaultExists(_vault); //the strategy should be added already means the vault should exist
    _validateStrategy(_vault, _strategy);
    require(_performanceFee <= MAX_BASIS_POINTS / 2, "invalid performance fee");
    strategies[_vault][_strategy].performanceFee = _performanceFee;
    emit StrategyPerformanceFeeUpdated(_vault, _strategy, _performanceFee);
  }

  /// @notice update the debt ratio for the given strategy
  /// @param _vault the address of the vault
  /// @param _strategy the address of the strategy contract
  /// @param _debtRatio the new debt ratio of the strategy in basis points
  function updateStrategyDebtRatio(
    address _vault,
    address _strategy,
    uint256 _debtRatio
  ) external {
    _validateVaultExists(_vault);
    // This could be called by the Vault itself to update the debt ratio when a strategy is not performing well
    _onlyAdminOrVault(_vault);
    _validateStrategy(_vault, _strategy);
    _updateStrategyDebtRatio(_vault, _strategy, _debtRatio);
  }

  /// @notice update the minDebtHarvest for the given strategy
  /// @param _vault the address of the vault
  /// @param _strategy the address of the strategy contract
  /// @param _minDebtPerHarvest the new minDebtPerHarvest value
  function updateStrategyMinDebtHarvest(
    address _vault,
    address _strategy,
    uint256 _minDebtPerHarvest
  ) external {
    _validateVaultExists(_vault);
    _onlyGovernanceOrVaultManager(_vault);
    _validateStrategy(_vault, _strategy);
    require(strategies[_vault][_strategy].maxDebtPerHarvest >= _minDebtPerHarvest, "invalid minDebtPerHarvest");
    strategies[_vault][_strategy].minDebtPerHarvest = _minDebtPerHarvest;
    emit StrategyMinDebtPerHarvestUpdated(_vault, _strategy, _minDebtPerHarvest);
  }

  /// @notice update the maxDebtHarvest for the given strategy
  /// @param _vault the address of the vault
  /// @param _strategy the address of the strategy contract
  /// @param _maxDebtPerHarvest the new maxDebtPerHarvest value
  function updateStrategyMaxDebtHarvest(
    address _vault,
    address _strategy,
    uint256 _maxDebtPerHarvest
  ) external {
    _validateVaultExists(_vault);
    _onlyGovernanceOrVaultManager(_vault);
    _validateStrategy(_vault, _strategy);
    require(strategies[_vault][_strategy].minDebtPerHarvest <= _maxDebtPerHarvest, "invalid maxDebtPerHarvest");
    strategies[_vault][_strategy].maxDebtPerHarvest = _maxDebtPerHarvest;
    emit StrategyMaxDebtPerHarvestUpdated(_vault, _strategy, _maxDebtPerHarvest);
  }

  /// @notice updates the withdrawalQueue to match the addresses and order specified by `queue`.
  ///  There can be fewer strategies than the maximum, as well as fewer than
  ///  the total number of strategies active in the vault.
  ///  This may only be called by governance or management.
  /// @dev This is order sensitive, specify the addresses in the order in which
  ///  funds should be withdrawn (so `queue`[0] is the first Strategy withdrawn
  ///  from, `queue`[1] is the second, etc.)
  ///  This means that the least impactful Strategy (the Strategy that will have
  ///  its core positions impacted the least by having funds removed) should be
  ///  at `queue`[0], then the next least impactful at `queue`[1], and so on.
  /// @param _vault the address of the vault
  /// @param _queue The array of addresses to use as the new withdrawal queue. This is order sensitive.
  function setWithdrawQueue(address _vault, address[] calldata _queue) external {
    require(_vault != address(0), "invalid vault");
    require(_queue.length <= MAX_STRATEGIES_PER_VAULT, "invalid queue size");
    _onlyGovernanceOrVaultManager(_vault);
    _initConfigsIfNeeded(_vault);
    address[] storage withdrawQueue_ = configs[_vault].withdrawQueue;
    uint256 oldQueueSize = withdrawQueue_.length;
    for (uint256 i = 0; i < _queue.length; i++) {
      address temp = _queue[i];
      require(strategies[_vault][temp].activation > 0, "invalid queue");
      if (i > withdrawQueue_.length - 1) {
        withdrawQueue_.push(temp);
      } else {
        withdrawQueue_[i] = temp;
      }
    }
    if (oldQueueSize > _queue.length) {
      for (uint256 j = oldQueueSize; j > _queue.length; j--) {
        withdrawQueue_.pop();
      }
    }
    emit WithdrawQueueUpdated(_vault, _queue);
  }

  /// @notice add the strategy to the `withdrawQueue`
  /// @dev the strategy will only be appended to the `withdrawQueue`
  /// @param _vault the address of the vault
  /// @param _strategy the strategy to add
  function addStrategyToWithdrawQueue(address _vault, address _strategy) external {
    _validateVaultExists(_vault);
    _onlyGovernanceOrVaultManager(_vault);
    _validateStrategy(_vault, _strategy);
    VaultStrategyConfig storage config_ = configs[_vault];
    require(config_.withdrawQueue.length + 1 <= MAX_STRATEGIES_PER_VAULT, "too many strategies");
    for (uint256 i = 0; i < config_.withdrawQueue.length; i++) {
      require(config_.withdrawQueue[i] != _strategy, "strategy already exist");
    }
    config_.withdrawQueue.push(_strategy);
    emit StrategyAddedToQueue(_vault, _strategy);
  }

  /// @notice remove the strategy from the `withdrawQueue`
  /// @dev we don't do this with revokeStrategy because it should still be possible to withdraw from the Strategy if it's unwinding.
  /// @param _vault the address of the vault
  /// @param _strategy the strategy to remove
  function removeStrategyFromWithdrawQueue(address _vault, address _strategy) external {
    _validateVaultExists(_vault);
    _onlyGovernanceOrVaultManager(_vault);
    _validateStrategy(_vault, _strategy);
    VaultStrategyConfig storage config_ = configs[_vault];
    uint256 i = 0;
    for (i = 0; i < config_.withdrawQueue.length; i++) {
      if (config_.withdrawQueue[i] == _strategy) {
        break;
      }
    }
    require(i < config_.withdrawQueue.length, "strategy does not exist");
    for (uint256 j = i; j < config_.withdrawQueue.length - 1; j++) {
      config_.withdrawQueue[j] = config_.withdrawQueue[j + 1];
    }
    config_.withdrawQueue.pop();
    emit StrategyRemovedFromQueue(_vault, _strategy);
  }

  /// @notice Migrate a Strategy, including all assets from `oldVersion` to `newVersion`. This may only be called by governance.
  /// @dev Strategy must successfully migrate all capital and positions to new Strategy, or else this will upset the balance of the Vault.
  ///  The new Strategy should be "empty" e.g. have no prior commitments to
  ///  this Vault, otherwise it could have issues.
  /// @param _vault the address of the vault
  /// @param _oldStrategy the existing strategy to migrate from
  /// @param _newStrategy the new strategy to migrate to
  function migrateStrategy(
    address _vault,
    address _oldStrategy,
    address _newStrategy
  ) external onlyGovernance {
    _validateVaultExists(_vault);
    _validateStrategy(_vault, _oldStrategy);
    require(_newStrategy != address(0), "invalid new strategy");
    require(strategies[_vault][_newStrategy].activation == 0, "new strategy already exists");
    require(_newStrategy.supportsInterface(type(IStrategy).interfaceId), "!strategy");

    StrategyParams memory params = strategies[_vault][_oldStrategy];
    _revokeStrategy(_vault, _oldStrategy);
    // _revokeStrategy will reduce the debt ratio
    configs[_vault].totalDebtRatio += params.debtRatio;
    //vs_.strategies[_oldStrategy].totalDebt = 0;

    strategies[_vault][_newStrategy] = StrategyParams({
      performanceFee: params.performanceFee,
      activation: params.activation,
      debtRatio: params.debtRatio,
      minDebtPerHarvest: params.minDebtPerHarvest,
      maxDebtPerHarvest: params.maxDebtPerHarvest,
      vault: params.vault
    });

    require(IVault(_vault).migrateStrategy(_oldStrategy, _newStrategy), "vault error");
    emit StrategyMigrated(_vault, _oldStrategy, _newStrategy);
    for (uint256 i = 0; i < configs[_vault].withdrawQueue.length; i++) {
      if (configs[_vault].withdrawQueue[i] == _oldStrategy) {
        configs[_vault].withdrawQueue[i] = _newStrategy;
      }
    }
    for (uint256 j = 0; j < configs[_vault].strategies.length; j++) {
      if (configs[_vault].strategies[j] == _oldStrategy) {
        configs[_vault].strategies[j] = _newStrategy;
      }
    }
  }

  /// @notice Revoke a Strategy, setting its debt limit to 0 and preventing any future deposits.
  ///  This function should only be used in the scenario where the Strategy is
  ///  being retired but no migration of the positions are possible, or in the
  ///  extreme scenario that the Strategy needs to be put into "Emergency Exit"
  ///  mode in order for it to exit as quickly as possible. The latter scenario
  ///  could be for any reason that is considered "critical" that the Strategy
  ///  exits its position as fast as possible, such as a sudden change in market
  ///  conditions leading to losses, or an imminent failure in an external
  ///  dependency.
  ///  This may only be called by governance, or the manager.
  ///
  /// @param _vault the address of the vault
  /// @param _strategy The Strategy to revoke.
  function revokeStrategy(address _vault, address _strategy) external {
    _onlyGovernanceOrVaultManager(_vault);
    if (strategies[_vault][_strategy].debtRatio != 0) {
      _revokeStrategy(_vault, _strategy);
    }
  }

  /// @notice Note that a Strategy will only revoke itself during emergency shutdown.
  ///  This function will be invoked the strategy by itself.
  ///  The Strategy will call the vault first and the vault will then forward the request to this contract.
  ///  This is to keep the Strategy interface compatible with Yearn's
  ///  This should only be called by the vault itself.
  /// @param _strategy the address of the strategy to revoke
  function revokeStrategyByStrategy(address _strategy) external {
    _validateVaultExists(_msgSender());
    _validateStrategy(_msgSender(), _strategy);
    if (strategies[_msgSender()][_strategy].debtRatio != 0) {
      _revokeStrategy(_msgSender(), _strategy);
    }
  }

  function _vaultExists(address _vault) internal view returns (bool) {
    if (configs[_vault].vault == _vault) {
      return true;
    }
    return false;
  }

  function _strategyExists(address _vault, address _strategy) internal view returns (bool) {
    if (strategies[_vault][_strategy].vault == _vault) {
      return true;
    }
    return false;
  }

  function _initConfigsIfNeeded(address _vault) internal {
    if (configs[_vault].vault != _vault) {
      configs[_vault] = VaultStrategyConfig({
        vault: _vault,
        manager: address(0),
        maxTotalDebtRatio: DEFAULT_MAX_TOTAL_DEBT_RATIO,
        totalDebtRatio: 0,
        withdrawQueue: new address[](0),
        strategies: new address[](0)
      });
    }
  }

  function _validateVaultExists(address _vault) internal view {
    require(_vault != address(0), "invalid vault");
    require(configs[_vault].vault == _vault, "no vault");
  }

  function _validateStrategy(address _vault, address _strategy) internal view {
    require(strategies[_vault][_strategy].activation > 0, "invalid strategy");
  }

  /// @dev make sure the vault exists and msg.send is either the governance or the manager of the vault
  ///   could be an modifier as well, but using internal functions to reduce the code size
  function _onlyGovernanceOrVaultManager(address _vault) internal view {
    require((governance == _msgSender()) || (configs[_vault].manager == _msgSender()), "not authorised");
  }

  function _onlyAdminOrVault(address _vault) internal view {
    require(
      (governance == _msgSender()) ||
        (configs[_vault].manager == _msgSender()) ||
        (configs[_msgSender()].vault == _vault),
      "not authorised"
    );
  }

  function _updateStrategyDebtRatio(
    address _vault,
    address _strategy,
    uint256 _debtRatio
  ) internal {
    VaultStrategyConfig storage config_ = configs[_vault];
    config_.totalDebtRatio = config_.totalDebtRatio - (strategies[_vault][_strategy].debtRatio);
    strategies[_vault][_strategy].debtRatio = _debtRatio;
    config_.totalDebtRatio = config_.totalDebtRatio + _debtRatio;
    require(config_.totalDebtRatio <= config_.maxTotalDebtRatio, "debtRatio over limit");
    emit StrategyDebtRatioUpdated(_vault, _strategy, _debtRatio);
  }

  function _revokeStrategy(address _vault, address _strategy) internal {
    configs[_vault].totalDebtRatio = configs[_vault].totalDebtRatio - strategies[_vault][_strategy].debtRatio;
    strategies[_vault][_strategy].debtRatio = 0;
    emit StrategyRevoked(_vault, _strategy);
  }
}
