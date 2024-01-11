// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

import "./IAccessControlPolicy.sol";
import "./PerVaultGatekeeper.sol";

/// @notice This contract will allow enable/disable open access to vaults (or the staking contract).
contract AllowAnyAccessControl is IAccessControlPolicy, PerVaultGatekeeper {
  /// @notice Emitted when AllowAny configure is updated for a vault
  event AllowAnyUpdated(address indexed _vault, bool indexed _allow);

  struct Config {
    bool isSet;
    bool allow;
  }

  /// @notice stores if open access is enabled for a vault. By default no values will be set so no vaults are open.
  ///  The address key can either be the address of a vault or the staking contract, and the value will be true if
  mapping(address => Config) internal configurations;

  address internal constant DEFAULT_CONFIG_ID = address(1);

  // solhint-disable-next-line no-empty-blocks
  constructor(address _governance) PerVaultGatekeeper(_governance) {}

  function hasAccess(address _user, address _vault) external view returns (bool) {
    require(_vault != address(0), "!input");
    require(_user != address(0), "!input");
    Config memory c = configurations[_vault];
    if (c.isSet) {
      return c.allow;
    } else {
      return configurations[DEFAULT_CONFIG_ID].allow;
    }
  }

  /// @notice Set the default configuration. Can only be called by governance.
  ///  The default configuration is only used if there is no vault level configuration set.
  /// @param _allowAny set to true will enable open access
  function setDefault(bool _allowAny) external onlyGovernance {
    configurations[DEFAULT_CONFIG_ID].isSet = true;
    configurations[DEFAULT_CONFIG_ID].allow = _allowAny;
    emit AllowAnyUpdated(DEFAULT_CONFIG_ID, _allowAny);
  }

  /// @notice Set the configuration for the given vaults. Will override the default configuration.
  /// @param _vaults the addresses of vaults to set
  /// @param _settings settings for each vault
  function setForVaults(address[] calldata _vaults, bool[] calldata _settings) external {
    require(_vaults.length > 0, "!vaults");
    require(_vaults.length == _settings.length, "!input");
    for (uint256 i = 0; i < _vaults.length; i++) {
      require(_vaults[i] != address(0), "!input");
      _onlyGovernanceOrGatekeeper(_vaults[i]);
      configurations[_vaults[i]].isSet = true;
      configurations[_vaults[i]].allow = _settings[i];
      emit AllowAnyUpdated(_vaults[i], _settings[i]);
    }
  }
}
