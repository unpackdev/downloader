// SPDX-License-Identifier: MIT

/**  WalletStore Contract */
/** Author: Aceson (2022.8) */
pragma solidity ^0.8.16;

import "./IERC20Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";

contract WalletStore is Initializable, OwnableUpgradeable, AccessControlUpgradeable {
  struct User {
    bool isVerified;
    uint256 arrayIndex;
  }

  // Create a new role identifier for the manager role
  bytes32 private constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
  address[] private verifiedList;

  mapping(address => User) public users;

  function batchAddUser(address[] memory _users) external onlyRole(MANAGER_ROLE) returns (bool) {
    uint256 len = _users.length;
    for (uint256 i = 0; i < len; i++) {
      addUser(_users[i]);
    }
    return true;
  }

  function replaceUser(address oldAddress, address newAddress)
    external
    onlyRole(MANAGER_ROLE)
    returns (bool)
  {
    require(!users[newAddress].isVerified, "new address is already verified");

    users[oldAddress].isVerified = false;
    users[newAddress].isVerified = true;

    uint256 idx = users[oldAddress].arrayIndex;
    verifiedList[idx] = newAddress;
    users[newAddress].arrayIndex = idx;

    return true;
  }

  function removeUser(address _address) external onlyRole(MANAGER_ROLE) returns (bool) {
    require(users[_address].isVerified, "user is not verified");

    uint256 idx = users[_address].arrayIndex;
    address lastAdd = verifiedList[verifiedList.length - 1];

    verifiedList[idx] = lastAdd;
    users[lastAdd].arrayIndex = idx;
    users[_address].arrayIndex = 0;
    users[_address].isVerified = false;

    verifiedList.pop();

    return true;
  }

  function setManager(address manager, bool status) external onlyRole(DEFAULT_ADMIN_ROLE) {
    if (status) {
      _grantRole(MANAGER_ROLE, manager);
    } else {
      _revokeRole(MANAGER_ROLE, manager);
    }
  }

  function getVerifiedUsers() external view returns (address[] memory) {
    return verifiedList;
  }

  function isVerified(address _user) external view returns (bool) {
    return users[_user].isVerified;
  }

  function initialize() public initializer {
    __Ownable_init();
    __AccessControl_init();
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(MANAGER_ROLE, msg.sender);
  }

  function addUser(address _address) public onlyRole(MANAGER_ROLE) returns (bool) {
    if (!users[_address].isVerified) {
      verifiedList.push(_address);
      users[_address].isVerified = true;
      users[_address].arrayIndex = verifiedList.length - 1;
    }

    return true;
  }
}
