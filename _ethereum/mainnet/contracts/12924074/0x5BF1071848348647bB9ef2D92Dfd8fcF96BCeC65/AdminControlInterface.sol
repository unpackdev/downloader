// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface AdminControlInterface {

  function hasRole(uint8 _role, address _account) external view returns (bool);

  function SUPER_ADMIN() external view returns (uint8);
  function ADMIN() external view returns (uint8);
  function SERVICE_ADMIN() external view returns (uint8);

}
