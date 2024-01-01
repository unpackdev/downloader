// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./Ownable.sol";

import "./IAdminBeaconUpgradeable.sol";

contract UseAdminBeacon is Ownable {

  /// @notice Emitted when a non-admin tries to call an admin function
  error OnlyAdmin();

  error OnlyAdminOrOwner();

  IAdminBeaconUpgradeable public adminBeacon;

  modifier onlyAdmin() {
    if (!_isAdmin(msg.sender)) revert OnlyAdmin();
    _;
  }

  modifier onlyAdminOrOwner() {
    if (!_isAdmin(msg.sender) && msg.sender != owner()) revert OnlyAdminOrOwner();
    _;
  }

  function _isAdmin(address _address) internal view returns (bool) {
    return adminBeacon.isAdmin(_address);
  }

  function _setAdminBeacon(IAdminBeaconUpgradeable _adminBeacon) internal {
    adminBeacon = _adminBeacon;
  }

  function setAdminBeacon(IAdminBeaconUpgradeable _adminBeacon) public virtual onlyOwner {
    _setAdminBeacon(_adminBeacon);
  }
}