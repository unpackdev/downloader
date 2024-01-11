// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;
pragma abicoder v2;

import "./Math.sol";
import "./ERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./BaseVault.sol";
import "./VaultUtils.sol";

///  @dev NOTE: do not add any new state variables to this contract. If needed, see {VaultDataStorage.sol} instead.
abstract contract SingleAssetVaultBase is BaseVault {
  using SafeERC20Upgradeable for IERC20Upgradeable;

  // solhint-disable-next-line no-empty-blocks
  constructor() {}

  // solhint-disable-next-line func-name-mixedcase
  function __SingleAssetVaultBase_init_unchained(address _token) internal {
    require(_token != address(0), "!token");
    token = IERC20Upgradeable(_token);
    // the vault decimals need to match the tokens to avoid any conversion
    vaultDecimals = ERC20Upgradeable(address(token)).decimals();
  }

  // solhint-disable-next-line func-name-mixedcase
  function __SingleAssetVaultBase_init(
    string memory _name,
    string memory _symbol,
    address _governance,
    address _gatekeeper,
    address _feeCollection,
    address _strategyDataStoreAddress,
    address _token,
    address _accessManager,
    address _vaultRewards
  ) internal {
    __BaseVault__init(
      _name,
      _symbol,
      _governance,
      _gatekeeper,
      _feeCollection,
      _strategyDataStoreAddress,
      _accessManager,
      _vaultRewards
    );
    __SingleAssetVaultBase_init_unchained(_token);
  }

  /// @notice Returns the total quantity of all assets under control of this
  ///   Vault, whether they're loaned out to a Strategy, or currently held in
  ///   the Vault.
  /// @return The total assets under control of this Vault.
  function totalAsset() external view returns (uint256) {
    return _totalAsset();
  }

  /// @notice the remaining amount of underlying tokens that still can be deposited into the vault before reaching the limit
  function availableDepositLimit() external view returns (uint256) {
    return _availableDepositLimit();
  }

  /// @notice Determines the maximum quantity of shares this Vault can facilitate a
  ///  withdrawal for, factoring in assets currently residing in the Vault,
  ///  as well as those deployed to strategies on the Vault's balance sheet.
  /// @dev Regarding how shares are calculated, see dev note on `deposit`.
  ///  If you want to calculated the maximum a user could withdraw up to,
  ///  you want to use this function.
  /// Note that the amount provided by this function is the theoretical
  ///  maximum possible from withdrawing, the real amount depends on the
  ///  realized losses incurred during withdrawal.
  /// @return The total quantity of shares this Vault can provide.
  function maxAvailableShares() external view returns (uint256) {
    return _maxAvailableShares();
  }

  /// @notice Gives the price for a single Vault share.
  /// @dev See dev note on `withdraw`.
  /// @return The value of a single share.
  function pricePerShare() external view returns (uint256) {
    return _shareValue(10**vaultDecimals);
  }

  /// @notice Determines if `_strategy` is past its debt limit and if any tokens
  ///  should be withdrawn to the Vault.
  /// @param _strategy The Strategy to check.
  /// @return The quantity of tokens to withdraw.
  function debtOutstanding(address _strategy) external view returns (uint256) {
    return _debtOutstanding(_strategy);
  }

  /// @notice Amount of tokens in Vault a Strategy has access to as a credit line.
  ///  This will check the Strategy's debt limit, as well as the tokens
  ///  available in the Vault, and determine the maximum amount of tokens
  ///  (if any) the Strategy may draw on.
  /// In the rare case the Vault is in emergency shutdown this will return 0.
  /// @param _strategy The Strategy to check.
  /// @return The quantity of tokens available for the Strategy to draw on.
  function creditAvailable(address _strategy) external view returns (uint256) {
    return _creditAvailable(_strategy);
  }

  /// @notice Provide an accurate expected value for the return this `strategy`
  /// would provide to the Vault the next time `report()` is called
  /// (since the last time it was called).
  /// @param _strategy The Strategy to determine the expected return for.
  /// @return The anticipated amount `strategy` should make on its investment since its last report.
  function expectedReturn(address _strategy) external view returns (uint256) {
    return _expectedReturn(_strategy);
  }

  /// @notice send the tokens that are not managed by the vault to the governance
  /// @param _token the token to send
  /// @param _amount the amount of tokens to send
  function sweep(address _token, uint256 _amount) external {
    _onlyGovernance();
    require(address(token) != _token, "!token");
    _sweep(_token, _amount, governance);
  }

  function _totalAsset() internal view returns (uint256) {
    return token.balanceOf(address(this)) + totalDebt;
  }

  function _availableDepositLimit() internal view returns (uint256) {
    return depositLimit > _totalAsset() ? depositLimit - _totalAsset() : 0;
  }

  function _shareValue(uint256 _sharesAmount) internal view returns (uint256) {
    uint256 supply = totalSupply();
    // if the value is empty then the price is 1:1
    return supply == 0 ? _sharesAmount : (_sharesAmount * _freeFunds()) / supply;
  }

  function _calculateLockedProfit() internal view returns (uint256) {
    // solhint-disable-next-line not-rely-on-time
    uint256 lockedFundRatio = (block.timestamp - lastReport) * lockedProfitDegradation;
    return
      lockedFundRatio < DEGRADATION_COEFFICIENT
        ? lockedProfit - (lockedFundRatio * lockedProfit) / DEGRADATION_COEFFICIENT
        : 0;
  }

  function _freeFunds() internal view returns (uint256) {
    return _totalAsset() - _calculateLockedProfit();
  }

  function _sharesForAmount(uint256 _amount) internal view returns (uint256) {
    uint256 freeFunds_ = _freeFunds();
    return freeFunds_ > 0 ? (_amount * totalSupply()) / freeFunds_ : 0;
  }

  function _maxAvailableShares() internal view returns (uint256) {
    uint256 shares_ = _sharesForAmount(token.balanceOf(address(this)));
    address[] memory withdrawQueue = _strategyDataStore().withdrawQueue(address(this));
    for (uint256 i = 0; i < withdrawQueue.length; i++) {
      shares_ = shares_ + _sharesForAmount(strategies[withdrawQueue[i]].totalDebt);
    }
    return shares_;
  }

  function _debtOutstanding(address _strategy) internal view returns (uint256) {
    _validateStrategy(_strategy);
    return VaultUtils.debtOutstanding(emergencyShutdown, _totalAsset(), _strategyDataStore(), strategies, _strategy);
  }

  function _creditAvailable(address _strategy) internal view returns (uint256) {
    if (emergencyShutdown) {
      return 0;
    }
    _validateStrategy(_strategy);
    return VaultUtils.creditAvailable(token, _totalAsset(), totalDebt, _strategyDataStore(), strategies, _strategy);
  }

  function _expectedReturn(address _strategy) internal view returns (uint256) {
    _validateStrategy(_strategy);
    return VaultUtils.expectedReturn(strategies, _strategy);
  }
}
