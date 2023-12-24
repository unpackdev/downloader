// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import "./IAccessControl.sol";

// @title Roles contract
//   @notice Manages the roles for interactions with a contract
interface IRoles is IAccessControl {
  /*///////////////////////////////////////////////////////////////
                              ERRORS
    //////////////////////////////////////////////////////////////*/

  // @notice Thrown when the caller of the function is not an authorized role
  error Roles_Unauthorized(address _account, bytes32 _role);
}
