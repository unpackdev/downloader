// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

import "./Ownable.sol";
import "./IAccessControlPolicy.sol";
import "./Governable.sol";
import "./PerVaultGatekeeper.sol";

contract AllowlistAccessControl is IAccessControlPolicy, PerVaultGatekeeper {
  mapping(address => bool) public globalAccessMap;
  mapping(address => mapping(address => bool)) public vaultAccessMap;

  event GlobalAccessGranted(address indexed _user);
  event GlobalAccessRemoved(address indexed _user);
  event VaultAccessGranted(address indexed _user, address indexed _vault);
  event VaultAccessRemoved(address indexed _user, address indexed _vault);

  // solhint-disable-next-line no-empty-blocks
  constructor(address _governance) PerVaultGatekeeper(_governance) {}

  function allowGlobalAccess(address[] calldata _users) external onlyGovernance {
    _updateGlobalAccess(_users, true);
  }

  function removeGlobalAccess(address[] calldata _users) external onlyGovernance {
    _updateGlobalAccess(_users, false);
  }

  function allowVaultAccess(address[] calldata _users, address _vault) external {
    _onlyGovernanceOrGatekeeper(_vault);
    _updateAllowVaultAccess(_users, _vault, true);
  }

  function removeVaultAccess(address[] calldata _users, address _vault) external {
    _onlyGovernanceOrGatekeeper(_vault);
    _updateAllowVaultAccess(_users, _vault, false);
  }

  function _hasAccess(address _user, address _vault) internal view returns (bool) {
    require(_user != address(0), "invalid user address");
    require(_vault != address(0), "invalid vault address");
    return globalAccessMap[_user] || vaultAccessMap[_user][_vault];
  }

  function hasAccess(address _user, address _vault) external view returns (bool) {
    return _hasAccess(_user, _vault);
  }

  /// @dev updates the users global access
  function _updateGlobalAccess(address[] calldata _users, bool _permission) internal {
    for (uint256 i = 0; i < _users.length; i++) {
      require(_users[i] != address(0), "invalid address");
      /// @dev only update mappign if permissions are changed
      if (globalAccessMap[_users[i]] != _permission) {
        globalAccessMap[_users[i]] = _permission;
        if (_permission) {
          emit GlobalAccessGranted(_users[i]);
        } else {
          emit GlobalAccessRemoved(_users[i]);
        }
      }
    }
  }

  function _updateAllowVaultAccess(
    address[] calldata _users,
    address _vault,
    bool _permission
  ) internal {
    for (uint256 i = 0; i < _users.length; i++) {
      require(_users[i] != address(0), "invalid user address");
      if (vaultAccessMap[_users[i]][_vault] != _permission) {
        vaultAccessMap[_users[i]][_vault] = _permission;
        if (_permission) {
          emit VaultAccessGranted(_users[i], _vault);
        } else {
          emit VaultAccessRemoved(_users[i], _vault);
        }
      }
    }
  }
}
