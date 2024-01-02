// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./AccessControl.sol";

contract AccessController is AccessControl {
  bytes32 public constant OPERATOR = keccak256("OPERATOR");

  modifier onlyAdmin() {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Caller is not the admin");
    _;
  }

  modifier onlyOperator() {
    require(hasRole(OPERATOR, _msgSender()), "Caller is not the operator");
    _;
  }

  modifier onlyOperatorOrAdmin() {
    require(hasRole(OPERATOR, _msgSender()) || hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Caller must be operator or admin");
    _;
  }

  function addOperator(address operator) external onlyAdmin {
    _setupRole(OPERATOR, operator);
  }

  function removeOperator(address operator) external onlyAdmin {
    revokeRole(OPERATOR, operator);
  }
}
