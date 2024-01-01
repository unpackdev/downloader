// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./OwnableUpgradeable.sol";
import "./AccessControlEnumerableUpgradeable.sol";

contract AdminBeaconUpgradeable is OwnableUpgradeable, AccessControlEnumerableUpgradeable {
  bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

  function initialize() public initializer {
    __Ownable_init();
    __AccessControlEnumerable_init();

    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

    _setupRole(ADMIN_ROLE, _msgSender());
  }

  // change default admin role owner to new contract owner on transfer
  // ensures only the owner holds the default admin role
  function _transferOwnership(address newOwner) internal virtual override {
    address currentOwner = owner();

    _revokeRole(DEFAULT_ADMIN_ROLE, currentOwner);

    super._transferOwnership(newOwner);

    _setupRole(DEFAULT_ADMIN_ROLE, newOwner);
  }

  function grantAdmin(address account) external onlyOwner {
    grantRole(ADMIN_ROLE, account);
  }

  function revokeAdmin(address account) external onlyOwner {
    revokeRole(ADMIN_ROLE, account);
  }

  function renounceAdmin() external {
    renounceRole(ADMIN_ROLE, _msgSender());
  }

  function isAdmin(address account) public view returns (bool) {
    return hasRole(ADMIN_ROLE, account);
  }

  function countAdmins() external view returns (uint256) {
    return getRoleMemberCount(ADMIN_ROLE);
  }

  function getAdmin(uint256 index) external view returns (address) {
    return getRoleMember(ADMIN_ROLE, index);
  }
}
