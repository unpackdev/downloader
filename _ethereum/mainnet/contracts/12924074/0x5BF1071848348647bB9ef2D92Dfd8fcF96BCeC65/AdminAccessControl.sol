// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./AdminControlInterface.sol";

abstract contract AdminAccessControl {

  AdminControlInterface public adminControl;

  modifier onlyRole(uint8 _role) {
    require(address(adminControl) == address(0) || adminControl.hasRole(_role, msg.sender), 'no access');
    _;
  }

  function addAdminControlContract(address _contract) public onlyRole(0) {
    adminControl = AdminControlInterface(_contract);
  }

}
