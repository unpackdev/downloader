// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;
pragma abicoder v2;

import "./draft-ERC20PermitUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./Math.sol";
import "./IStrategy.sol";
import "./IVaultStrategyDataStore.sol";
import "./IYOPRewards.sol";
import "./VaultMetaDataStore.sol";

import "./IVault.sol";

/// @dev This contract is marked abstract to avoid being used directly.
///  NOTE: do not add any new state variables to this contract. If needed, see {VaultDataStorage.sol} instead.
abstract contract BaseVault is ERC20PermitUpgradeable, VaultMetaDataStore {
  using SafeERC20Upgradeable for IERC20Upgradeable;

  event StrategyAdded(address indexed _strategy);
  event StrategyMigrated(address indexed _oldVersion, address indexed _newVersion);
  event StrategyRevoked(address indexed _strategy);

  // solhint-disable-next-line no-empty-blocks
  constructor() {}

  // solhint-disable-next-line
  function __BaseVault__init_unchained() internal {}

  // solhint-disable-next-line func-name-mixedcase
  function __BaseVault__init(
    string memory _name,
    string memory _symbol,
    address _governance,
    address _gatekeeper,
    address _feeCollection,
    address _strategyDataStoreAddress,
    address _accessManager,
    address _vaultRewards
  ) internal {
    __ERC20_init(_name, _symbol);
    __ERC20Permit_init(_name);
    __VaultMetaDataStore_init(
      _governance,
      _gatekeeper,
      _feeCollection,
      _strategyDataStoreAddress,
      _accessManager,
      _vaultRewards
    );
    __BaseVault__init_unchained();
  }

  /// @notice returns decimals value of the vault
  function decimals() public view override returns (uint8) {
    return vaultDecimals;
  }

  /// @notice Init a new strategy. This should only be called by the {VaultStrategyDataStore} and should not be invoked manually.
  ///   Use {VaultStrategyDataStore.addStrategy} to manually add a strategy to a Vault.
  /// @dev This will be called by the {VaultStrategyDataStore} when a strategy is added to a given Vault.
  function addStrategy(address _strategy) external virtual returns (bool) {
    _onlyNotEmergencyShutdown();
    _onlyStrategyDataStore();
    return _addStrategy(_strategy);
  }

  /// @notice Migrate a new strategy. This should only be called by the {VaultStrategyDataStore} and should not be invoked manually.
  ///   Use {VaultStrategyDataStore.migrateStrategy} to manually migrate a strategy for a Vault.
  /// @dev This will called be the {VaultStrategyDataStore} when a strategy is migrated.
  ///  This will then call the strategy to migrate (as the strategy only allows the vault to call the migrate function).
  function migrateStrategy(address _oldVersion, address _newVersion) external virtual returns (bool) {
    _onlyStrategyDataStore();
    return _migrateStrategy(_oldVersion, _newVersion);
  }

  /// @notice called by the strategy to revoke itself. Should not be called by any other means.
  ///  Use {VaultStrategyDataStore.revokeStrategy} to revoke a strategy manually.
  /// @dev The strategy could talk to the {VaultStrategyDataStore} directly when revoking itself.
  ///  However, that means we will need to change the interfaces to Strategies and make them incompatible with Yearn's strategies.
  ///  To avoid that, the strategies will continue talking to the Vault and the Vault will then let the {VaultStrategyDataStore} know.
  function revokeStrategy() external {
    _validateStrategy(_msgSender());
    _strategyDataStore().revokeStrategyByStrategy(_msgSender());
    emit StrategyRevoked(_msgSender());
  }

  function strategy(address _strategy) external view returns (StrategyInfo memory) {
    return strategies[_strategy];
  }

  function strategyDebtRatio(address _strategy) external view returns (uint256) {
    return _strategyDataStore().strategyDebtRatio(address(this), _strategy);
  }

  /// @dev It doesn't inherit openzepplin's ERC165 implementation to save on contract size
  ///  but it is compatible with ERC165
  function supportsInterface(bytes4 _interfaceId) external view virtual returns (bool) {
    // 0x01ffc9a7 is the interfaceId of IERC165 itself
    return _interfaceId == type(IVault).interfaceId || _interfaceId == 0x01ffc9a7;
  }

  /// @dev This is called when tokens are minted, transferred or burned by the ERC20 implementation from openzeppelin
  // solhint-disable-next-line no-unused-vars
  function _beforeTokenTransfer(
    address _from,
    address _to,
    uint256
  ) internal override {
    if (_from == address(0)) {
      // this is a mint event, track block time for the account
      dt[_to] = block.number;
    } else {
      // this is a transfer or burn event, make sure it is at least 1 block later from deposit to prevent flash loan
      // this will cause a small issue that if a user minted some tokens before, and then mint some more and withdraw (burn) or transfer previously minted tokens in the same block, this will fail.
      // But it should not be a issue for majority of users and it does prevent flash loan
      require(block.number > dt[_from], "!block");
    }
    if (vaultRewards != address(0)) {
      if (_from != address(0)) {
        IYOPRewards(vaultRewards).calculateVaultRewards(_from);
      }
      if (_to != address(0)) {
        IYOPRewards(vaultRewards).calculateVaultRewards(_to);
      }
    }
  }

  function _strategyDataStore() internal view returns (IVaultStrategyDataStore) {
    return IVaultStrategyDataStore(strategyDataStore);
  }

  function _onlyStrategyDataStore() internal view {
    require(_msgSender() == strategyDataStore, "!strategyStore");
  }

  /// @dev ensure the vault is not in emergency shutdown mode
  function _onlyNotEmergencyShutdown() internal view {
    require(emergencyShutdown == false, "emergency shutdown");
  }

  function _validateStrategy(address _strategy) internal view {
    require(strategies[_strategy].activation > 0, "!strategy");
  }

  function _addStrategy(address _strategy) internal returns (bool) {
    /* solhint-disable not-rely-on-time */
    strategies[_strategy] = StrategyInfo({
      activation: block.timestamp,
      lastReport: block.timestamp,
      totalDebt: 0,
      totalGain: 0,
      totalLoss: 0
    });
    emit StrategyAdded(_strategy);
    return true;
    /* solhint-enable */
  }

  function _migrateStrategy(address _oldVersion, address _newVersion) internal returns (bool) {
    StrategyInfo memory info = strategies[_oldVersion];
    strategies[_oldVersion].totalDebt = 0;
    strategies[_newVersion] = StrategyInfo({
      activation: info.activation,
      lastReport: info.lastReport,
      totalDebt: info.totalDebt,
      totalGain: 0,
      totalLoss: 0
    });
    IStrategy(_oldVersion).migrate(_newVersion);
    emit StrategyMigrated(_oldVersion, _newVersion);
    return true;
  }

  function _sweep(
    address _token,
    uint256 _amount,
    address _to
  ) internal {
    IERC20Upgradeable token_ = IERC20Upgradeable(_token);
    _amount = Math.min(_amount, token_.balanceOf(address(this)));
    token_.safeTransfer(_to, _amount);
  }
}
