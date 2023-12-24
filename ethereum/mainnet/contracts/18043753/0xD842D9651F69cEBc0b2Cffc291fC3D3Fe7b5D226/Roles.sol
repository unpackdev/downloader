// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import "./IRoles.sol";
import "./AccessControl.sol";

abstract contract Roles is IRoles, AccessControl {
  // @notice Checks if an account has a particular role
  // @param  _role The role that the account needs to have
  // @param  _account The account to check for the role
  function _checkRole(bytes32 _role, address _account) internal view override {
    if (!hasRole(_role, _account)) revert Roles_Unauthorized(_account, _role);
  }
}
