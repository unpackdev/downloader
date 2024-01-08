// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./ConfirmedOwner.sol";
import "./AccessControllerInterface.sol";

/**
 * @title WriteAccessController
 * @notice Has two access lists: a global list and a data-specific list.
 * @dev does not make any special permissions for EOAs, see
 * ReadAccessController for that.
 */
contract WriteAccessController is AccessControllerInterface, ConfirmedOwner(msg.sender) {
  bool private s_checkEnabled = true;
  mapping(address => bool) internal s_globalAccessList;
  mapping(address => mapping(bytes => bool)) internal s_localAccessList;

  event AccessAdded(address user, bytes data, address sender);
  event AccessRemoved(address user, bytes data, address sender);
  event CheckAccessEnabled();
  event CheckAccessDisabled();

  function checkEnabled()
    public
    view
    returns (
      bool
    )
  {
    return s_checkEnabled;
  }

  /**
   * @notice Returns the access of an address
   * @param user The address to query
   * @param data The calldata to query
   */
  function hasAccess(
    address user,
    bytes memory data
  )
    public
    view
    virtual
    override
    returns (bool)
  {
    return !s_checkEnabled || s_globalAccessList[user] || s_localAccessList[user][data];
  }

/**
   * @notice Adds an address to the global access list
   * @param user The address to add
   */
  function addGlobalAccess(
    address user
  )
    external
    onlyOwner()
  {
    _addGlobalAccess(user);
  }

  /**
   * @notice Adds an address+data to the local access list
   * @param user The address to add
   * @param data The calldata to add
   */
  function addLocalAccess(
    address user,
    bytes memory data
  )
    external
    onlyOwner()
  {
    _addLocalAccess(user, data);
  }

  /**
   * @notice Removes an address from the global access list
   * @param user The address to remove
   */
  function removeGlobalAccess(
    address user
  )
    external
    onlyOwner()
  {
    _removeGlobalAccess(user);
  }

  /**
   * @notice Removes an address+data from the local access list
   * @param user The address to remove
   * @param data The calldata to remove
   */
  function removeLocalAccess(
    address user,
    bytes memory data
  )
    external
    onlyOwner()
  {
    _removeLocalAccess(user, data);
  }

  /**
   * @notice makes the access check enforced
   */
  function enableAccessCheck()
    external
    onlyOwner()
  {
    _enableAccessCheck();
  }

  /**
   * @notice makes the access check unenforced
   */
  function disableAccessCheck()
    external
    onlyOwner()
  {
    _disableAccessCheck();
  }

  /**
   * @dev reverts if the caller does not have access
   */
  modifier checkAccess() {
    if (s_checkEnabled) {
      require(hasAccess(msg.sender, msg.data), "No access");
    }
    _;
  }

  function _enableAccessCheck() internal {
    if (!s_checkEnabled) {
      s_checkEnabled = true;
      emit CheckAccessEnabled();
    }
  }

  function _disableAccessCheck() internal {
    if (s_checkEnabled) {
      s_checkEnabled = false;
      emit CheckAccessDisabled();
    }
  }

  function _addGlobalAccess(address user) internal {
    if (!s_globalAccessList[user]) {
      s_globalAccessList[user] = true;
      emit AccessAdded(user, "", msg.sender);
    }
  }

  function _removeGlobalAccess(address user) internal {
    if (s_globalAccessList[user]) {
      s_globalAccessList[user] = false;
      emit AccessRemoved(user, "", msg.sender);
    }
  }

  function _addLocalAccess(address user, bytes memory data) internal {
    if (!s_localAccessList[user][data]) {
      s_localAccessList[user][data] = true;
      emit AccessAdded(user, data, msg.sender);
    }
  }

  function _removeLocalAccess(address user, bytes memory data) internal {
    if (s_localAccessList[user][data]) {
      s_localAccessList[user][data] = false;
      emit AccessRemoved(user, data, msg.sender);
    }
  }
}
